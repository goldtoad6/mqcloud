package com.sohu.tv.mq.cloud.web.view.data;

import com.sohu.tv.mq.cloud.bo.*;
import com.sohu.tv.mq.cloud.common.util.WebUtil;
import com.sohu.tv.mq.cloud.service.*;
import com.sohu.tv.mq.cloud.util.DateUtil;
import com.sohu.tv.mq.cloud.util.Result;
import com.sohu.tv.mq.cloud.web.controller.param.PaginationParam;
import com.sohu.tv.mq.cloud.web.view.SearchHeader;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.DateSearchField;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.HiddenSearchField;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.SearchField;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.SelectSearchField;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.SelectSearchField.KV;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart.XAxis;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart.YAxis;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart.YAxisGroup;
import com.sohu.tv.mq.cloud.web.view.chart.LineChartData;
import com.sohu.tv.mq.cloud.web.vo.UserInfo;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.math.NumberUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.servlet.http.HttpServletRequest;
import java.util.*;
import java.util.stream.Collectors;

/**
 * topic消费者流量数据
 * 
 * @Description:
 * @author yongfeigao
 * @date 2018年6月29日
 */
@Component
public class ConsumeTrafficLineChartData implements LineChartData {

    // 搜索区域
    private SearchHeader searchHeader;

    public static final String DATE_FIELD = "date";
    public static final String TID_FIELD = "tid";
    public static final String DATE_FIELD_TITLE = "日期";
    public static final String CONSUMER_FIELD = "_consumer";
    public static final String CURRENTPAGE_FIELD = "currentPage";
    public static final String TYPE = "type";

    @Autowired
    private TopicTrafficService topicTrafficService;

    @Autowired
    private ConsumerTrafficService consumerTrafficService;
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private DelayMessageService delayMessageService;

    @Autowired
    private ConsumerClientMetricsService consumerClientMetricsService;
    
    // x轴数据
    private List<String> xDataList;

    // x轴格式化后的数据
    private List<String> xDataFormatList;
    
    private PaginationParam paginationParam = new PaginationParam();

    public ConsumeTrafficLineChartData() {
        initSearchHeader();
    }

    /**
     * 初始化搜索数据
     */
    public void initSearchHeader() {
        searchHeader = new SearchHeader();
        List<SearchField> searchFieldList = new ArrayList<SearchHeader.SearchField>();

        // type
        List<KV> kvList = new ArrayList<KV>();
        KV kv = new KV();
        kv.setK("0");
        kv.setV("服务端指标");
        kvList.add(kv);
        kv = new KV();
        kv.setK("1");
        kv.setV("客户端指标");
        kvList.add(kv);
        SelectSearchField typeSearchField = new SelectSearchField();
        typeSearchField.setKvList(kvList);
        typeSearchField.setKey(TYPE);
        typeSearchField.setValue("0");
        searchFieldList.add(typeSearchField);

        // time
        DateSearchField dateSearchField = new DateSearchField();
        dateSearchField.setKey(DATE_FIELD);
        dateSearchField.setTitle(DATE_FIELD_TITLE);
        searchFieldList.add(dateSearchField);

        // hidden
        HiddenSearchField hiddenSearchField = new HiddenSearchField();
        hiddenSearchField.setKey(TID_FIELD);
        searchFieldList.add(hiddenSearchField);
        
        // hidden
        HiddenSearchField hiddenConsumerField = new HiddenSearchField();
        hiddenConsumerField.setKey(CONSUMER_FIELD);
        searchFieldList.add(hiddenConsumerField);
        
        // begin
        HiddenSearchField currentPageField = new HiddenSearchField();
        currentPageField.setKey(CURRENTPAGE_FIELD);
        searchFieldList.add(currentPageField);

        searchHeader.setSearchFieldList(searchFieldList);
        
        // 初始化x轴数据，因为x轴数据是固定的
        xDataFormatList = new ArrayList<String>();
        xDataList = new ArrayList<String>();
        for (int i = 0; i < 24; ++i) {
            for (int j = 0; j < 60; ++j) {
                String hour = i < 10 ? "0" + i : "" + i;
                String ninutes = j < 10 ? "0" + j : "" + j;
                xDataList.add(hour + ninutes);
                xDataFormatList.add(hour + ":" + ninutes);
            }
        }
    }

    @Override
    public String getPath() {
        return "consume";
    }

    @Override
    public String getPageTitle() {
        return "topic消费流量";
    }

    @Override
    public List<LineChart> getLineChartData(Map<String, Object> searchMap) {
        List<LineChart> lineChartList = new ArrayList<LineChart>();
        
        // 解析参数
        Date date = getDate(searchMap, DATE_FIELD);
        Long tid = getLongValue(searchMap, TID_FIELD);
        if (tid == null) {
            return lineChartList;
        }
        
        // 获取request
        HttpServletRequest request = (HttpServletRequest) searchMap.get(REQUEST);
        // 获取用户信息
        UserInfo userInfo = (UserInfo) WebUtil.getAttribute(request, UserInfo.USER_INFO);
        // 查询topic的消费者
        Result<TopicTopology> topicTopologyResult = userService.queryTopicTopology(userInfo.getUser(), tid);
        if(topicTopologyResult.isNotOK()) {
            return lineChartList;
        }
        TopicTopology topicTopology = topicTopologyResult.getResult();
        
        if (tid == null || tid <= 0) {
            return lineChartList;
        } 
        //获取topic流量
        Result<List<TopicTraffic>> result = getTopicTraffic(topicTopology.getTopic(), date);
        if (!result.isOK()) {
            return lineChartList;
        }

        // 将list转为map方便数据查找
        Map<String, Traffic> trafficMap = list2Map(result.getResult());
        
        // 过滤消费者
        filterConsumer(searchMap, topicTopology);
        
        // 生成消费者数据
        LineChart lineChart2 = getConsumerLineChart(searchMap, date, topicTopology, trafficMap);
        if (lineChart2 != null) {
            lineChartList.add(lineChart2);
        }
        return lineChartList;
    }
    
    /**
     * 过滤消费者
     * @param searchMap
     * @param topicTopology
     */
    private void filterConsumer(Map<String, Object> searchMap, TopicTopology topicTopology) {
        List<Consumer> consumerList = topicTopology.getConsumerList();
        Object object = searchMap.get(CONSUMER_FIELD);
        if (object != null) {
            String tmp = object.toString();
            if (StringUtils.isBlank(tmp)) {
                return;
            }
            tmp = tmp.trim();
            Iterator<Consumer> iterator = consumerList.iterator();
            while (iterator.hasNext()) {
                Consumer consumer = iterator.next();
                if (!consumer.getName().equals(tmp)) {
                    iterator.remove();
                }
            }
        } else {
            Object currentPageObject = searchMap.get(CURRENTPAGE_FIELD);
            int currentPage = 1;
            if (currentPageObject != null) {
                currentPage = NumberUtils.toInt(currentPageObject.toString());
            }
            paginationParam.setCurrentPage(currentPage);
            paginationParam.caculatePagination(consumerList.size());
            List<Consumer> tmpList = new ArrayList<>();
            for (int i = paginationParam.getBegin(); i < paginationParam.getEnd(); ++i) {
                tmpList.add(consumerList.get(i));
            }
            topicTopology.setConsumerList(tmpList);
        }
    }

    private long setCountData(Traffic traffic, List<Number> countList) {
        if (traffic == null) {
            countList.add(0);
            return 0;
        } else {
            countList.add(traffic.getCount());
            return traffic.getCount();
        }
    }

    private Map<String, Traffic> list2Map(List<? extends Traffic> list) {
        Map<String, Traffic> map = new TreeMap<String, Traffic>();
        if (list == null) {
            return map;
        }
        for (Traffic traffic : list) {
            map.put(traffic.getCreateTime(), traffic);
        }
        return map;
    }

    private Map<Long, List<ConsumerTraffic>> list2ConsumerMap(List<ConsumerTraffic> list) {
        Map<Long, List<ConsumerTraffic>> map = new HashMap<Long, List<ConsumerTraffic>>();
        if (list == null) {
            return map;
        }
        for (ConsumerTraffic traffic : list) {
            List<ConsumerTraffic> mapList = map.get(traffic.getConsumerId());
            if (mapList == null) {
                mapList = new ArrayList<ConsumerTraffic>();
                map.put(traffic.getConsumerId(), mapList);
            }
            mapList.add(traffic);
        }
        return map;
    }
    
    /**
     * 生成消费者图表
     * 
     * @param searchMap
     * @param date
     * @param topic
     * @return
     */
    private LineChart getConsumerLineChart(Map<String, Object> searchMap, Date date, TopicTopology topicTopology, 
            Map<String, Traffic> producerTrafficMap) {
        // 构造曲线图对象
        LineChart lineChart = new LineChart();
        lineChart.setChartId("consumer");
        lineChart.setOneline(true);
        lineChart.setTickInterval(6);
        
        XAxis xAxis = new XAxis();
        xAxis.setxList(xDataFormatList);
        lineChart.setxAxis(xAxis);

        // 设置y轴列表
        List<YAxis> countYAxisList = new ArrayList<YAxis>();
        // 生成y轴数据组
        YAxisGroup countYAxisGroup = new YAxisGroup();
        countYAxisGroup.setGroupName("消息量");
        countYAxisGroup.setyAxisList(countYAxisList);
        // 设置y轴
        List<YAxisGroup> yAxisGroupList = new ArrayList<YAxisGroup>();
        yAxisGroupList.add(countYAxisGroup);
        lineChart.setyAxisGroupList(yAxisGroupList);

        int type = NumberUtils.toInt(searchMap.get(TYPE).toString());
        List<ConsumerTraffic> consumerTraffics = fetchConsumerTraffic(type, topicTopology.getConsumerList(), date);
        Map<Long, List<ConsumerTraffic>> map = list2ConsumerMap(consumerTraffics);
        for (Consumer consumer : topicTopology.getConsumerList()) {
            List<ConsumerTraffic> list = map.get(consumer.getId());
            // 将list转为map方便数据查找
            Map<String, Traffic> trafficMap = list2Map(list);
            // 填充y轴数据
            List<Number> countList = new ArrayList<Number>();
            for(String time : xDataList) {
                setCountData(trafficMap.get(time), countList);
            }
            YAxis countYAxis = new YAxis();
            countYAxis.setName(consumer.getName());
            countYAxis.setData(countList);
            countYAxisList.add(countYAxis);
        }
        
        // 设置生产者数据
        List<Number> producerCountList = new ArrayList<Number>();
        for(String time : xDataList) {
            setCountData(producerTrafficMap.get(time), producerCountList);
        }
        YAxis producerCountYAxis = new YAxis();
        producerCountYAxis.setName("生产者");
        producerCountYAxis.setData(producerCountList);
        countYAxisList.add(producerCountYAxis);
        return lineChart;
    }


    public List<ConsumerTraffic> fetchConsumerTraffic(int searchType, List<Consumer> consumerList, Date date) {
        Map<String, Long> consumerIdMap = new HashMap<>();
        for (Consumer consumer : consumerList) {
            consumerIdMap.put(consumer.getName(), consumer.getId());
        }
        // 服务端指标
        if (searchType == 0) {
            return consumerTrafficService.query(consumerIdMap.values(), date).getResult();
        }
        // 客户端指标
        List<ConsumerClientMetrics> consumerClientMetrics = consumerClientMetricsService.queryListByDate(consumerIdMap.keySet(), date).getResult();
        if (consumerClientMetrics == null) {
            return null;
        }
        return consumerClientMetrics.stream().map(consumerClientMetric -> {
            ConsumerTraffic consumerTraffic = new ConsumerTraffic();
            consumerTraffic.setConsumerId(consumerIdMap.get(consumerClientMetric.getConsumer()));
            consumerTraffic.setCreateTime(consumerClientMetric.getCreateTime());
            consumerTraffic.setCount(consumerClientMetric.getCount());
            return consumerTraffic;
        }).collect(Collectors.toList());
    }

    /**
     * 获取长整型数据
     * 
     * @param searchMap
     * @param key
     * @return
     */
    protected Long getLongValue(Map<String, Object> searchMap, String key) {
        if (searchMap == null) {
            return null;
        }
        Object obj = searchMap.get(key);
        if (obj == null) {
            return null;
        }
        return NumberUtils.toLong(obj.toString());
    }

    /**
     * 获取日期数据
     * 
     * @param searchMap
     * @param key
     * @return
     */
    protected Date getDate(Map<String, Object> searchMap, String key) {
        if (searchMap == null) {
            return new Date();
        }
        Object obj = searchMap.get(key);
        if (obj == null) {
            return new Date();
        }
        String date = obj.toString();
        if (!StringUtils.isEmpty(date)) {
            return DateUtil.parseYMD(date);
        }
        return new Date();
    }

    /**
     * 获取topic流量
     * 
     * @param topic
     * @param dateStr
     * @return
     */
    private Result<List<TopicTraffic>> getTopicTraffic(Topic topic, Date date) {
        Result<List<TopicTraffic>> result = null;
        if (topic.isDelayMsgType()) {
            result = delayMessageService.selectDelayMessageTraffic(topic.getId(), DateUtil.format(date));
        } else {
            result = topicTrafficService.query(topic.getId(), date);
        }
        return result;
    }
    
    @Override
    public SearchHeader getSearchHeader() {
        return searchHeader;
    }

}
