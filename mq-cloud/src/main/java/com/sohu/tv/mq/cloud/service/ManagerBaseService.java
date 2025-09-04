package com.sohu.tv.mq.cloud.service;

import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import com.sohu.tv.mq.cloud.bo.Topic;
import com.sohu.tv.mq.cloud.bo.User;
import com.sohu.tv.mq.cloud.dao.TopicDao;
import com.sohu.tv.mq.cloud.dao.TopicTrafficDao;
import com.sohu.tv.mq.cloud.dao.UserConsumerDao;
import com.sohu.tv.mq.cloud.dao.UserProducerDao;
import com.sohu.tv.mq.cloud.util.Result;
import com.sohu.tv.mq.cloud.web.controller.param.ManagerParam;
import com.sohu.tv.mq.cloud.web.controller.param.ManagerParam.QueryOrderType;
import com.sohu.tv.mq.cloud.web.controller.param.PaginationParam;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.CollectionUtils;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static com.sohu.tv.mq.cloud.web.controller.param.ManagerParam.QueryOrderType.SIZE1D_DESC;

/**
 * @author fengwang219475
 * @version 1.0
 * @description: 多条件查询基础服务类
 * @date 2022/3/3 17:11
 */
public class ManagerBaseService {

    @Resource
    protected TopicDao topicDao;

    @Resource
    protected UserConsumerDao userConsumerDao;

    @Resource
    protected UserProducerDao userProducerDao;

    @Resource
    protected TopicTrafficDao topicTrafficDao;

    @Autowired
    private TopicService topicService;

    /**
     * 通用过滤逻辑
     */
    protected List<Topic> queryAndFilterTopic(ManagerParam param, PaginationParam paginationParam,
                                              List<Long> resultTids, boolean returnAll) {

        List<Long> topicIds = queryTopicList(param);

        if (CollectionUtils.isEmpty(topicIds)) {
            return null;
        }
        return loopQueryAndFilter(param.getCid(), topicIds, paginationParam
                , resultTids, returnAll, param);
    }

    /**
     * 内存分页
     */
    private List<Topic> loopQueryAndFilter(Long cid, List<Long> tids, PaginationParam paginationParam,
                                           List<Long> resultTids, boolean returnAll, ManagerParam param) {
        List<Long> allTopicIdByCid = getAllTopicIdByCid(cid, tids);
        if (CollectionUtils.isEmpty(allTopicIdByCid)) {
            return null;
        }
        List<Topic> allTopic = new ArrayList<>();
        List<List<Long>> partition = Lists.partition(allTopicIdByCid, 100);
        for (List<Long> ids : partition) {
            List<Topic> topicList = topicDao.queryTopicDataByLimit(ids);
            allTopic.addAll(topicList);
        }
        QueryOrderType orderType = QueryOrderType.getQueryOrderTypeByDefault(param.getOrderType(), SIZE1D_DESC);
        switch (orderType){
            case TRAFFIC_DESC:
                allTopic.sort(Comparator.comparing(Topic::getCount).reversed());
                break;
            case TOPICNAME_ASC:
                allTopic.sort(Comparator.comparing(topic -> {
                    if (StringUtils.isEmpty(topic.getName())) {
                        return "";
                    }
                    return topic.getName().toLowerCase();
                }));
                break;
            case CREATE_ASC:
                allTopic.sort(Comparator.comparing(Topic::getCreateDate));
                break;
            case SIZE1D_DESC:
                allTopic.sort(Comparator.comparing(Topic::getSize1d).reversed());
                break;
            case SIZE2D_DESC:
                allTopic.sort(Comparator.comparing(Topic::getSize2d).reversed());
                break;
            case SIZE3D_DESC:
                allTopic.sort(Comparator.comparing(Topic::getSize3d).reversed());
                break;
            case SIZE5D_DESC:
                allTopic.sort(Comparator.comparing(Topic::getSize5d).reversed());
                break;
            case SIZE7D_DESC:
                allTopic.sort(Comparator.comparing(Topic::getSize7d).reversed());
                break;
            case SIZE_DESC:
                allTopic.sort(Comparator.comparing(Topic::getSize).reversed());
                break;
        }
        if (returnAll) {
            resultTids.addAll(allTopicIdByCid);
            return allTopic;
        } else {
            paginationParam.caculatePagination(allTopicIdByCid.size());
            List<List<Topic>> topicPageContent = Lists.partition(allTopic, paginationParam.getNumOfPage());
            List<Topic> currentTopics = topicPageContent.get(paginationParam.getCurrentPage() - 1);
            resultTids.addAll(currentTopics.stream().map(Topic::getId).collect(Collectors.toList()));
            return currentTopics;
        }
    }

    /**
     * 求tids的交集
     */
    private List<Long> getAllTopicIdByCid(Long cid, List<Long> tids) {
        List<Long> list = topicDao.selectAllTidsByCid(cid);
        list.retainAll(tids);
        return list.stream().sorted().collect(Collectors.toList());
    }

    /**
     * 主题查询
     */
    public List<Long> queryTopicList(ManagerParam param) {
        List<List<Long>> lists = new ArrayList<>(3);

        boolean isAddLimitQuery = false;

        if (param.getNoneConsumers() != null && param.getNoneConsumers()) {
            isAddLimitQuery = true;
            lists.add(findNoneConsumerTopic());
        }
        if (param.getNonePrducerFlows() != null && param.getNonePrducerFlows()) {
            isAddLimitQuery = true;
            lists.add(findNoneProMsgTopic());
        }
        if (param.getUid() != null) {
            isAddLimitQuery = true;
            lists.add(getTidListByUid(param.getUid()));
        }
        if (param.getGid() != null) {
            isAddLimitQuery = true;
            lists.add(getTidListByGid(param.getGid()));
        }
        if (param.getTopic() != null) {
            isAddLimitQuery = true;
            Result<List<Topic>> listResult = topicService.queryTopicList(param.getTopic(), 0, 0, 100, new LinkedList<>());
            if (listResult != null) {
                List<Topic> topicList = listResult.getResult();
                if (!CollectionUtils.isEmpty(topicList)) {
                    lists.add(topicList.stream().map(Topic::getId).collect(Collectors.toList()));
                }
            }
        }

        //求交集并去重
        return retainTidList(lists, isAddLimitQuery).stream().distinct().collect(Collectors.toList());
    }

    /**
     * 查找没有消费者的Topic
     */
    private List<Long> findNoneConsumerTopic() {
        // 查找没有消费者的Topic
        return topicDao.selectNoMatchTids();
    }

    /**
     * 查找当日无流量的Topic
     */
    private List<Long> findNoneProMsgTopic() {
        // 查找当前生产量为0的主题
        return topicTrafficDao.selectCurrentMsgNum(new Date());
    }

    /**
     * 查找活跃的的Topic
     */
    private List<Long> findActiveTopic() {
        // 查找没有消费者的Topic
        List<Long> activeConsumerTids = topicDao.selectActiveMatchTids();
        return activeConsumerTids;
    }

    /**
     * 依据人员ID获取tid集合
     */
    private List<Long> getTidListByUid(Long uid) {
        // 限制用户 需要关联user-consumer,user-producer
        List<Long> consumerTids = userConsumerDao.selectTidListByUid(uid);
        List<Long> producerTids = userProducerDao.selectTidListByUid(uid);
        return Stream.concat(consumerTids.stream(), producerTids.stream()).distinct().collect(Collectors.toList());
    }

    /**
     * 依据组织ID获取tid集合
     */
    private List<Long> getTidListByGid(long gid) {
        // 限制组织 需要管理user-group,user-consumer,user-producer
        List<Long> consumerTids = userConsumerDao.selectTidListByGid(gid);
        List<Long> producerTids = userProducerDao.selectTidListByGid(gid);
        return Stream.concat(consumerTids.stream(), producerTids.stream()).distinct().collect(Collectors.toList());
    }

    /**
     * 求取多个条件的交集Tid
     */
    private List<Long> retainTidList(List<List<Long>> lists, boolean queryLimit) {
        Set<Long> referSet = new HashSet<>();
        if (!CollectionUtils.isEmpty(lists)) {
            referSet.addAll(lists.get(0));
            Iterator<Long> iterator = referSet.iterator();
            while (iterator.hasNext()) {
                Long i = iterator.next();
                for (int index = 1; index < lists.size(); index++) {
                    List<Long> set = lists.get(index);
                    if (!set.contains(i)) {
                        iterator.remove();
                        break;
                    }
                }
            }
        }
        if (!queryLimit && CollectionUtils.isEmpty(referSet)) {
            return topicDao.selectAll().stream().map(Topic::getId).collect(Collectors.toList());
        }
        return Lists.newArrayList(referSet);
    }

    /**
     * 返回null 说明该条件可忽略
     * 返回List 需要纳入限制条件
     */
    protected Set<Long> intersectionToSet(List<Long> ... lists){
        Set<Long> result = null;
        List<List<Long>> noNullList = Stream.of(lists).filter(Objects::nonNull).collect(Collectors.toList());
        if (CollectionUtils.isEmpty(noNullList))return result;
        List<Long> remove = noNullList.remove(0);
        if (CollectionUtils.isEmpty(noNullList)) return Sets.newHashSet(remove);
        for (List<Long> list : noNullList) {
            remove.retainAll(list);
        }
        return Sets.newHashSet(remove);
    }

    // 前端参数处理 公用提取到service中
    public void handleUserName(Result<List<User>> userResult) {
        if (userResult.isNotEmpty()) {
            userResult.getResult().forEach(node -> {
                String value = node.getEmail().substring(0, node.getEmail().indexOf("@"));
                if (org.apache.commons.lang3.StringUtils.isNoneBlank(node.getName()) && node.getName() != value) {
                    value = node.getName() + "【" + value + "】";
                }
                node.setName(value);
            });
        }
    }

    public String handleQueryParams(HttpServletRequest request) {
        //剔除分页参数
        String queryStr = null;
        if (!StringUtils.isBlank(request.getQueryString())) {
            String queryString = request.getQueryString();
            int index = queryString.indexOf("&currentPage");
            if (index == -1) {
                queryStr = request.getQueryString();
            } else {
                queryStr = request.getQueryString().substring(0, index);
            }
        }
        return queryStr;
    }
}
