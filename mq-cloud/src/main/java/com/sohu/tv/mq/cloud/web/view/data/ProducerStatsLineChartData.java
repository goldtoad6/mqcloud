package com.sohu.tv.mq.cloud.web.view.data;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import com.sohu.tv.mq.cloud.web.service.LineChartService;
import org.apache.commons.collections.MapUtils;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.sohu.tv.mq.cloud.bo.ProducerStat;
import com.sohu.tv.mq.cloud.bo.ProducerTotalStat;
import com.sohu.tv.mq.cloud.service.ProducerStatService;
import com.sohu.tv.mq.cloud.service.ProducerTotalStatService;
import com.sohu.tv.mq.cloud.util.DateUtil;
import com.sohu.tv.mq.cloud.util.Result;
import com.sohu.tv.mq.cloud.web.view.SearchHeader;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.DateSearchField;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.HiddenSearchField;
import com.sohu.tv.mq.cloud.web.view.SearchHeader.SearchField;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart.XAxis;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart.YAxis;
import com.sohu.tv.mq.cloud.web.view.chart.LineChart.YAxisGroup;
import com.sohu.tv.mq.cloud.web.view.chart.LineChartData;

/**
 * 生产者客户端状态数据
 * 
 * @author yongfeigao
 * @date 2018年9月13日
 */
@Component
public class ProducerStatsLineChartData implements LineChartData {
    private Logger logger = LoggerFactory.getLogger(getClass());

    // 搜索区域
    private SearchHeader searchHeader;

    public static final String DATE_FIELD = "date";
    public static final String PRODUCER_FIELD = "producerGroupStats";
    public static final String DATE_FIELD_TITLE = "日期";

    // x轴数据
    private List<String> xDataList;

    // x轴格式化后的数据
    private List<String> xDataFormatList;

    @Autowired
    private ProducerTotalStatService producerTotalStatService;
    
    @Autowired
    private ProducerStatService producerStatService;

    public ProducerStatsLineChartData() {
        initSearchHeader();
    }

    /**
     * 初始化搜索数据
     */
    public void initSearchHeader() {
        searchHeader = new SearchHeader();
        List<SearchField> searchFieldList = new ArrayList<SearchHeader.SearchField>();

        // time
        DateSearchField dateSearchField = new DateSearchField();
        dateSearchField.setKey(DATE_FIELD);
        dateSearchField.setTitle(DATE_FIELD_TITLE);
        dateSearchField.setDaysBefore(10);
        searchFieldList.add(dateSearchField);

        // hidden
        HiddenSearchField hiddenSearchField = new HiddenSearchField();
        hiddenSearchField.setKey(PRODUCER_FIELD);
        searchFieldList.add(hiddenSearchField);

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
        return "pstats";
    }

    @Override
    public String getPageTitle() {
        return "生产者状况统计";
    }

    @SuppressWarnings("unchecked")
    @Override
    public List<LineChart> getLineChartData(Map<String, Object> searchMap) {
        List<LineChart> lineChartList = new ArrayList<LineChart>();
        
        // 解析参数
        String producer = MapUtils.getString(searchMap, PRODUCER_FIELD);
        if (producer == null) {
            return lineChartList;
        }
        Date date = getDate(searchMap, DATE_FIELD);

        //获取producer总体统计
        Result<List<ProducerTotalStat>> result = producerTotalStatService.query(producer, date);
        if (result.isEmpty()) {
            return lineChartList;
        }
        // 转为map
        Map<String, Map<String, ProducerTotalStat>> totalMap = list2Map(producer, date, result.getResult());
        
        // 获取producer 详细统计
        Result<List<ProducerStat>> producerTotalStatListResult = producerStatService.query(producer, date);
        // 转为map
        Map<Long, List<ProducerStat>> statMap = list2MapList(producerTotalStatListResult.getResult());
        for (ProducerTotalStat producerTotalStat : result.getResult()) {
           producerTotalStat.setStatList(statMap.get(producerTotalStat.getId()));
        }
        int index = 1;
        for(String client : totalMap.keySet()) {
            long clinetTotalCount = 0;
            // 构造曲线图对象
            LineChart lineChart = new LineChart();
            lineChart.setChartId("total" + index++);
            lineChart.setTitle(client+"每分钟耗时");
            lineChart.setOneline(true);
            lineChart.setTickInterval(6);
            
            XAxis xAxis = new XAxis();
            xAxis.setxList(xDataFormatList);
            lineChart.setxAxis(xAxis);
    
            // 设置耗时y轴列表
            List<YAxis> yAxisList = new ArrayList<YAxis>();
            // 生成耗时y轴数据组
            YAxisGroup costYAxisGroup = new YAxisGroup();
            costYAxisGroup.setGroupName("耗时(ms)");
            costYAxisGroup.setyAxisList(yAxisList);
            
            // 设置调用量y轴列表
            List<YAxis> countYAxisList = new ArrayList<YAxis>();
            // 生成调用量y轴数据组对象
            YAxisGroup countYAxisGroup = new YAxisGroup();
            countYAxisGroup.setGroupName("次数");
            countYAxisGroup.setOpposite(true);
            countYAxisGroup.setyAxisList(countYAxisList);
            
            // 设置调用量y轴
            YAxis countYaxis = new YAxis();
            countYaxis.setName("调用量");
            countYaxis.setColor("#0099FF");
            List<Map<String, Object>> countDataList = new ArrayList<Map<String, Object>>();
            countYaxis.setData(countDataList);
            countYAxisList.add(countYaxis);
            
            // 设置y轴
            List<YAxisGroup> yAxisGroupList = new ArrayList<YAxisGroup>();
            yAxisGroupList.add(costYAxisGroup);
            yAxisGroupList.add(countYAxisGroup);
            lineChart.setyAxisGroupList(yAxisGroupList);
        
            YAxis percent90Yaxis = new YAxis();
            percent90Yaxis.setName("90%");
            percent90Yaxis.setColor("#ffc107");
            List<Number> percent90DataList = new ArrayList<Number>();
            percent90Yaxis.setData(percent90DataList);
            yAxisList.add(percent90Yaxis);
            
            YAxis percent99Yaxis = new YAxis();
            percent99Yaxis.setName("99%");
            percent99Yaxis.setColor("#28a745");
            List<Number> percent99DataList = new ArrayList<Number>();
            percent99Yaxis.setData(percent99DataList);
            yAxisList.add(percent99Yaxis);
            
            YAxis avgYaxis = new YAxis();
            avgYaxis.setName("avg");
            avgYaxis.setColor("green");
            List<Number> avgDataList = new ArrayList<Number>();
            avgYaxis.setData(avgDataList);
            yAxisList.add(avgYaxis);
            
            long maxCount = 0;
            int maxCost = 0;
            Map<String, ProducerTotalStat> timeMap = totalMap.get(client);
            for(int i = 0; i < xDataList.size(); ++i) {
                String time = xDataList.get(i);
                ProducerTotalStat pts = timeMap.get(time);
                Map<String, Object> countMap = new HashMap<String, Object>();
                if(pts == null) {
                    percent90DataList.add(0);
                    percent99DataList.add(0);
                    avgDataList.add(0);
                    countMap.put("y", 0);
                    countDataList.add(countMap);
                } else {
                    percent90DataList.add(pts.getPercent90());
                    percent99DataList.add(pts.getPercent99());
                    avgDataList.add(pts.getAvg());
                    
                    countMap.put("y", pts.getCount());
                    countMap.put("id", pts.getId());
                    countDataList.add(countMap);
                    
                    if(maxCount < pts.getCount()) {
                        maxCount = pts.getCount();
                    }
                    clinetTotalCount += pts.getCount();
                    
                    // 获取详细信息
                    if(pts.getStatList() != null) {
                        // 添加是否异常
                        boolean warn = false;
                        for(ProducerStat stat : pts.getStatList()) {
                            if(maxCost < stat.getMax()) {
                                maxCost = stat.getMax();
                            }
                            if(!warn && stat.getException() != null) {
                                warn = true;
                            }
                        }
                        if(warn || pts.getException() != null) {
                            Map<String, Object> markerMap = new HashMap<String, Object>();
                            markerMap.put("symbol", "circle");
                            markerMap.put("fillColor", "red");
                            markerMap.put("enabled", true);
                            countMap.put("marker", markerMap);
                            if (pts.getException() != null) {
                                countMap.put("dt", pts.getException());
                            }
                        }
                        // 设置详细信息
                        Map<Long, List<ProducerStat>> map = (Map<Long, List<ProducerStat>>) lineChart.getDataMap();
                        if(map == null) {
                            map = new TreeMap<>();
                            lineChart.setDataMap(map);
                        }
                        map.put(pts.getId(), pts.getStatList());
                    }
                }
            }
            lineChart.setSubTitle("总调用量: "+ formatCount(clinetTotalCount) +" 最大调用量: "+maxCount+"次/分钟 单次最大耗时: "+maxCost+"ms");
            lineChartList.add(lineChart);
        }
        
        return lineChartList;
    }
    
    /**
     * 格式化消息数量
     * @param maxCount
     * @return
     */
    private String formatCount(long maxCount) {
        String maxCountShow = "";
        if(maxCount > 100000000) {
            maxCountShow = String.format("%.2f", maxCount / 100000000F) + "亿("+maxCount+")";
        } else if(maxCount > 10000) {
            maxCountShow = String.format("%.2f", maxCount / 10000F) + "万("+maxCount+")";
        } else {
            maxCountShow = String.valueOf(maxCount);
        }
        return maxCountShow;
    }

    private Map<String/*client*/, Map<String/*time*/, ProducerTotalStat>> list2Map(String producer, Date date,
                                                                                   List<ProducerTotalStat> list) {
        Map<String, Map<String, ProducerTotalStat>> map = new HashMap<String, Map<String, ProducerTotalStat>>();
        if (list == null) {
            return map;
        }
        int searchedDate = DateUtil.format(date);
        for (ProducerTotalStat producerTotalStat : list) {
            Map<String, ProducerTotalStat> timeMap = map.get(producerTotalStat.getClient());
            if (timeMap == null) {
                timeMap = new HashMap<>();
                map.put(producerTotalStat.getClient(), timeMap);
            }
            int statTime = producerTotalStat.getStatTime();
            long t = statTime * 60000L;
            Date statDate = new Date(t);
            // 只统计搜索日期的数据
            if (searchedDate != DateUtil.format(statDate)) {
                continue;
            }
            String key = DateUtil.getFormat(DateUtil.HHMM).format(statDate);
            timeMap.put(key, producerTotalStat);
        }
        // 查询当天的数据，不必补充23:59的数据
        if (searchedDate == DateUtil.format(new Date())) {
            return map;
        }
        boolean lastDataExist = true;
        for (Map<String, ProducerTotalStat> timeMap : map.values()) {
            if (!timeMap.containsKey("2359")) {
                lastDataExist = false;
                break;
            }
        }
        if (lastDataExist) {
            return map;
        }
        // 补充23:59的数据
        int lastStatTime = 0;
        try {
            Date dt = DateUtil.getFormat(DateUtil.YMDHM).parse(searchedDate+"2359");
            lastStatTime = (int) (dt.getTime() / 60000);
        } catch (ParseException e) {
            logger.warn("parse date error", e);
            return map;
        }
        Result<List<ProducerTotalStat>> listResult = producerTotalStatService.queryByStatTime(producer, lastStatTime);
        if (listResult.isEmpty()) {
            return map;
        }
        listResult.getResult().stream().forEach(totalStat -> {
            Map<String, ProducerTotalStat> timeMap = map.get(totalStat.getClient());
            if(timeMap != null && !timeMap.containsKey("2359")) {
                timeMap.put("2359", totalStat);
            }
        });
        return map;
    }
    
    private Map<Long, List<ProducerStat>> list2MapList(List<ProducerStat> list) {
        Map<Long, List<ProducerStat>> map = new HashMap<Long, List<ProducerStat>>();
        
        if (list == null) {
            return map;
        }
        for (ProducerStat producerStat : list) {
            List<ProducerStat> plist = map.get(producerStat.getTotalId());
            if(plist == null) {
                plist = new ArrayList<ProducerStat>();
                map.put(producerStat.getTotalId(), plist);
            }
            producerStat.setTotalId(0);
            plist.add(producerStat);
        }
        return map;
    }

    @Override
    public SearchHeader getSearchHeader() {
        return searchHeader;
    }

}
