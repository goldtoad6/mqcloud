package com.sohu.tv.mq.cloud.task;

import com.sohu.tv.mq.cloud.bo.Cluster;
import com.sohu.tv.mq.cloud.service.ClusterService;
import com.sohu.tv.mq.cloud.task.monitor.MonitorService;
import com.sohu.tv.mq.cloud.task.monitor.MonitorServiceFactory;
import com.sohu.tv.mq.cloud.util.MQCloudConfigHelper;
import net.javacrumbs.shedlock.core.LockConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;

import java.time.Instant;

/**
 * 定时监控预警
 *
 * @author yongfeigao
 * @Description:
 * @date 2018年7月30日
 */
public class MonitorServiceTask {
    private final Logger logger = LoggerFactory.getLogger(this.getClass());

    @Autowired
    private TaskExecutor taskExecutor;

    @Autowired
    private ClusterService clusterService;

    @Autowired
    private MonitorServiceFactory monitorServiceFactory;

    @Autowired
    private MQCloudConfigHelper mqCloudConfigHelper;

    /**
     * 每5分钟监控一次
     */
    @Scheduled(cron = "43 */5 * * * *")
    public void monitor() {
        if (clusterService.getAllMQCluster() == null) {
            logger.warn("mqcluster is null");
            return;
        }
        for (Cluster mqCluster : clusterService.getAllMQCluster()) {
            // 测试环境，监控所有的集群；online环境，只监控online集群
            if (!mqCloudConfigHelper.needMonitor(mqCluster.online())) {
                continue;
            }
            MonitorService monitorService = monitorServiceFactory.getMonitorService(mqCluster);
            if (monitorService == null) {
                logger.warn("monitorService is null, mqCluster:{}", mqCluster);
                continue;
            }
            LockConfiguration lockConfiguration = new LockConfiguration("monitor-" + mqCluster.getId(),
                    Instant.now().plusSeconds(240), Instant.now().plusSeconds(180));
            taskExecutor.execute(() -> {
                try {
                    long start = System.currentTimeMillis();
                    monitorService.doMonitorWork();
                    logger.info("monitor:{}, use:{}ms", mqCluster, System.currentTimeMillis() - start);
                } catch (Exception e) {
                    logger.error("monitor:{} err", mqCluster, e);
                }
            }, lockConfiguration);
        }
    }
}
