package com.sohu.tv.mq.cloud.service;

import com.sohu.tv.mq.cloud.bo.BrokerConfig;
import com.sohu.tv.mq.cloud.bo.Cluster;
import com.sohu.tv.mq.cloud.bo.StoreFiles;
import com.sohu.tv.mq.cloud.bo.StoreFiles.StoreFile;
import com.sohu.tv.mq.cloud.bo.StoreFiles.StoreFileType;
import com.sohu.tv.mq.cloud.bo.SubscriptionGroup;
import com.sohu.tv.mq.cloud.mq.MQAdminCallback;
import com.sohu.tv.mq.cloud.mq.MQAdminTemplate;
import com.sohu.tv.mq.cloud.service.SSHTemplate.DefaultLineProcessor;
import com.sohu.tv.mq.cloud.service.SSHTemplate.SSHCallback;
import com.sohu.tv.mq.cloud.service.SSHTemplate.SSHResult;
import com.sohu.tv.mq.cloud.service.SSHTemplate.SSHSession;
import com.sohu.tv.mq.cloud.util.*;
import com.sohu.tv.mq.cloud.web.vo.ScpDirVO;
import com.sohu.tv.mq.cloud.web.vo.ScpVO;
import com.sohu.tv.mq.util.JSONUtil;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.math.NumberUtils;
import org.apache.rocketmq.common.MixAll;
import org.apache.rocketmq.remoting.protocol.body.ClusterInfo;
import org.apache.rocketmq.remoting.protocol.body.SubscriptionGroupWrapper;
import org.apache.rocketmq.remoting.protocol.body.TopicConfigSerializeWrapper;
import org.apache.rocketmq.remoting.protocol.route.BrokerData;
import org.apache.rocketmq.tools.admin.MQAdminExt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * MQ部署
 * @Description: 
 * @author yongfeigao
 * @date 2018年8月15日
 */
@Component
public class MQDeployer {
    
    @Autowired
    private MQCloudConfigHelper mqCloudConfigHelper;
    
    public static final String MQ_CLOUD_CONFIG_INIT_FLAG = "/home/mqcloud/.mq_cloud_inited";
    
    public static final String MQ_CLOUD_OS_SH = "%s/bin/os.sh";
    
    public static final String TMP_DIR = "/tmp/";
    
    public static final String PID = "tmpVar=`sudo netstat -npl | grep \":%s\" | awk '{print $NF}' | awk -F\"/java\" '{print $1}'` && [ ! -z \"$tmpVar\" ] && ";
    
    public static final String RUN_FILE = "run.sh";
    
    public static final String CONFIG_FILE = "mq.conf";

    public static final String ENV_CONFIG = "echo \"source /etc/profile\" > %s/" + RUN_FILE;

    public static final String JVM_OPT_EXT_CONFIG = "echo \"export JAVA_OPT_EXT='%s'\" >> %s/" + RUN_FILE;

    public static final String RUN_CONFIG = "echo \"nohup bash %s/bin/%s >> %s/logs/startup.log 2>&1 &\" >> %s/" + RUN_FILE;

    public static final String DATA_LOGS_DIR = "mkdir -p %s/data/config && mkdir -p %s/logs && ";

    public static final String MQ_AUTH = "/tmp/mqauth";

    public static final String PROXY_JSON = "rmq-proxy.json";

    public static final String BROKER_RATE_LIMIT_JSON = "rateLimitConfig.json";

    public static final String BACKUP_SUFFIX = ".backup";
    // 获取某个端口的链接地址
    public static final String CONNECTION_ADDR = "sudo netstat -nt | grep ESTABLISHED | awk '$4 ~ /:%s$/ {print $5}'";
    // 获取某个端口的链接数量
    public static final String CONNECTION_COUNT = "sudo netstat -nt | grep ESTABLISHED | awk '$4 ~ /:%s$/ {count++} END {print count}'";

    // 部署broker时自动创建监控订阅组
    public static final String SUBSCRIPTIONGROUP_JSON = "echo '"
            + JSONUtil.toJSONString(SubscriptionGroup.buildMonitorSubscriptionGroup())
            + "' > %s/config/subscriptionGroup.json";
   
    protected Logger logger = LoggerFactory.getLogger(this.getClass());
    
    @Autowired
    private SSHTemplate sshTemplate;
    
    @Autowired
    private MQAdminTemplate mqAdminTemplate;
    
    @Autowired
    private ClusterService clusterService;
    
    @Autowired
    private RocketMQFileService rocketMQFileService;
    
    @Autowired
    private BrokerConfigService brokerConfigService;

    @Autowired
    private BrokerService brokerService;
    
    /**
     * 获取jdk版本
     * @param ip
     * @return
     */
    public Result<?> getJDKVersion(String ip){
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand("source /etc/profile;javap -version");
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("getJDKVersion:{}", ip, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * 获取进程信息
     * @param ip
     * @return
     */
    public Result<?> getProgram(String ip, int port){
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(String.format(PID, port) + "sudo ps -fp $tmpVar");
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("getProgram, ip:{},port{}", ip, port, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }

    /**
     * pid是否死亡
     */
    public Result<?> isPidDead(String ip, int pid) {
        try {
            SSHResult sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("sudo kill -0 " + pid + " 2>/dev/null && echo 1 || echo 0");
                }
            });
            if (sshResult != null) {
                int rst = NumberUtils.toInt(sshResult.getResult(), -1);
                if (rst == 0) {
                    return Result.getOKResult();
                }
                if (rst == -1) {
                    return Result.getErrorResult(sshResult.getResult() + " is not number");
                }
                return Result.getErrorResult("pid(" + sshResult.getResult() + ") is alive");
            }
            return Result.getErrorResult("ssh result is empty");
        } catch (SSHException e) {
            logger.error("getPid, ip:{}, pid:{}", ip, pid, e);
            return Result.getErrorResult("ssh result error:" + e.toString());
        }
    }

    /**
     * 获取监听某个端口的信息
     * @param ip
     * @return
     */
    public Result<?> getListenPortInfo(String ip, int port){
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand("sudo netstat -npl | grep -w " + port);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("getListenPortInfo, ip:{},port:{}", ip, port, e);
            return Result.getWebErrorResult(e);
        }
        Result<?> result = wrapSSHResult(sshResult);
        
        // 端口被占用
        if(result.isOK() && result.getResult() != null) {
            result.setStatus(Status.DB_ERROR.getKey());
        }
        return result;
    }
    
    /**
     * 判断目录是否被占用
     * @param ip
     * @return
     */
    public Result<?> dirWrite(String ip, String dir){
        String comm = "if [ ! -d \"" + dir + "\" ];then sudo mkdir -p " + dir + " && sudo chown mqcloud:mqcloud " + dir
                + ";else echo 0;fi";
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("isNotUsed, ip:{},dir:{}", ip, dir, e);
            return Result.getWebErrorResult(e);
        }
        Result<?> result = wrapSSHResult(sshResult);
        
        if(result.isOK() && "0".equals(result.getResult())) {
            return Result.getResult(Status.DB_ERROR).setMessage("目录已存在");
        }
        return result;
    }
    
    /**
     * 上传rocketmq.zip文件
     * @param ip
     * @return
     */
    public Result<?> scp(String ip, RocketMQVersion rocketMQVersion){
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    byte[] rocketmqFile = null;
                    if (RocketMQVersion.V4 == rocketMQVersion) {
                        rocketmqFile = rocketMQFileService.getRocketmqFile();
                    } else {
                        rocketmqFile = rocketMQFileService.getRocketmq5File();
                    }
                    SSHResult sshResult = session.scpToFile(rocketmqFile, TMP_DIR + MQCloudConfigHelper.ROCKETMQ_FILE);
                    rocketmqFile = null;
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("scp:{}, ", ip, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * unzip
     * @param ip
     * @return
     */
    public Result<?> unzip(String ip, String dest){
        return unzip(ip, dest, TMP_DIR + MQCloudConfigHelper.ROCKETMQ_FILE);
    }
    
    /**
     * unzip
     * @param ip
     * @return
     */
    public Result<?> unzip(String ip, String dest, String zipFile){
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand("unzip -d " + dest + " " + zipFile);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("unzip, ip:{},dest:{},zip:{}", ip, dest, zipFile, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * configNameServer
     * @param ip
     * @return
     */
    public Result<?> configNameServer(Map<String, Object> param){
        String port = param.get("listenPort").toString();
        String ip = param.get("ip").toString();
        String absoluteDir = param.get("dir").toString();
        String absoluteConfig = absoluteDir + "/" + CONFIG_FILE;
        String mqConf = "echo \"kvConfigPath="+absoluteDir+"/data/kvConfig.json\" >> " + absoluteConfig + " && "
                + "echo \"listenPort="+port+"\" >> " + absoluteConfig + " && ";
        if (mqCloudConfigHelper.isAdminAclEnable()) {
            mqConf += "echo \"adminAclEnable=true\" >> " + absoluteConfig + " && ";
        }
        String runFileCommand = buildNameServerRunFileCommand(param);
        String comm = String.format(DATA_LOGS_DIR, absoluteDir, absoluteDir)
                + mqConf
                + runFileCommand;
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("configNameServer, ip:{},comm:{}", ip, comm, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }

    /**
     * configBroker
     * @param ip
     * @return
     */
    public Result<?> configBroker(Map<String, Object> param){
        String clusterName = param.get("brokerClusterName").toString();
        Cluster cluster = clusterService.getMQClusterByName(clusterName);
        String absoluteDir = param.get("dir").toString();
        String absoluteConfig = absoluteDir + "/" + CONFIG_FILE;
        String brokerIp = param.get("ip").toString();
        String runFileCommand = buildBrokerRunFileCommand(param);
        String storePathRootDir = param.get("storePathRootDir").toString();
        // 1.基础配置
        String comm = String.format(DATA_LOGS_DIR, absoluteDir, absoluteDir)
                + "mkdir -p " + storePathRootDir + "/consumequeue " + param.get("storePathCommitLog")
                + " && echo -e \""
                + map2String(param, cluster.getId())
                + "\" > " + absoluteConfig + " && "
                + runFileCommand;
        // 2.启用proxy
        String proxyConfigCommand = null;
        if (isEnableProxy(param)) {
            proxyConfigCommand = " && echo '{\"rocketMQClusterName\":\"" + clusterName + "\""
                    + ",\"namesrvDomain\":\"" + param.get("rmqAddressServerDomain") + "\""
                    + ",\"namesrvDomainSubgroup\":\"" + param.get("rmqAddressServerSubGroup") + "\"";
            if (param.get("grpcServerPort") != null) {
                proxyConfigCommand += ",\"grpcServerPort\":" + param.remove("grpcServerPort");
            }
            if (param.get("remotingListenPort") != null) {
                proxyConfigCommand += ",\"remotingListenPort\":" + param.remove("remotingListenPort");
            }
            proxyConfigCommand += "}' > " + absoluteDir + "/" + PROXY_JSON;
        }
        if (proxyConfigCommand != null) {
            comm += proxyConfigCommand;
        }
        final String finalComm = comm;
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(brokerIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(finalComm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("configBroker, ip:{},comm:{}", brokerIp, comm, e);
            return Result.getWebErrorResult(e);
        }
        Result<?> configResult = wrapSSHResult(sshResult);
        if(configResult.isNotOK()) {
            return configResult;
        }
        // 3.初始化监控订阅信息
        final String subscriptionGroupComm = String.format(SUBSCRIPTIONGROUP_JSON, storePathRootDir);
        try {
            sshResult = sshTemplate.execute(brokerIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(subscriptionGroupComm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("init subscriptionGroup, ip:{},comm:{}", brokerIp, subscriptionGroupComm, e);
            return Result.getWebErrorResult(e);
        }
        configResult = wrapSSHResult(sshResult);
        if(configResult.isNotOK()) {
            return configResult;
        }
        
        // slave直接返回
        if("SLAVE".equals(param.get("brokerRole"))) {
            return Result.getOKResult();
        }
        // 获取master地址
        Result<String> masterAddressResult = fetchMasterAddress(cluster);
        // 集群中无节点时，不进行后续配置
        if(Status.NO_RESULT.getKey() == masterAddressResult.getStatus()) {
            return Result.getOKResult();
        }
        if(!masterAddressResult.isOK()) {
            return masterAddressResult;
        }
        String masterAddress = masterAddressResult.getResult();
        // 4.1抓取topic配置
        Result<String> result = fetchTopicConfig(cluster, masterAddress);
        if(Status.DB_ERROR.getKey() == result.getStatus()) {
            return result;
        }
        
        // 4.2保存topic配置
        Result<?> topicSSHResult = saveConfig(brokerIp, result.getResult(), storePathRootDir, "topics.json");
        if(!topicSSHResult.isOK()) {
            return topicSSHResult;
        }
        
        // 5.1抓取consumer配置
        Result<String> consumerResult = fetchConsumerConfig(cluster, masterAddress);
        if(Status.DB_ERROR.getKey() == consumerResult.getStatus()) {
            return consumerResult;
        }
        
        // 5.2保存consumer配置
        Result<?> rst = saveConfig(brokerIp, consumerResult.getResult(), storePathRootDir, "subscriptionGroup.json");

        // 6.1限速配置
        String brokerRateLimitJson = getBrokerRateLimitJson(cluster, masterAddress);
        if (StringUtils.isBlank(brokerRateLimitJson)) {
            return rst;
        }

        // 6.2保存限速配置
        return saveConfig(brokerIp, brokerRateLimitJson, storePathRootDir, BROKER_RATE_LIMIT_JSON);
    }

    /**
     * 获取broker限速配置
     */
    private String getBrokerRateLimitJson(Cluster cluster, String brokerAddr) {
        // 获取broker数据存储根路径
        Properties properties = brokerService.fetchBrokerConfig(cluster, brokerAddr).getResult();
        if (properties == null) {
            return null;
        }
        String storePathRootDir = properties.getProperty("storePathRootDir");
        if (storePathRootDir == null) {
            return null;
        }
        String command = "cat " + storePathRootDir + "/config/" + BROKER_RATE_LIMIT_JSON;
        try {
            SSHResult sshResult = sshTemplate.execute(brokerAddr.split(":")[0], new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand(command);
                }
            });
            if (sshResult.isSuccess()) {
                return sshResult.getResult();
            }
        } catch (SSHException e) {
            logger.error(command, e);
            return null;
        }
        return null;
    }

    /**
     * configController
     * @param ip
     * @return
     */
    public Result<?> configController(Map<String, Object> param) {
        param.remove("v");
        param.remove("cid");
        param.remove("listenPort");
        String ip = param.remove("ip").toString();
        String absoluteDir = param.get("dir").toString();
        String absoluteConfig = absoluteDir + "/" + CONFIG_FILE;
        String mqConf = map2String(param);
        String mqConfCommand = "echo -e \"" + mqConf + "\" > " + absoluteConfig;
        String runFileCommand = buildControllerRunFileCommand(param);
        String comm = String.format(DATA_LOGS_DIR, absoluteDir, absoluteDir)
                + mqConfCommand + " && "
                + runFileCommand;
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("configController, ip:{},comm:{}", ip, comm, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }

    /**
     * configProxy
     * @return
     */
    public Result<?> configProxy(Map<String, Object> param) {
        param.remove("v");
        param.remove("cid");
        param.remove("listenPort");
        String ip = param.remove("ip").toString();
        String absoluteDir = param.get("dir").toString();
        String runFileCommand = buildProxyRunFileCommand(param);
        String proxyConfigCommand = "echo '" + param.get("config") + "' > " + absoluteDir + "/" + PROXY_JSON;
        String comm = String.format("mkdir -p %s/logs", absoluteDir) + " && "
                + proxyConfigCommand + " && "
                + runFileCommand;
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("configController, ip:{},comm:{}", ip, comm, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }

    /**
     * 构建runFile命令
     *
     * @param param
     * @param absoluteDir
     * @return
     */
    private String buildNameServerRunFileCommand(Map<String, Object> param) {
        return buildRunFileCommand("mqnamesrv", param);
    }

    /**
     * 构建runFile命令
     *
     * @param param
     * @param absoluteDir
     * @return
     */
    private String buildControllerRunFileCommand(Map<String, Object> param) {
        return buildRunFileCommand("mqcontroller", param);
    }

    /**
     * 构建runFile命令
     *
     * @param param
     * @param absoluteDir
     * @return
     */
    private String buildProxyRunFileCommand(Map<String, Object> param) {
        return buildRunFileCommand("mqproxy", param);
    }

    /**
     * 构建runFile命令
     *
     * @param param
     * @param absoluteDir
     * @return
     */
    private String buildBrokerRunFileCommand(Map<String, Object> param) {
        return buildRunFileCommand("mqbroker", param);
    }

    /**
     * 构建runFile命令
     *
     * @param runFile
     * @param param
     * @return
     */
    private String buildRunFileCommand(String runFile, Map<String, Object> param) {
        String JvmOptExtConfig = buildJvmOptExtConfig(param);
        String absoluteDir = param.get("dir").toString();
        String command = String.format(ENV_CONFIG, absoluteDir);
        if (JvmOptExtConfig.length() > 0) {
            command += " && " + String.format(JVM_OPT_EXT_CONFIG, JvmOptExtConfig, absoluteDir);
        }
        // broker内嵌proxy参数
        if ("mqbroker".equals(runFile) && isEnableProxy(param)) {
            runFile += " --enable-proxy -pc " + absoluteDir + "/" + PROXY_JSON;
        }
        // 指定配置文件
        if ("mqproxy".equals(runFile)) {
            runFile += " -pc " + absoluteDir + "/" + PROXY_JSON;
        } else {
            runFile += " -c " + absoluteDir + "/" + CONFIG_FILE;
        }
        command += " && " + String.format(RUN_CONFIG, absoluteDir, runFile, absoluteDir, absoluteDir);
        return command;
    }

    private boolean isEnableProxy(Map<String, Object> param) {
        String enableProxy = (String) param.get("enableProxy");
        if ("5".equals(param.get("v")) && enableProxy != null) {
            return true;
        }
        return false;
    }

    /**
     * 支持jvm自定义参数
     * @param param
     * @return
     */
    private String buildJvmOptExtConfig(Map<String, Object> param) {
        StringBuilder jvmOptBuilder = new StringBuilder();
        String jvmOptExt = (String) param.remove("jvmOptExt");
        if (StringUtils.isNotBlank(jvmOptExt)) {
            jvmOptBuilder.append(jvmOptExt);
        }
        return jvmOptBuilder.toString();
    }

    private String map2String(Map<String, Object> param, int cid) {
        StringBuilder sb = new StringBuilder();
        Result<List<BrokerConfig>> result = brokerConfigService.queryByCid(cid);
        for (String key : param.keySet()) {
            for (BrokerConfig brokerConfig : result.getResult()) {
                if (brokerConfig.getKey().equals(key)) {
                    sb.append(key + "=" + param.get(key) + "\n");
                }
            }
        }
        return sb.toString();
    }

    private String map2String(Map<String, Object> param) {
        StringBuilder sb = new StringBuilder();
        for (String key : param.keySet()) {
            String value = param.get(key).toString();
            if (StringUtils.isBlank(value)) {
                continue;
            }
            sb.append(key + "=" + param.get(key) + "\n");
        }
        return sb.toString();
    }
    
    private Result<?> saveConfig(String ip, String content, String storePathRootDir, String fileName) {
        SSHResult sshResult = null;
        try {
            // save config to /tmp
            MixAll.string2File(content, "/tmp/" + fileName);
            
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.scpToDir("/tmp/" + fileName, storePathRootDir + "/config/");
                    return sshResult;
                }
            });
        } catch (Exception e) {
            logger.error("configBroker {}, ip:{}, content:{}", fileName, ip, content, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * 初始化配置
     * @param ip
     * @return
     */
    public Result<?> initConfig(String ip, String nsHome) {
        String comm = "if [ ! -f \"" + MQ_CLOUD_CONFIG_INIT_FLAG + "\" ];then sudo bash "
                + String.format(MQ_CLOUD_OS_SH, nsHome) + " && touch " + MQ_CLOUD_CONFIG_INIT_FLAG + ";fi";
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("initConfig, ip:{},comm:{}", ip, comm, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * 获取master地址
     * @param brokerRole
     * @return
     */
    private Result<String> fetchMasterAddress(Cluster cluster){
        // 获取topic配置
        return mqAdminTemplate.execute(new MQAdminCallback<Result<String>>() {
            public Result<String> callback(MQAdminExt mqAdmin) throws Exception {
                // 获取集群配置
                ClusterInfo clusterInfo = mqAdmin.examineBrokerClusterInfo();
                if(clusterInfo == null) {
                    return Result.getResult(Status.NO_RESULT);
                }
                Map<String, BrokerData> brokerAddrTable = clusterInfo.getBrokerAddrTable();
                if(brokerAddrTable == null || brokerAddrTable.size() == 0) {
                    return Result.getResult(Status.NO_RESULT);
                }
                BrokerData brokerData = brokerAddrTable.values().iterator().next();
                HashMap<Long, String> brokerAddrs = brokerData.getBrokerAddrs();
                if(brokerAddrs == null || brokerAddrs.size() == 0) {
                    return Result.getResult(Status.NO_RESULT);
                }
                String masterAddr = brokerAddrs.get(MixAll.MASTER_ID);
                return Result.getResult(masterAddr);
            }

            public Result<String> exception(Exception e) throws Exception {
                logger.error("fetchMasterAddress:{} error", cluster, e);
                return Result.getDBErrorResult(e);
            }
            public Cluster mqCluster() {
                return cluster;
            }
        });
    }
    
    /**
     * 获取topic的配置
     * @param brokerRole
     * @return
     */
    private Result<String> fetchTopicConfig(Cluster cluster, String masterAddress){
        // 获取topic配置
        return mqAdminTemplate.execute(new MQAdminCallback<Result<String>>() {
            public Result<String> callback(MQAdminExt mqAdmin) throws Exception {
                // 获取topic配置
                TopicConfigSerializeWrapper topicWrapper = mqAdmin.getAllTopicConfig(masterAddress, 10 * 1000);
                if(topicWrapper == null) {
                    return Result.getResult(Status.NO_RESULT);
                }
                return Result.getResult(JSONUtil.toJSONString(topicWrapper));
            }

            public Result<String> exception(Exception e) throws Exception {
                logger.error("fetchTopicConfig:{} error", masterAddress, e);
                return Result.getDBErrorResult(e);
            }

            public Cluster mqCluster() {
                return cluster;
            }
        });
    }
    
    /**
     * 获取consumer的配置
     * @param brokerRole
     * @return
     */
    private Result<String> fetchConsumerConfig(Cluster cluster, String masterAddress){
        // 获取topic配置
        return mqAdminTemplate.execute(new MQAdminCallback<Result<String>>() {
            public Result<String> callback(MQAdminExt mqAdmin) throws Exception {
                // 获取topic配置
                SubscriptionGroupWrapper subscriptionWrapper = mqAdmin.getAllSubscriptionGroup(masterAddress, 10 * 1000);
                if(subscriptionWrapper == null) {
                    return Result.getResult(Status.NO_RESULT);
                }
                return Result.getResult(JSONUtil.toJSONString(subscriptionWrapper));
            }

            public Result<String> exception(Exception e) throws Exception {
                logger.error("fetchConsumerConfig:{} error", masterAddress, e);
                return Result.getDBErrorResult(e);
            }

            public Cluster mqCluster() {
                return cluster;
            }
        });
    }

    /**
     * 备份数据
     *
     * @param ip
     * @param sourceDir
     */
    public Result<?> backup(String ip, String sourceDir) {
        return backup(ip, sourceDir, sourceDir + BACKUP_SUFFIX);
    }

    /**
     * 备份数据
     * @param ip
     * @param sourceDir
     * @param destDir
     * @return
     */
    public Result<?> backup(String ip, String sourceDir, String destDir) {
        // 首先判断目标目录是否存在
        Result<?> dirExistResult = _dirExist(ip, destDir);
        if (!dirExistResult.isOK()) {
            return dirExistResult;
        }
        if ((Boolean) dirExistResult.getResult()) {
            return Result.getResult(Status.DB_ERROR).setMessage(destDir + "已存在");
        }
        String comm = "sudo mv " + sourceDir + " " + destDir;
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("backup err, ip:{},sourceDir:{},destDir:{},comm:{}", ip, sourceDir, destDir, comm, e);
            return Result.getWebErrorResult(e);
        }
        Result<?> result = wrapSSHResult(sshResult);
        // 创建新目录
        if (result.isOK()) {
            dirWrite(ip, sourceDir);
        }
        return result;
    }

    /**
     * 移动备份数据到新安装目录
     *
     * @param ip
     * @param dir
     */
    public Result<?> recover(String ip, String dir) {
        return recover(ip, dir + BACKUP_SUFFIX, dir);
    }

    /**
     * 移动备份数据到新安装目录
     * @param ip
     * @param backupDir
     * @param destDir
     * @return
     */
    public Result<?> recover(String ip, String backupDir, String destDir) {
        String mvCommTemplate = "sudo mv %s/%s %s/";
        // 1. 移动mq.conf
        String mvConfig = String.format(mvCommTemplate, backupDir, CONFIG_FILE, destDir);
        // 2. 移动run.sh
        String mvRun = String.format(mvCommTemplate, backupDir, RUN_FILE, destDir);
        // 3. 移动rmq-proxy.json
        String mvProxyJson = String.format("[ -f %s ] &&", backupDir + "/" + PROXY_JSON)
                + String.format(mvCommTemplate, backupDir, PROXY_JSON, destDir);
        // 4. 移动data目录
        String mvData = String.format(mvCommTemplate, backupDir, "data", destDir);
        // 5. 创建logs目录
        String createLogsDir = String.format("mkdir -p %s/logs", destDir);
        // 顺序执行,各个命令之间没有依赖
        String comm = new StringBuilder()
                .append(mvConfig).append(" ; ")
                .append(mvRun).append(" ; ")
                .append(mvProxyJson).append(" ; ")
                .append(mvData).append(" ; ")
                .append(createLogsDir).toString();
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("recover err, ip:{},backupDir:{},destDir:{},comm:{}", ip, backupDir, destDir, comm, e);
            return Result.getWebErrorResult(e);
        }
        // 检测执行结果
        Result<?> mvResult = wrapSSHResult(sshResult);
        if (mvResult.isNotOK()) {
            return mvResult;
        }
        // 6. 备份目录重命名
        String renameBackupDirComm = "sudo mv " + backupDir + " " + backupDir + DateUtil.getFormatNow(DateUtil.YMDHMS);
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(renameBackupDirComm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("renameBackupDir err, ip:{},comm:{}", ip, renameBackupDirComm, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * startup
     * @param ip
     * @return
     */
    public Result<?> startup(String ip, String absoluteDir, int port){
        return startup(ip, absoluteDir, port, true);
    }
    
    /**
     * startup
     * @param ip
     * @return
     */
    public Result<?> startup(String ip, String absoluteDir, int port, boolean checkStartupStatus){
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand("sudo bash " + absoluteDir + "/" + RUN_FILE);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("startup, ip:{},home:{}", ip, absoluteDir, e);
            return Result.getWebErrorResult(e);
        }
        Result<?> result = wrapSSHResult(sshResult);
        if (result.isOK() && checkStartupStatus) {
            // 检测是否已经启动
            for (int i = 0; i < 100; ++i) {
                Result<?> programResult = getProgram(ip, port);
                if (programResult != null && programResult.isOK() && programResult.getResult() != null) {
                    break;
                }
                try {
                    logger.info("starting up, ip:{},port:{}, times:{}", ip, port, i);
                    Thread.sleep(3000);
                } catch (InterruptedException e) {
                    break;
                }
            }
        }
        return result;
    }

    /**
     * shutdown
     * @param ip
     * @return
     */
    public Result<?> shutdown(String ip, int port){
        return shutdown(ip, port, null);
    }
    
    /**
     * shutdown
     */
    public Result<?> shutdown(String ip, int port, String baseDir){
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(String.format(PID, port)  + "sudo kill $tmpVar && echo $tmpVar");
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("shutdown, ip:{},port:{}", ip, port, e);
            return Result.getWebErrorResult(e);
        }
        Result<?> result = wrapSSHResult(sshResult);
        if (baseDir != null && result.isOK()) {
            int pid = NumberUtils.toInt(String.valueOf(result.getResult()), 0);
            if (pid == 0) {
                logger.error("cant shutdown, ip:{}, port:{}, baseDir:{} result:{}", ip, port, baseDir, result.getResult());
                return Result.getResult(Status.DB_ERROR).setMessage("cant shutdown");
            }
            // 检测broker是否已经关闭
            int shutdownTimes = 0;
            for (int i = 0; i < 20; ++i) {
                Result<?> pidResult = isPidDead(ip, pid);
                if (pidResult.isOK()) {
                    // 连续两次检测到关闭才算成功
                    if (++shutdownTimes >= 2) {
                        logger.info("shutdown ok, ip:{}, port:{}, baseDir:{}, times:{}, result:{}", ip, port, baseDir, i, pid);
                        break;
                    } else {
                        logger.info("shutdown detected, ip:{}, port:{}, baseDir:{}, times:{}, result:{}", ip, port, baseDir, i, pid);
                    }
                } else {
                    shutdownTimes = 0;
                }
                try {
                    logger.info("shutting down, ip:{}, port:{}, baseDir:{}, times:{}, result:{}", ip, port, baseDir, i, pidResult.getMessage());
                    Thread.sleep(3000);
                } catch (InterruptedException e) {
                    break;
                }
            }
        }
        return result;
    }
    
    /**
     * 机器互信
     * @param sourceIp
     * @param destIp
     * @return
     */
    public Result<?> authentication(String sourceIp, String destIp) {
        // 1.生产无密互信公私钥
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(sourceIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("[ ! -e '" + MQ_AUTH + "' ] && ssh-keygen -t rsa -f " + MQ_AUTH + " -N '' -q");
                }
            });
        } catch (SSHException e) {
            logger.error("ssh-keygen, sourceIp:{}", sourceIp, e);
            return Result.getWebErrorResult(e);
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        // 2.读取公钥
        sshResult = null;
        try {
            sshResult = sshTemplate.execute(sourceIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("cat " + MQ_AUTH + ".pub");
                }
            });
        } catch (SSHException e) {
            logger.error("cat " + MQ_AUTH + ".pub, sourceIp:{}", sourceIp, e);
            return Result.getWebErrorResult(e);
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        String pubKey = sshResult.getResult();
        // 3.写入目标机器
        sshResult = null;
        try {
            sshResult = sshTemplate.execute(destIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("[ ! -e '/home/mqcloud/.ssh' ] && mkdir -p -m 700 /home/mqcloud/.ssh;"
                            + "[ ! -e '/home/mqcloud/.ssh/authorized_keys' ] && touch /home/mqcloud/.ssh/authorized_keys && chmod 600 /home/mqcloud/.ssh/authorized_keys;"
                            + "echo '" + pubKey + "' >> /home/mqcloud/.ssh/authorized_keys;");
                }
            });
        } catch (SSHException e) {
            logger.error("authorized_keys, sourceIp:{}, destIp:{}", sourceIp, destIp, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * 获取存储文件
     * @param ip
     * @param home
     * @return
     */
    public Result<?> getStoreFileList(String ip, String home) {
        String absoluteDir = home + "/data";
        SSHResult sshResult = null;
        StoreFiles storeFiles = new StoreFiles();
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("cd " + absoluteDir + ";find -type f | xargs du -b",
                            new DefaultLineProcessor() {
                                public void process(String line, int lineNum) throws Exception {
                                    String[] tmpArray = line.split("\\s+");
                                    if (tmpArray[1].startsWith(".")) {
                                        tmpArray[1] = tmpArray[1].substring(1);
                                    }
                                    storeFiles.addStoreFile(tmpArray[1], NumberUtils.toLong(tmpArray[0]));
                                }
                            }, 60 * 1000);
                }
            });
        } catch (SSHException e) {
            logger.error("startup, ip:{},home:{}", ip, absoluteDir, e);
            return Result.getWebErrorResult(e);
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        if (storeFiles.getStoreEntryMap().size() == 0) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(ip + " " + absoluteDir + " 无数据");
        }
        storeFiles.sort();
        return Result.getResult(storeFiles);
    }
    
    /**
     * 创建存储路径
     * @param ip
     * @param home
     * @return
     */
    public Result<?> createStorePath(String ip, String home) {
        String absoluteDir = home + "/data";
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    StringBuilder comm = new StringBuilder("mkdir -p ");
                    for(StoreFileType storeFileType : StoreFileType.values()) {
                        comm.append(absoluteDir);
                        comm.append(storeFileType.getPath());
                        comm.append(" ");
                    }
                    return session.executeCommand(comm.toString());
                }
            });
        } catch (SSHException e) {
            logger.error("startup, ip:{},home:{}", ip, absoluteDir, e);
            return Result.getWebErrorResult(e);
        }
        return wrapSSHResult(sshResult);
    }
    
    /**
     * scp存储条目
     * 
     * @param ip
     * @param home
     * @return
     */
    public Result<?> scpStoreEntry(String sourceIp, String sourceHome, String destIp, String destHome,
            StoreFile storeFile) {
        if (storeFile.getSubEntryListSize() > 1) {
            return scpStoreFolder(sourceIp, sourceHome, destIp, destHome, storeFile);
        } else {
            return scpStoreFile(sourceIp, sourceHome, destIp, destHome, storeFile);
        }
    }
    
    /**
     * scp存储文件
     * @param ip
     * @param home
     * @return
     */
    public Result<?> scpStoreFile(String sourceIp, String sourceHome, String destIp, String destHome,
            StoreFile storeFile) {
        long start = System.currentTimeMillis();
        // 复制文件
        String absoluteStorePath = storeFile.toAbsoluteStorePath();
        String sourceFile = sourceHome + "/data" + absoluteStorePath;
        String destFile = destHome + "/data" + absoluteStorePath;
        SSHResult sshResult = null;
        // 先创建需要的存储目录
        if (storeFile.getParentName() != null) {
            try {
                sshResult = sshTemplate.execute(destIp, new SSHCallback() {
                    public SSHResult call(SSHSession session) {
                        return session.executeCommand("mkdir -p " + destFile.substring(0, destFile.lastIndexOf("/")));
                    }
                });
            } catch (SSHException e) {
                logger.error("mkdir destIp:{}, destHome:{}", destIp, destHome, e);
                return Result.getWebErrorResult(e);
            }
            if (!sshResult.isSuccess()) {
                return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
            }
        }
        // 复制文件
        try {
            sshResult = sshTemplate.execute(sourceIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand(
                            "scp -o BatchMode=yes -o StrictHostKeyChecking=no -i " + MQ_AUTH + " -pq -l 819200 " + sourceFile 
                            + " mqcloud@" + destIp + ":" + destFile,
                            30 * 60 * 1000);
                }
            });
        } catch (SSHException e) {
            logger.error("scp, ip:{}, sourceHome:{}, destIp:{}, destHome:{}", sourceIp, sourceHome, destIp, destHome, e);
            return Result.getWebErrorResult(e);
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        // 源md5
        try {
            sshResult = sshTemplate.execute(sourceIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("md5sum " + sourceFile, 60 * 1000);
                }
            });
        } catch (SSHException e) {
            logger.error("mkdir destIp:{}, destHome:{}", destIp, destHome, e);
            return Result.getWebErrorResult(e);
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        String sourceMD5 = sshResult.getResult().split("\\s+")[0];
        // 目标md5
        try {
            sshResult = sshTemplate.execute(destIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("md5sum " + destFile, 60 * 1000);
                }
            });
        } catch (SSHException e) {
            logger.error("mkdir destIp:{}, destHome:{}", destIp, destHome, e);
            return Result.getWebErrorResult(e);
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        String destMD5 = sshResult.getResult().split("\\s+")[0];
        // md5不一致需要校验大小是否一致
        if (!sourceMD5.equals(destMD5)) {
            // 目标大小
            try {
                sshResult = sshTemplate.execute(destIp, new SSHCallback() {
                    public SSHResult call(SSHSession session) {
                        return session.executeCommand("du -b " + destFile);
                    }
                });
            } catch (SSHException e) {
                logger.error("mkdir destIp:{}, destHome:{}", destIp, destHome, e);
                return Result.getWebErrorResult(e);
            }
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        String[] tmpArray = sshResult.getResult().split("\\s+");
        long destSize = NumberUtils.toLong(tmpArray[0]);
        // 结果封装
        ScpVO scpVO = new ScpVO(sourceMD5, destMD5, System.currentTimeMillis() - start, storeFile.getSize(), destSize);
        return Result.getResult(scpVO);
    }
    
    /**
     * scp存储路径
     * @param ip
     * @param home
     * @return
     */
    public Result<?> scpStoreFolder(String sourceIp, String sourceHome, String destIp, String destHome,
            StoreFile storeFile) {
        long start = System.currentTimeMillis();
        StoreFileType storeFileType = StoreFileType.findStoreFileType(storeFile.getType());
        String sourceDataDir = sourceHome + "/data" + storeFileType.getPath();
        String destDataDir = destHome + "/data" + storeFileType.getPath();
        SSHResult sshResult = null;
        // 复制目录
        try {
            sshResult = sshTemplate.execute(sourceIp, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("cd " + sourceDataDir + ";tar cz " + storeFile.getName() + " && ssh -i "
                          + MQ_AUTH + " -q mqcloud@" + destIp + " \"tar xzm -C " + destDataDir + "\"", 30 * 60 * 1000);
                }
            });
        } catch (SSHException e) {
            logger.error("scp, ip:{}, sourceHome:{}, destIp:{}, destHome:{}", sourceIp, sourceHome, destIp, destHome, e);
            return Result.getWebErrorResult(e);
        }
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        // 源md5
        Map<String, ScpVO> scpVOMap = new HashMap<>();
        sshResult = getMD5(scpVOMap, sourceIp, sourceDataDir + "/" + storeFile.getName(), true);
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        // 目标md5
        sshResult = getMD5(scpVOMap, destIp, destDataDir + "/" + storeFile.getName(), false);
        if (!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        // md5不一致需要校验大小是否一致
        boolean md5Equal = true;
        for (ScpVO scpVO : scpVOMap.values()) {
            if (!scpVO.isMD5OK()) {
                md5Equal = false;
                break;
            }
        }
        boolean sizeEqual = true;
        if (!md5Equal) {
            // 源大小
            sshResult = getSize(scpVOMap, sourceIp, sourceDataDir + "/" + storeFile.getName(), true);
            if (!sshResult.isSuccess()) {
                return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
            }
            // 目标大小
            sshResult = getSize(scpVOMap, destIp, destDataDir + "/" + storeFile.getName(), false);
            if (!sshResult.isSuccess()) {
                return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
            }
            for (ScpVO scpVO : scpVOMap.values()) {
                if (!scpVO.isSizeOK()) {
                    sizeEqual = false;
                    break;
                }
            }
        }
        // 结果封装
        ScpDirVO scpDirVO = new ScpDirVO(md5Equal, sizeEqual, System.currentTimeMillis() - start, storeFile.getSize(), scpVOMap);
        return Result.getResult(scpDirVO);
    }
    
    /**
     * 获取md5
     * @param scpVOMap
     * @param ip
     * @param path
     * @param source
     * @return
     */
    private SSHResult getMD5(Map<String, ScpVO> scpVOMap, String ip, String path, boolean source) {
        try {
            return sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("cd " + path + ";find -type f | xargs md5sum",
                            new DefaultLineProcessor() {
                                public void process(String line, int lineNum) throws Exception {
                                    String[] tmpArray = line.split("\\s+");
                                    if (tmpArray[1].startsWith(".")) {
                                        tmpArray[1] = tmpArray[1].substring(1);
                                    }
                                    if(source) {
                                        ScpVO scpVO = new ScpVO(tmpArray[0], null, 0, 0, 0);
                                        scpVOMap.put(tmpArray[1], scpVO);
                                    } else {
                                        ScpVO scpVO = scpVOMap.get(tmpArray[1]);
                                        if (scpVO != null) {
                                            scpVO.setDestMD5(tmpArray[0]);
                                        }
                                    }
                                }
                            });
                }
            });
        } catch (SSHException e) {
            logger.error("md5 ip:{}, path:{}", ip, path, e);
            return sshTemplate.new SSHResult(e);
        }
    }
    
    /**
     * 获取md5
     * @param scpVOMap
     * @param ip
     * @param path
     * @param source
     * @return
     */
    private SSHResult getSize(Map<String, ScpVO> scpVOMap, String ip, String path, boolean source) {
        try {
            return sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    return session.executeCommand("cd " + path + ";find -type f | xargs du -b",
                            new DefaultLineProcessor() {
                                public void process(String line, int lineNum) throws Exception {
                                    String[] tmpArray = line.split("\\s+");
                                    if (tmpArray[1].startsWith(".")) {
                                        tmpArray[1] = tmpArray[1].substring(1);
                                    }
                                    ScpVO scpVO = scpVOMap.get(tmpArray[1]);
                                    if (scpVO != null) {
                                        if(source) {
                                            scpVO.setSourceSize(NumberUtils.toLong(tmpArray[0]));
                                        } else {
                                            scpVO.setDestSize(NumberUtils.toLong(tmpArray[0]));
                                        }
                                    }
                                }
                            });
                }
            });
        } catch (SSHException e) {
            logger.error("du ip:{}, path:{}", ip, path, e);
            return sshTemplate.new SSHResult(e);
        }
    }
    
    /**
     * 判断目录是否存在
     * @param ip
     * @return
     */
    public Result<?> dirExist(String ip, String dir) {
        String destDir = dir + "/data";
        Result<?> result = _dirExist(ip, destDir);
        if (result.isOK() && !(Boolean) result.getResult()) {
            return Result.getResult(Status.DB_ERROR).setMessage("目录不存在");
        }
        return result;
    }

    /**
     * 判断目录是否存在
     *
     * @param ip
     * @param dir
     * @return Result.notOK:结果未知;Result<true>:存在;Result<false>:不存在
     */
    private Result<?> _dirExist(String ip, String dir) {
        String comm = "if [ -d \"" + dir + "\" ];then echo 1;else echo 0;fi";
        SSHResult sshResult = null;
        try {
            sshResult = sshTemplate.execute(ip, new SSHCallback() {
                public SSHResult call(SSHSession session) {
                    SSHResult sshResult = session.executeCommand(comm);
                    return sshResult;
                }
            });
        } catch (SSHException e) {
            logger.error("dirExist, ip:{},dir:{}", ip, dir, e);
            return Result.getWebErrorResult(e);
        }
        Result<?> result = wrapSSHResult(sshResult);
        if (!result.isOK()) {
            return result;
        }
        if ("0".equals(result.getResult())) {
            return Result.getResult(false);
        } else if ("1".equals(result.getResult())) {
            return Result.getResult(true);
        }
        return Result.getResult(Status.NO_RESULT);
    }

    /**
     * 删除某个目录
     */
    public Result<?> delete(String ip, String dir) {
        String command = "sudo rm -rf " + dir;
        try {
            return wrapSSHResult(sshTemplate.execute(ip, session -> session.executeCommand(command)));
        } catch (SSHException e) {
            logger.error("unzip, ip:{} command:{}", ip, command, e);
            return Result.getWebErrorResult(e);
        }
    }

    /**
     * 获取某个端口链接数量
     */
    public Result<String> getConnectionCount(String ip, int port) {
        try {
            return (Result<String>) wrapSSHResult(sshTemplate.execute(ip,
                    session -> session.executeCommand(String.format(CONNECTION_COUNT, port))));
        } catch (SSHException e) {
            logger.error("getConnectionCount, ip:{}, port:{}", ip, port, e);
            return Result.getWebErrorResult(e);
        }
    }

    /**
     * 获取某个端口链接地址
     */
    public Result<List<String>> getConnectionAddress(String ip, int port) {
        List<String> connectionAddrList = new ArrayList<>();
        try {
            sshTemplate.execute(ip, session -> session.executeCommand(String.format(CONNECTION_ADDR, port), new DefaultLineProcessor() {
                public void process(String line, int lineNum) throws Exception {
                    connectionAddrList.add(line);
                }
            }));
        } catch (SSHException e) {
            logger.error("getConnectionAddress, ip:{}, port:{}", ip, port, e);
            return Result.getWebErrorResult(e);
        }
        if (connectionAddrList.isEmpty()) {
            return Result.getResult(Status.NO_RESULT);
        }
        return Result.getResult(connectionAddrList);
    }
    
    /**
     * 包装返回结果
     * @param sshResult
     * @return
     */
    private Result<?> wrapSSHResult(SSHResult sshResult){
        if(sshResult == null) {
            return Result.getResult(Status.NO_RESULT);
        }
        if(sshResult.getExcetion() != null) {
            return Result.getWebErrorResult(sshResult.getExcetion());
        }
        if(!sshResult.isSuccess()) {
            return Result.getResult(Status.PARAM_ERROR).setMessage(sshResult.getResult());
        }
        if(sshResult.isSuccess() && sshResult.getResult() != null) {
            return Result.getResult(sshResult.getResult());
        }
        return Result.getOKResult();
    }
}
