package com.sohu.tv.mq.cloud.web.controller.admin;

import com.sohu.tv.mq.cloud.bo.CheckStatusEnum;
import com.sohu.tv.mq.cloud.bo.Cluster;
import com.sohu.tv.mq.cloud.bo.NameServer;
import com.sohu.tv.mq.cloud.service.ClusterService;
import com.sohu.tv.mq.cloud.service.MQDeployer;
import com.sohu.tv.mq.cloud.service.NameServerService;
import com.sohu.tv.mq.cloud.util.MQCloudConfigHelper;
import com.sohu.tv.mq.cloud.util.Result;
import com.sohu.tv.mq.cloud.util.Status;
import com.sohu.tv.mq.cloud.web.vo.UserInfo;
import org.apache.commons.lang3.math.NumberUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * name server
 * 
 * @author yongfeigao
 * @date 2018年10月23日
 */
@Controller
@RequestMapping("/admin/nameserver")
public class AdminNameServerController extends AdminViewController {

    @Autowired
    private ClusterService clusterService;

    @Autowired
    private NameServerService nameServerService;

    @Autowired
    private MQCloudConfigHelper mqCloudConfigHelper;

    @Autowired
    private MQDeployer mqDeployer;

    @RequestMapping("/list")
    public String list(@RequestParam(name = "cid", required = false) Integer cid, Map<String, Object> map) {
        setView(map, "list");
        Cluster mqCluster = clusterService.getOrDefaultMQCluster(cid);
        if (mqCluster == null) {
            return view();
        }
        Result<List<NameServer>> result = nameServerService.query(mqCluster.getId());
        if (result.isNotEmpty()) {
            // 检查状态
            result.getResult().forEach(nameServer -> {
                Result<?> healthCheckResult = nameServerService.healthCheck(mqCluster, nameServer.getAddr());
                if (healthCheckResult.isOK()) {
                    nameServer.setCheckStatus(CheckStatusEnum.OK.getStatus());
                    // 获取链接数量
                    Result<String> countResult = mqDeployer.getConnectionCount(nameServer.getIp(), nameServer.getPort());
                    if (countResult.isOK()) {
                        nameServer.setConnectionCount(NumberUtils.toInt(countResult.getResult()));
                    }
                } else {
                    nameServer.setCheckStatus(CheckStatusEnum.FAIL.getStatus());
                }
            });
        }
        setResult(map, result);
        setResult(map, "clusters", clusterService.getAllMQCluster());
        setResult(map, "selectedCluster", mqCluster);
        setResult(map, "username", mqCloudConfigHelper.getServerUser());
        return view();
    }

    /**
     * 关联
     * 
     * @param cid
     * @param broker
     * @return
     */
    @ResponseBody
    @RequestMapping(value = "/add", method = RequestMethod.POST)
    public Result<?> add(UserInfo ui, @RequestParam(name = "addr") String addr,
            @RequestParam(name = "cid") int cid) {
        String[] addrs = addr.split(":");
        if(addrs.length != 2) {
            return Result.getResult(Status.PARAM_ERROR);
        }
        String ip = addrs[0];
        String portStr = addrs[1];
        int port = NumberUtils.toInt(portStr);
        if (port == 0) {
            return Result.getResult(Status.PARAM_ERROR);
        }
        Result<?> portResult = mqDeployer.getListenPortInfo(ip, port);
        if(portResult.getStatus() != Status.DB_ERROR.getKey()) {
            return Result.getResult(Status.NO_RESULT);
        }
        Result<?> result = nameServerService.save(cid, addr);
        return Result.getWebResult(result);
    }
    
    /**
     * 下线
     * 
     * @return
     */
    @ResponseBody
    @RequestMapping(value = "/offline", method = RequestMethod.POST)
    public Result<?> offline(UserInfo ui, @RequestParam(name = "addr") String addr,
            @RequestParam(name = "cid") int cid) {
        logger.warn("offline:{}, user:{}", addr, ui);
        String[] addrs = addr.split(":");
        String ip = addrs[0];
        String portStr = addrs[1];
        int port = NumberUtils.toInt(portStr);
        if (port == 0) {
            return Result.getResult(Status.PARAM_ERROR);
        }
        return mqDeployer.shutdown(ip, port);
    }
    
    /**
     * 删除
     * 
     * @param cid
     * @param broker
     * @return
     */
    @ResponseBody
    @RequestMapping(value = "/delete", method = RequestMethod.POST)
    public Result<?> delete(UserInfo ui, @RequestParam(name = "addr") String addr,
            @RequestParam(name = "cid") int cid) {
        logger.warn("offline:{}, user:{}", addr, ui);
        Result<?> result = nameServerService.delete(cid, addr);
        return Result.getWebResult(result);
    }

    /**
     * 启动
     * 
     * @return
     */
    @ResponseBody
    @RequestMapping(value = "/startup", method = RequestMethod.POST)
    public Result<?> startup(UserInfo ui, @RequestParam(name = "ip") String ip, @RequestParam(name = "listenPort") int port,
            @RequestParam(name = "dir") String dir, @RequestParam(name = "cid") int cid) {
        logger.warn("startup, ip:{}, dir:{}, user:{}", ip, dir, ui);
        Result<?> result = mqDeployer.startup(ip, dir, port);
        if (result.isOK()) {
            nameServerService.save(cid, ip + ":" + port, dir);
        }
        return result;
    }

    /**
     * 连接
     */
    @GetMapping(value = "/connection")
    public String connection(int cid, String ip, int port, Map<String, Object> map) {
        setResult(map, nameServerService.getConnectionAddress(cid, ip, port));
        return adminViewModule() + "/connection";
    }

    /**
     * 剔除流量
     */
    @ResponseBody
    @RequestMapping(value = "/unregister", method = RequestMethod.POST)
    public Result<?> unregister(UserInfo ui, @RequestParam(name = "addr") String addr, @RequestParam(name = "cid") int cid) {
        logger.warn("unregister:{}, user:{}", addr, ui);
        return Result.getWebResult(nameServerService.updateStatus(cid, addr, 1));
    }

    /**
     * 恢复流量
     */
    @ResponseBody
    @RequestMapping(value = "/register", method = RequestMethod.POST)
    public Result<?> register(UserInfo ui, @RequestParam(name = "addr") String addr, @RequestParam(name = "cid") int cid) {
        logger.warn("register:{}, user:{}", addr, ui);
        return Result.getWebResult(nameServerService.updateStatus(cid, addr, 0));
    }

    @Override
    public String viewModule() {
        return "nameserver";
    }
}
