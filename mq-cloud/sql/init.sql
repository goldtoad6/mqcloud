-- ----------------------------
-- DATABASE structure for `mq-cloud`
-- ----------------------------
CREATE DATABASE IF NOT EXISTS `mq-cloud` DEFAULT CHARACTER SET utf8;

use `mq-cloud`;
-- ----------------------------
-- Table structure for `audit`
-- ----------------------------
DROP TABLE IF EXISTS `audit`;
CREATE TABLE `audit` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL COMMENT '用户id',
  `type` tinyint(4) NOT NULL COMMENT '申请类型:0:新建TOPIC,1:修改TOPIC ,2:删除TOPIC ,3:新建消费者,4:删除消费者,5:重置offset,6:跳过堆积,7:关联生产者,8:关联消费者,9:成为管理员',
  `info` varchar(360) DEFAULT NULL COMMENT '申请描述',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0:等待审批,1:审批通过,2:驳回',
  `refuse_reason` varchar(360) DEFAULT NULL COMMENT '驳回理由',
  `auditor` varchar(64) DEFAULT NULL COMMENT '审计员(邮箱)',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核主表';

-- ----------------------------
-- Table structure for `audit_associate_consumer`
-- ----------------------------
DROP TABLE IF EXISTS `audit_associate_consumer`;
CREATE TABLE `audit_associate_consumer` (
  `uid` int(11) NOT NULL COMMENT '关联的用户ID',
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `cid` int(11) NOT NULL COMMENT 'consumer id',
  PRIMARY KEY (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核关联消费者相关表';

-- ----------------------------
-- Table structure for `audit_associate_producer`
-- ----------------------------
DROP TABLE IF EXISTS `audit_associate_producer`;
CREATE TABLE `audit_associate_producer` (
  `uid` int(11) NOT NULL COMMENT '关联的用户ID',
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `producer` varchar(64) NOT NULL COMMENT '关联的生产者名字',
  `protocol` int(4) NOT NULL DEFAULT '0' COMMENT '0:remoting,1:http,2:proxy remoting,3:grpc',
  PRIMARY KEY (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核关联生产者相关表';

-- ----------------------------
-- Table structure for `audit_consumer`
-- ----------------------------
DROP TABLE IF EXISTS `audit_consumer`;
CREATE TABLE `audit_consumer` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `consumer` varchar(64) NOT NULL COMMENT '消费者名字',
  `consume_way` int(4) NOT NULL DEFAULT '0' COMMENT '0:集群消费,1:广播消费',
  `trace_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不开启trace,1:开启trace',
  `permits_per_second` int(11) DEFAULT NULL COMMENT 'qps',
  `protocol` int(4) NOT NULL DEFAULT '0' COMMENT '0:remoting,1:http,2:proxy remoting,3:grpc',
  UNIQUE KEY `tid` (`tid`,`consumer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核消费者相关表';

-- ----------------------------
-- Table structure for `audit_consumer_delete`
-- ----------------------------
DROP TABLE IF EXISTS `audit_consumer_delete`;
CREATE TABLE `audit_consumer_delete` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `cid` int(11) NOT NULL COMMENT 'consumer id',
  `consumer` varchar(64) DEFAULT NULL COMMENT 'consumer名字',
  `topic` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核消费者删除相关表';

-- ----------------------------
-- Table structure for `audit_producer_delete`
-- ----------------------------
DROP TABLE IF EXISTS `audit_producer_delete`;
CREATE TABLE `audit_producer_delete` (
  `uid` int(11) NOT NULL,
  `aid` int(11) NOT NULL COMMENT '审核id',
  `pid` int(11) NOT NULL COMMENT 'userProducer id',
  `producer` varchar(64) DEFAULT NULL,
  `topic` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核用户与生产者组关系删除相关表';

-- ----------------------------
-- Table structure for `audit_reset_offset`
-- ----------------------------
DROP TABLE IF EXISTS `audit_reset_offset`;
CREATE TABLE `audit_reset_offset` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `consumer_id` int(11) DEFAULT NULL COMMENT 'consumer id',
  `offset` varchar(64) DEFAULT NULL COMMENT 'null:重置为最大offset,时间戳:重置为某时间点(yyyy-MM-dd#HH:mm:ss:SSS)',
  `message_key` varchar(360) DEFAULT NULL COMMENT '消息key'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核offset相关表';

-- ----------------------------
-- Table structure for `audit_topic`
-- ----------------------------
DROP TABLE IF EXISTS `audit_topic`;
CREATE TABLE `audit_topic` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `name` varchar(64) NOT NULL COMMENT 'topic名',
  `queue_num` int(11) NOT NULL COMMENT '队列长度',
  `producer` varchar(64) NOT NULL COMMENT '生产者名字',
  `ordered` int(4) NOT NULL DEFAULT '0' COMMENT '0:无序,1:有序',
  `trace_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不开启trace,1:开启trace',
  `transaction_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不开启事务,1:开启事务',
  `msg_type` int(4) NOT NULL DEFAULT '0' COMMENT '消息类型，0:普通消息，1:延迟消息，2:定时消息',
  `test_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:非测试topic,1:测试topic',
  `info` varchar(360) DEFAULT NULL COMMENT 'topic描述',
  `qps` int(11) DEFAULT NULL COMMENT '消息量qps预估',
  `qpd` int(11) DEFAULT NULL COMMENT '一天消息量预估',
  `serializer` int(4) NOT NULL DEFAULT '0' COMMENT '序列化器 0:Protobuf,1:String',
  `protocol` int(4) NOT NULL DEFAULT '0' COMMENT '0:remoting,1:http,2:proxy remoting,3:grpc'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核topic相关表';

-- ----------------------------
-- Table structure for `audit_topic_delete`
-- ----------------------------
DROP TABLE IF EXISTS `audit_topic_delete`;
CREATE TABLE `audit_topic_delete` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `topic` varchar(64) DEFAULT NULL COMMENT 'topic名字'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核topic删除相关表';

-- ----------------------------
-- Table structure for `audit_topic_update`
-- ----------------------------
DROP TABLE IF EXISTS `audit_topic_update`;
CREATE TABLE `audit_topic_update` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `queue_num` int(11) NOT NULL COMMENT '队列长度'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核topic更新相关表';

-- ----------------------------
-- Table structure for `audit_user_consumer_delete`
-- ----------------------------
DROP TABLE IF EXISTS `audit_user_consumer_delete`;
CREATE TABLE `audit_user_consumer_delete` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `uid` int(11) NOT NULL COMMENT '此消费者对应的用户',
  `ucid` int(11) NOT NULL COMMENT 'user_consumer id',
  `consumer` varchar(64) DEFAULT NULL,
  `topic` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核用户与消费者组关系删除相关表';

-- ----------------------------
-- Table structure for `audit_resend_message`
-- ----------------------------
DROP TABLE IF EXISTS `audit_resend_message`;
CREATE TABLE `audit_resend_message` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `msgId` char(32) NOT NULL COMMENT 'broker offset msg id',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '申请类型:0:未处理,1:发送成功,2:发送失败',
  `times` int(11) NOT NULL DEFAULT '0' COMMENT '发送次数',
  `send_time` datetime COMMENT '发送时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='消息重发审核表';

-- ----------------------------
-- Table structure for `audit_resend_message_consumer`
-- ----------------------------
CREATE TABLE `audit_resend_message_consumer` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `consumer_id` int(11) NOT NULL COMMENT 'consumer id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='消息重发给消费者审核表';

-- ----------------------------
-- Table structure for `audit_topic_trace`
-- ----------------------------
CREATE TABLE `audit_topic_trace` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `trace_enabled` int(11) NOT NULL COMMENT '0:不开启trece,1:开启trace'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核topic trace相关表';

-- ----------------------------
-- Table structure for `audit_timespan_message_consume`
-- ----------------------------
DROP TABLE IF EXISTS `audit_timespan_message_consume`;
CREATE TABLE `audit_timespan_message_consume` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `topic` varchar(64) NOT NULL COMMENT 'topic',
  `consumer` varchar(64) NOT NULL COMMENT 'consumer',
  `client_id` varchar(255) DEFAULT NULL COMMENT '暂停的客户端Id',
  `start` bigint(20) DEFAULT NULL COMMENT '消费开始时间戳',
  `end` bigint(20) DEFAULT NULL COMMENT '消费结束时间戳'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='时间段消息消费审核表';

-- ----------------------------
-- Table structure for `broker_traffic`
-- ----------------------------
DROP TABLE IF EXISTS `broker_traffic`;
CREATE TABLE `broker_traffic` (
  `ip` varchar(255) NOT NULL COMMENT 'addr',
  `create_date` date NOT NULL COMMENT '数据收集天',
  `create_time` char(4) NOT NULL COMMENT '数据收集小时分钟,格式:HHMM',
  `cluster_id` int(11) NOT NULL COMMENT 'cluster_id',
  `put_count` bigint(20) NOT NULL DEFAULT '0' COMMENT '生产消息量',
  `put_size` bigint(20) NOT NULL DEFAULT '0' COMMENT '生产消息大小',
  `get_count` bigint(20) NOT NULL DEFAULT '0' COMMENT '消费消息量',
  `get_size` bigint(20) NOT NULL DEFAULT '0' COMMENT '消费消息大小',
  PRIMARY KEY (`ip`,`create_date`,`create_time`),
  KEY `time` (`create_date`,`cluster_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='broker流量表';

-- ----------------------------
-- Table structure for `client_version`
-- ----------------------------
DROP TABLE IF EXISTS `client_version`;
CREATE TABLE `client_version` (
  `topic` varchar(255) NOT NULL,
  `client` varchar(255) NOT NULL,
  `role` tinyint(4) NOT NULL COMMENT '1:producer,2:consumer',
  `version` varchar(255) NOT NULL,
  `create_date` date NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY `topic` (`topic`,`client`,`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='topic客户端版本';

-- ----------------------------
-- Table structure for `cluster`
-- ----------------------------
DROP TABLE IF EXISTS `cluster`;
CREATE TABLE `cluster` (
  `id` int(11) NOT NULL COMMENT '集群id，也会作为ns发现的一部分',
  `name` varchar(64) NOT NULL COMMENT '集群名',
  `vip_channel_enabled` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否开启vip通道, 1:开启, 0:关闭, rocketmq 4.x版本默认开启',
  `online` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否为线上集群, 1:是, 0:否, 线上集群会开启流量抓取',
  `transaction_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不支持事务,1:支持事务',
  `trace_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不支持trace,1:支持trace',
  `status` tinyint(4) default 0 comment '状态:0:正常,1:更新中',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='集群表';

-- ----------------------------
-- Table structure for `common_config`
-- ----------------------------
DROP TABLE IF EXISTS `common_config`;
CREATE TABLE `common_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(64) DEFAULT NULL COMMENT '配置key',
  `value` varchar(20000) DEFAULT '' COMMENT '配置值',
  `comment` varchar(256) DEFAULT '' COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `consumer`
-- ----------------------------
DROP TABLE IF EXISTS `consumer`;
CREATE TABLE `consumer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `name` varchar(64) NOT NULL COMMENT 'consumer名',
  `consume_way` int(4) NOT NULL DEFAULT '0' COMMENT '0:集群消费,1:广播消费',
  `create_date` date NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `trace_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不开启trace,1:开启trace',
  `protocol` int(4) NOT NULL DEFAULT '0' COMMENT '0:remoting,1:http,2:proxy remoting,3:grpc',
  `info` varchar(360) DEFAULT NULL COMMENT '消费者描述',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `tid` (`tid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='消费者表';

-- ----------------------------
-- Table structure for `consumer_block`
-- ----------------------------
DROP TABLE IF EXISTS `consumer_block`;
CREATE TABLE `consumer_block` (
  `csid` int(11) DEFAULT NULL COMMENT 'consumer_stat id',
  `instance` varchar(255) DEFAULT NULL COMMENT 'consumer instance_id',
  `updatetime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `broker` varchar(255) DEFAULT NULL COMMENT 'broker',
  `qid` int(11) DEFAULT NULL COMMENT 'qid',
  `block_time` bigint(20) DEFAULT NULL COMMENT '毫秒=当前时间-最新消费时间',
  `offset_moved_times` int(11) DEFAULT '0' COMMENT 'offset moved times',
  `offset_moved_time` bigint(20) DEFAULT NULL COMMENT 'offset moved msg store time',
  UNIQUE KEY `csid` (`csid`,`broker`,`qid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `consumer_stat`
-- ----------------------------
DROP TABLE IF EXISTS `consumer_stat`;
CREATE TABLE `consumer_stat` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `consumer_group` varchar(255) DEFAULT NULL COMMENT 'consumer group',
  `topic` varchar(255) DEFAULT NULL COMMENT 'host',
  `updatetime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `undone_msg_count` bigint(20) DEFAULT NULL COMMENT '未消费的消息量',
  `undone_1q_msg_count`bigint(20) DEFAULT NULL COMMENT '单队列未消费的最大消息量',
  `undone_delay` bigint(20) DEFAULT NULL COMMENT '毫秒=broker最新消息存储时间-最新消费时间',
  `sbscription` varchar(255) DEFAULT NULL COMMENT '订阅关系,如果一个group订阅不同的topic,在这里会有体现',
  PRIMARY KEY (`id`),
  UNIQUE KEY `consumer_group` (`consumer_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `consumer_traffic`
-- ----------------------------
DROP TABLE IF EXISTS `consumer_traffic`;
CREATE TABLE `consumer_traffic` (
  `consumer_id` int(11) NOT NULL DEFAULT '0' COMMENT 'consumer id',
  `create_date` date NOT NULL COMMENT '数据收集天',
  `create_time` char(4) NOT NULL COMMENT '数据收集小时分钟,格式:HHMM',
  `count` bigint(20) DEFAULT NULL COMMENT 'consumer pull times',
  `size` bigint(20) DEFAULT NULL COMMENT 'consumer pull size',
  PRIMARY KEY (`consumer_id`,`create_date`,`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='消费者流量表';

-- ----------------------------
-- Table structure for `feedback`
-- ----------------------------
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL COMMENT '用户id',
  `content` text NOT NULL COMMENT '反馈内容',
  `create_date` datetime NOT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='反馈表';

-- ----------------------------
-- Table structure for `need_warn_config`
-- ----------------------------
DROP TABLE IF EXISTS `need_warn_config`;
CREATE TABLE `need_warn_config` (
  `oKey` varchar(255) NOT NULL COMMENT '报警频率的key（type_topic_group）',
  `times` int(11) NOT NULL COMMENT '次数',
  `update_time` bigint(13) NOT NULL COMMENT '计时起始时间时间',
  UNIQUE KEY `key` (`oKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='报警频率表';

-- ----------------------------
-- Table structure for `notice`
-- ----------------------------
DROP TABLE IF EXISTS `notice`;
CREATE TABLE `notice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `content` varchar(512) NOT NULL COMMENT '通知内容',
  `status` tinyint(4) NOT NULL COMMENT '0:无效,1:有效',
  `create_date` date NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='通知表';

-- ----------------------------
-- Table structure for `producer_stat`
-- ----------------------------
DROP TABLE IF EXISTS `producer_stat`;
CREATE TABLE `producer_stat` (
  `total_id` int(11) NOT NULL COMMENT 'producer_total_stat id',
  `broker` varchar(20) NOT NULL COMMENT 'broker',
  `max` int(11) NOT NULL COMMENT '最大耗时',
  `avg` double NOT NULL COMMENT '平均耗时',
  `count` int(11) NOT NULL COMMENT '调用次数',
  `exception` text COMMENT '异常记录',
  KEY `total_id` (`total_id`,`broker`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='生产者统计';

-- ----------------------------
-- Table structure for `producer_total_stat`
-- ----------------------------
DROP TABLE IF EXISTS `producer_total_stat`;
CREATE TABLE `producer_total_stat` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producer` varchar(255) NOT NULL COMMENT 'producer',
  `ip` varchar(100) NOT NULL COMMENT 'ip',
  `client` varchar(100) NOT NULL COMMENT 'client',
  `percent90` int(11) NOT NULL COMMENT '耗时百分位90',
  `percent99` int(11) NOT NULL COMMENT '耗时百分位99',
  `avg` double NOT NULL COMMENT '平均耗时',
  `count` int(11) NOT NULL COMMENT '调用次数',
  `create_date` int(11) NOT NULL COMMENT '创建日期',
  `create_time` char(4) NOT NULL COMMENT '创建分钟,格式:HHMM',
  `stat_time` int(11) NOT NULL COMMENT '统计时间',
  `exception` text COMMENT '异常记录',
  PRIMARY KEY (`id`),
  UNIQUE KEY `producer` (`producer`,`stat_time`,`client`),
  KEY `create_date` (`create_date`,`producer`),
  KEY `date_client` (`create_date`,`client`),
  KEY `date_ip` (`create_date`,`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='生产者总体统计';

-- ----------------------------
-- Table structure for `server`
-- ----------------------------
DROP TABLE IF EXISTS `server`;
CREATE TABLE `server` (
  `ip` varchar(16) NOT NULL COMMENT 'ip',
  `machine_type` int(4) DEFAULT NULL COMMENT '机器类型：0-未知，1-物理机，2-虚拟机，3-docker',
  `host` varchar(255) DEFAULT NULL COMMENT 'host',
  `nmon` varchar(255) DEFAULT NULL COMMENT 'nmon version',
  `cpus` tinyint(4) DEFAULT NULL COMMENT 'logic cpu num',
  `cpu_model` varchar(255) DEFAULT NULL COMMENT 'cpu 型号',
  `dist` varchar(255) DEFAULT NULL COMMENT '发行版信息',
  `kernel` varchar(255) DEFAULT NULL COMMENT '内核信息',
  `ulimit` varchar(255) DEFAULT NULL COMMENT 'ulimit -n,ulimit -u',
  `updatetime` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `room` varchar(255) DEFAULT NULL COMMENT '机房',
  PRIMARY KEY (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `server_stat`
-- ----------------------------
DROP TABLE IF EXISTS `server_stat`;
CREATE TABLE `server_stat` (
  `ip` varchar(16) NOT NULL COMMENT 'ip',
  `cdate` date NOT NULL COMMENT '数据收集天',
  `ctime` char(4) NOT NULL COMMENT '数据收集小时分钟',
  `cuser` float DEFAULT NULL COMMENT '用户态占比',
  `csys` float DEFAULT NULL COMMENT '内核态占比',
  `cwio` float DEFAULT NULL COMMENT 'wio占比',
  `c_ext` text COMMENT '子cpu占比',
  `cload1` float DEFAULT NULL COMMENT '1分钟load',
  `cload5` float DEFAULT NULL COMMENT '5分钟load',
  `cload15` float DEFAULT NULL COMMENT '15分钟load',
  `mtotal` float DEFAULT NULL COMMENT '总内存,单位M',
  `mfree` float DEFAULT NULL COMMENT '空闲内存',
  `mcache` float DEFAULT NULL COMMENT 'cache',
  `mbuffer` float DEFAULT NULL COMMENT 'buffer',
  `mswap` float DEFAULT NULL COMMENT 'cache',
  `mswap_free` float DEFAULT NULL COMMENT 'cache',
  `nin` float DEFAULT NULL COMMENT '网络入流量 单位K/s',
  `nout` float DEFAULT NULL COMMENT '网络出流量 单位k/s',
  `nin_ext` text COMMENT '各网卡入流量详情',
  `nout_ext` text COMMENT '各网卡出流量详情',
  `tuse` int(11) DEFAULT NULL COMMENT 'tcp estab连接数',
  `torphan` int(11) DEFAULT NULL COMMENT 'tcp orphan连接数',
  `twait` int(11) DEFAULT NULL COMMENT 'tcp time wait连接数',
  `dread` float DEFAULT NULL COMMENT '磁盘读速率 单位K/s',
  `dwrite` float DEFAULT NULL COMMENT '磁盘写速率 单位K/s',
  `diops` float DEFAULT NULL COMMENT '磁盘io速率 交互次数/s',
  `dbusy` float DEFAULT NULL COMMENT '磁盘io带宽使用百分比',
  `d_ext` text COMMENT '磁盘各分区占比',
  `dspace` text COMMENT '磁盘各分区空间使用率',
  PRIMARY KEY (`ip`,`cdate`,`ctime`),
  KEY `cdate` (`cdate`,`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `shedlock`
-- ----------------------------
DROP TABLE IF EXISTS `shedlock`;
CREATE TABLE `shedlock` (
  `name` varchar(64) NOT NULL DEFAULT '',
  `lock_until` timestamp(3) NULL DEFAULT NULL,
  `locked_at` timestamp(3) NULL DEFAULT NULL,
  `locked_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `topic`
-- ----------------------------
DROP TABLE IF EXISTS `topic`;
CREATE TABLE `topic` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cluster_id` int(11) NOT NULL COMMENT 'cluster id',
  `name` varchar(64) NOT NULL COMMENT 'topic名',
  `queue_num` int(11) NOT NULL COMMENT '队列长度',
  `ordered` int(4) NOT NULL DEFAULT '0' COMMENT '0:无序,1:有序',
  `count` int(11) DEFAULT NULL COMMENT 'topic put times in one hour',
  `size` bigint(20) DEFAULT '0' COMMENT 'topic put size in one hour',
  `info` varchar(360) DEFAULT NULL COMMENT 'topic描述',
  `trace_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不开启trace,1:开启trace',
  `msg_type` int(4) NOT NULL DEFAULT '0' COMMENT '消息类型，0:普通消息，1:延迟消息，2:定时消息',
  `create_date` date NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `serializer` int(4) NOT NULL DEFAULT '0' COMMENT '序列化器 0:Protobuf,1:String',
  `traffic_warn_enabled` int(4) NOT NULL DEFAULT '0' COMMENT '0:不开启流量突增预警,1:开启流量突增预警',
  `effective` int(4) NOT NULL DEFAULT '0' COMMENT '状态确认 0 未确认 1 确认',
  `size_1d` bigint(20) DEFAULT '0' COMMENT 'topic put size in one day',
  `size_2d` bigint(20) DEFAULT '0' COMMENT 'topic put size in two days',
  `size_3d` bigint(20) DEFAULT '0' COMMENT 'topic put size in three days',
  `size_5d` bigint(20) DEFAULT '0' COMMENT 'topic put size in five days',
  `size_7d` bigint(20) DEFAULT '0' COMMENT 'topic put size in seven days',
  `count_1d` bigint(20) DEFAULT '0' COMMENT 'topic put count in one day',
  `count_2d` bigint(20) DEFAULT '0' COMMENT 'topic put count in two days',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='topic表';

-- ----------------------------
-- Table structure for `topic_traffic`
-- ----------------------------
DROP TABLE IF EXISTS `topic_traffic`;
CREATE TABLE `topic_traffic` (
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `create_date` date NOT NULL COMMENT '数据收集天',
  `create_time` char(4) NOT NULL COMMENT '数据收集小时分钟,格式:HHMM',
  `count` bigint(20) DEFAULT NULL COMMENT 'topic put times',
  `size` bigint(20) DEFAULT NULL COMMENT 'topic put size',
  PRIMARY KEY (`tid`,`create_date`,`create_time`),
  KEY `time` (`create_date`,`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='topic流量表';

-- ----------------------------
-- Table structure for `user`
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL COMMENT '用户名',
  `email` varchar(64) NOT NULL COMMENT '邮箱',
  `mobile` varchar(16) DEFAULT NULL COMMENT '手机',
  `type` int(4) NOT NULL DEFAULT '0' COMMENT '0:普通用户,1:管理员',
  `create_date` date NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `receive_notice` int(4) NOT NULL DEFAULT '0' COMMENT '管理员是否接收邮件通知,0:不接收,1:接收',
  `password` varchar(256) COMMENT '登录方式采用用户名密码验证时使用',
  `receive_phone_notice` int(4) NOT NULL DEFAULT '0' COMMENT '用户是否接收手机通知,0:不接收,1:接收',
  `gid` int(11) NOT NULL DEFAULT '0' COMMENT '组id',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户表';

-- ----------------------------
-- Table structure for `user_consumer`
-- ----------------------------
DROP TABLE IF EXISTS `user_consumer`;
CREATE TABLE `user_consumer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL COMMENT '用户id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `consumer_id` int(11) DEFAULT NULL COMMENT 'consumer id',
  PRIMARY KEY (`id`),
  KEY `t_c` (`tid`,`consumer_id`),
  KEY `u_t` (`uid`,`tid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户与消费者关系表';

-- ----------------------------
-- Table structure for `user_message`
-- ----------------------------
DROP TABLE IF EXISTS `user_message`;
CREATE TABLE `user_message` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL COMMENT '用户id',
  `message` varchar(512) NOT NULL COMMENT '消息内容',
  `status` tinyint(4) NOT NULL COMMENT '0:未读,1:已读',
  `create_date` datetime NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户消息表';

-- ----------------------------
-- Table structure for `user_producer`
-- ----------------------------
DROP TABLE IF EXISTS `user_producer`;
CREATE TABLE `user_producer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL COMMENT '用户id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `producer` varchar(64) NOT NULL COMMENT 'producer名',
  `protocol` int(4) NOT NULL DEFAULT '0' COMMENT '0:remoting,1:http,2:proxy remoting,3:grpc',
  PRIMARY KEY (`id`),
  KEY `t_p` (`tid`,`producer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户与生产者关系表';

-- ----------------------------
-- Table structure for `warn_config`
-- ----------------------------
DROP TABLE IF EXISTS `warn_config`;
CREATE TABLE `warn_config` (
  `consumer` varchar(64) DEFAULT '' COMMENT 'consumer名，为空时代表默认（仅一条默认记录）',
  `accumulate_time` int(11) DEFAULT '300000' COMMENT '堆积时间',
  `accumulate_count` int(11) DEFAULT '10000' COMMENT '堆积数量',
  `block_time` int(11) DEFAULT '10000' COMMENT '阻塞时间',
  `consumer_fail_count` int(11) DEFAULT '10' COMMENT '消费失败数量',
  `warn_unit_time` int(4) DEFAULT '1' COMMENT '报警频率的单位时间，单位小时',
  `warn_unit_count` int(4) DEFAULT '2' COMMENT '报警频率在单位时间的次数',
  `ignore_warn` int(4) DEFAULT '0' COMMENT '0:接收所有报警,1:不接收所有报警，此字段优先级最高',
  unique key (`consumer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='报警阈值配置表';

-- ----------------------------
-- Table structure for `name_server`
-- ----------------------------
DROP TABLE IF EXISTS `name_server`;
CREATE TABLE `name_server` (
  `cid` int(11) NOT NULL COMMENT '集群id',
  `addr` varchar(255) NOT NULL COMMENT 'name server 地址',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `check_status` tinyint(4) DEFAULT 0 COMMENT '检测结果:0:未知,1:正常,2:异常',
  `check_time` datetime COMMENT '检测时间',
  `base_dir` varchar(360) DEFAULT '/opt/mqcloud/ns' COMMENT '安装路径',
  `status` tinyint(4) DEFAULT 0 COMMENT '状态:0:正常,1:流量剔除',
  UNIQUE KEY `cid` (`cid`,`addr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='name server表';

-- ----------------------------
-- Table structure for `server_warn_config`
-- ----------------------------
DROP TABLE IF EXISTS `server_warn_config`;
CREATE TABLE `server_warn_config` (
  `ip` varchar(15) NOT NULL COMMENT 'ip',
  `memory_usage_rate` int(4) NOT NULL DEFAULT '0' COMMENT '内存使用率',
  `load1` int(4) NOT NULL DEFAULT '0' COMMENT '一分钟load',
  `connect` int(4) NOT NULL DEFAULT '0' COMMENT 'tcp连接数',
  `wait` int(4) NOT NULL DEFAULT '0' COMMENT 'tcp等待数',
  `iops` int(4) NOT NULL DEFAULT '0' COMMENT '磁盘io速率 交互次数/s',
  `iobusy` int(4) NOT NULL DEFAULT '0' COMMENT '磁盘io带宽使用百分比',
  `cpu_usage_rate` int(4) NOT NULL DEFAULT '0' COMMENT 'cpu使用率',
  `net_in` int(4) NOT NULL DEFAULT '0' COMMENT '入网流量',
  `net_out` int(4) NOT NULL DEFAULT '0' COMMENT '出网流量',
  `io_usage_rate` int(4) NOT NULL DEFAULT '0' COMMENT '磁盘使用率',
  UNIQUE KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='服务器预警配置表';

-- ----------------------------
-- Table structure for `broker`
-- ----------------------------
DROP TABLE IF EXISTS `broker`;
CREATE TABLE `broker` (
  `cid` int(11) NOT NULL COMMENT '集群id',
  `addr` varchar(255) NOT NULL COMMENT 'broker 地址',
  `broker_name` varchar(64) NOT NULL COMMENT 'broker名字',
  `broker_id` int(4) NOT NULL COMMENT 'broker ID，0-master，1-slave',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `check_status` tinyint(4) DEFAULT 0 COMMENT '检测结果:0:未知,1:正常,2:异常',
  `check_time` datetime COMMENT '检测时间',
  `base_dir` varchar(360) DEFAULT NULL COMMENT '安装路径',
  `writable` int(4) NOT NULL DEFAULT '1' COMMENT '0:不可写入,1:可写入',
  `size_1d` bigint(20) DEFAULT '0' COMMENT 'put size in one day',
  `size_2d` bigint(20) DEFAULT '0' COMMENT 'put size in two days',
  `size_3d` bigint(20) DEFAULT '0' COMMENT 'put size in three days',
  `size_5d` bigint(20) DEFAULT '0' COMMENT 'put size in five days',
  `size_7d` bigint(20) DEFAULT '0' COMMENT 'put size in seven days',
  `version` varchar(64) NOT NULL DEFAULT '5' COMMENT 'broker版本:4,5',
  UNIQUE KEY `cid` (`cid`,`addr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='broker表';

-- ----------------------------
-- Table structure for `consumer_client_stat`
-- ----------------------------
DROP TABLE IF EXISTS `consumer_client_stat`;
CREATE TABLE `consumer_client_stat` (
  `consumer` varchar(255) NOT NULL COMMENT 'consumer',
  `client` varchar(20) NOT NULL COMMENT 'client',
  `create_date` date NOT NULL COMMENT '创建日期',
  KEY `cck` (`create_date`,`client`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='消费者客户端统计表';

-- ----------------------------
-- Table structure for `audit_batch_associate`
-- ----------------------------
DROP TABLE IF EXISTS `audit_batch_associate`;
CREATE TABLE `audit_batch_associate` (
  `uids` text NOT NULL COMMENT '关联的用户id',
  `aid` int(11) NOT NULL COMMENT '审核id',
  `producer_ids` text NULL COMMENT '生产者id',
  `consumer_ids` text NULL COMMENT '消费者id',
  PRIMARY KEY (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核批量关联';

-- ----------------------------
-- Table structure for `broker_store_stat`
-- ----------------------------
DROP TABLE IF EXISTS `broker_store_stat`;
CREATE TABLE `broker_store_stat` (
  `cluster_id` int(11) NOT NULL COMMENT 'cluster_id',
  `broker_ip` varchar(255) NOT NULL COMMENT 'broker ip',
  `percent90` int(11) NOT NULL COMMENT '耗时百分位90',
  `percent99` int(11) NOT NULL COMMENT '耗时百分位99',
  `avg` double NOT NULL COMMENT '平均耗时',
  `max` int(11) NOT NULL COMMENT '最大耗时',
  `count` bigint(20) NOT NULL COMMENT '调用次数',
  `create_date` int(11) NOT NULL COMMENT '创建日期',
  `create_time` char(4) NOT NULL COMMENT '创建分钟,格式:HHMM',
  `stat_time` int(11) NOT NULL COMMENT '统计时间',
  PRIMARY KEY (`create_date`,`broker_ip`,`create_time`, `cluster_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='broker存储统计';
-- ----------------------------
-- user init
-- ----------------------------
INSERT INTO `user`(`id`, name, email, mobile, type, create_date, update_time, receive_notice, password) VALUES ('1', 'admin', 'admin@admin.com', '18688888888', '1', '2018-10-01', '2018-10-01 09:49:00', '1', '21232f297a57a5a743894a0e4a801fc3');

-- ----------------------------
-- common_config init
-- ----------------------------
INSERT INTO `common_config` VALUES ('1', 'domain', '127.0.0.1:8080', 'mqcloud的域名');
INSERT INTO `common_config` VALUES ('5', 'serverUser', 'mqcloud', '服务器 ssh 用户');
INSERT INTO `common_config` VALUES ('6', 'serverPassword', '9j7t4SDJOIusddca+Mzd6Q==', '服务器 ssh 密码');
INSERT INTO `common_config` VALUES ('7', 'serverPort', '22', '服务器 ssh 端口');
INSERT INTO `common_config` VALUES ('8', 'serverConnectTimeout', '6000', '服务器 ssh 链接建立超时时间');
INSERT INTO `common_config` VALUES ('9', 'serverOPTimeout', '12000', '服务器 ssh 操作超时时间');
INSERT INTO `common_config` VALUES ('10', 'ciperKey', 'DJs32jslkdghDSDf', '密码助手的key,长度需为8的倍数');
INSERT INTO `common_config` VALUES ('12', 'operatorContact', '[{\"name\":\"admin\",\"phone\":\"010-1234\",\"mobile\":\"18688888888\",\"qq\":\"88888888\",\"email\":\"admin@admin.com\"}]', '运维人员json');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mailHost', 'smtp.xx.com', '邮件服务器域名');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mailUsername', 'xxx@xx.com', '邮件服务器用户');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mailPassword', '密码或授权码', '邮件服务器用户密码');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mailPort', '25', '邮件服务器端口');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mailProtocol', 'smtp', '邮件服务器通信协议');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mailTimeout', '10000', '邮件服务器超时时间');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mailUseSSL', 'false', '邮件是否使用SSL');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('isOpenRegister', '1', '是否开启注册功能：0-不开启，1-开启');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('rocketmqFilePath', 'classpath:static/software/rocketmq.zip', 'rocketmq安装文件路径，支持以下三种资源加载方式,例如 1:classpath:static/software/rocketmq.zip 2：file:///tmp/rocketmq.zip 3：http://127.0.0.1:8080/software/rocketmq.zip');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('rocketmq5FilePath', 'classpath:static/software/rocketmq5.zip', 'rocketmq5安装文件路径，支持以下三种资源加载方式,例如 1:classpath:static/software/rocketmq5.zip 2：file:///tmp/rocketmq5.zip 3：http://127.0.0.1:8080/software/rocketmq5.zip');
INSERT INTO `common_config`(`key`, `comment`) VALUES ('adminAccessKey', '管理员访问名(broker&nameserver使用)');
INSERT INTO `common_config`(`key`, `comment`) VALUES ('adminSecretKey', '管理员访问私钥(broker&nameserver使用)');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('machineRoom', '["默认"]', '机房列表');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('machineRoomColor', '["#95a5a6"]', '机房节点颜色');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('queryMessageFromSlave', 'true', '是否从slave查询消息');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('consumeFallBehindSize', '1073741824', '消费落后多少进行预警,单位byte');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('messageTypeLocation', 'classpath*:msg-type/*.class', '消息序列化方式为protostuf并且发送为自定义类型时，需要配置消息类型的class路径,例如 1:classpath*:msg-type/*.class 2：jar:file:///tmp/msgType.jar!/**/*.class 3：jar:http://127.0.0.1:8080/msgType.jar!/**/*.class');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('slaveFallBehindSize', '10485760', 'slave的commitlog落后master多少进行预警,单位byte');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('mqProxyServerString', '127.0.0.1', 'MQProxy服务器地址列表，多个用逗号分割');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('oldReqestCodeBrokerSet', '', '使用旧请求码的broker列表，例如：["127.0.0.1:10911","127.0.0.2:10911"]');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('clientGroupNSConfig', '{}', '客户端ns配置');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('proxyAcls', '', 'proxy的acl列表，例如：[{"clusterId":1,"accessKey":"RocketMQ","secretKey":"12345678"}]');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('exportedMessageLocalPath', '/tmp', '消息导出时的本地路径，例如/tmp');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('exportedMessageRemotePath', '消息导出时的远程地址，例如127.0.0.1:/tmp，请赋予mqcloud权限');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('exportedMessageDownloadUrlPrefix', '消息导出时的下载地址，例如http://127.0.0.1/tmp/，请用http开头');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('ignoreErrorProducerSet', '[]', '忽略生产错误预警的生产者');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('orderTopicKVConfig', '{}', '全局有序topic路由配置');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('rsyncConfig', '{"user":"mqcloud","module":"mqcloud","password":"rsync"}', 'rsync配置');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('pauseAudit', 'false', '在集群运维时，设置为true，会暂停审核功能，保障数据安全');
INSERT INTO `common_config`(`key`, `value`, `comment`) VALUES ('clusterStoreWarnConfig', '[{"max":500,"percent99":400}]', '集群broker存储过慢预警配置，默认为最大响应超过500ms或百分之99响应超过400ms进行预警，可以单独对某个集群进行配置，例如[{"max":500,"percent99":400},{"clusterId":1,"max":1000,"percent99":800}]');
insert into `common_config`(`key`, `value`, `comment`) values ('mqcloudServers', '["127.0.0.1"]', 'mqcloud的server列表');
-- ----------------------------
-- warn_config init
-- ----------------------------
INSERT INTO `warn_config`(accumulate_time,accumulate_count,block_time,consumer_fail_count,warn_unit_time,warn_unit_count,ignore_warn) VALUES (300000, 10000, 10000, 10, 1, 1, 0);

-- ----------------------------
-- notice init
-- ----------------------------
INSERT INTO `notice` (`content`, `status`, `create_date`) VALUES ('欢迎您使用MQCloud，为了更好为您的服务，请花一分钟时间看下文档，如果有任何问题，欢迎联系我们^_^', 1, now());

-- ----------------------------
-- user message init
-- ----------------------------
INSERT INTO `user_message` (`uid`, `message`, `status`, `create_date`) VALUES (1, 'Hello！Welcome to MQCloud！', 0, now());

-- ----------------------------
-- Table structure for `cluster_config`
-- ----------------------------
DROP TABLE IF EXISTS `cluster_config`;
CREATE TABLE `cluster_config` (
  `cid` int(11) NOT NULL COMMENT '集群id',
  `bid` int(11) NOT NULL COMMENT 'broker config id',
  `online_value` varchar(256) COMMENT '线上值',
  UNIQUE KEY `cid_key` (`cid`,`bid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `broker_config_group`
-- ----------------------------
DROP TABLE IF EXISTS `broker_config_group`;
CREATE TABLE `broker_config_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group` varchar(255) NOT NULL COMMENT '配置组',
  `order` int(11) NOT NULL COMMENT '序号小排前',
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_key`  (`group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `broker_config`
-- ----------------------------
DROP TABLE IF EXISTS `broker_config`;
CREATE TABLE `broker_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gid` int(11) NOT NULL COMMENT '组id',
  `key` varchar(255) NOT NULL COMMENT '配置key',
  `value` varchar(256) COMMENT '配置值',
  `desc` varchar(256) COMMENT '描述',
  `tip` varchar(256) COMMENT '提示',
  `order` int(11) NOT NULL COMMENT '序号小排前',
  `dynamic_modify` tinyint(4) NOT NULL COMMENT '0:修改后需要重启,1:修改后实时生效',
  `option` varchar(256) COMMENT '选项',
  `required` tinyint(4) DEFAULT 0 COMMENT '0:可选配置,1:必选配置',
  PRIMARY KEY (`id`),
  UNIQUE KEY `bkey`  (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for `audit_consumer_config`
-- ----------------------------
DROP TABLE IF EXISTS `audit_consumer_config`;
CREATE TABLE `audit_consumer_config` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `consumer_id` int(11) DEFAULT NULL COMMENT 'consumer id',
  `permits_per_second` float DEFAULT NULL COMMENT 'qps',
  `enable_rate_limit` tinyint(4) DEFAULT NULL COMMENT '0:不限速,1:限速',
  `pause` tinyint(4) DEFAULT NULL COMMENT '0:不暂停,1:暂停',
  `unregister` tinyint(4) DEFAULT NULL COMMENT '0:不解注册,1:解注册',
  `pause_client_id` varchar(255) DEFAULT NULL COMMENT '暂停的客户端Id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核消费者配置相关表';

-- ----------------------------
-- Table structure for `consumer_config`
-- ----------------------------
DROP TABLE IF EXISTS `consumer_config`;
CREATE TABLE `consumer_config` (
  `consumer` varchar(64) NOT NULL COMMENT 'consumer名',
  `retry_message_reset_to` bigint(20) DEFAULT NULL COMMENT '重置至时间戳，小于此时间的都将不再消息',
  `permits_per_second` float DEFAULT NULL COMMENT 'qps',
  `enable_rate_limit` tinyint(4) DEFAULT NULL COMMENT '0:不限速,1:限速',
  `pause` tinyint(4) DEFAULT NULL COMMENT '0:不暂停,1:暂停',
  `retry_message_skip_key` varchar(360) DEFAULT NULL COMMENT '消息key',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  UNIQUE KEY `consumer` (`consumer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户端配置表';


-- ----------------------------
-- Table structure for `consumer_pause_config`
-- ----------------------------
DROP TABLE IF EXISTS `consumer_pause_config`;
CREATE TABLE `consumer_pause_config` (
    `consumer`               varchar(64) NOT NULL COMMENT 'consumer名',
    `pause_client_id`        varchar(255)         DEFAULT NULL COMMENT '暂停的客户端Id',
    `unregister`             tinyint(4) DEFAULT NULL COMMENT '0:不解注册,1:解注册',
    `update_time`            timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY `c_p_c` (`consumer`, `pause_client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户端暂停配置表';

-- ----------------------------
-- Table structure for `topic_traffic_stat`
-- ----------------------------
DROP TABLE IF EXISTS `topic_traffic_stat`;
CREATE TABLE `topic_traffic_stat` (
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `avg_max` bigint(20) NOT NULL COMMENT '指定天数内,每天流量最大值的平均值',
  `max_max` bigint(20) NOT NULL COMMENT '指定天数内,去除异常点后流量的最大值',
  `days` int(4) NOT NULL COMMENT '指定统计流量的天数',
  `update_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`tid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='topic流量统计表';

-- ----------------------------
-- `broker_config_group` record
-- ----------------------------
insert into broker_config_group(`id`, `group`, `order`) values(1, '常见配置', 1);
insert into broker_config_group(`id`, `group`, `order`) values(2, '发现机制', 2);
insert into broker_config_group(`id`, `group`, `order`) values(3, 'topic&订阅', 3);
insert into broker_config_group(`id`, `group`, `order`) values(4, '写入限流机制', 4);
insert into broker_config_group(`id`, `group`, `order`) values(5, '请求处理线程池', 5);
insert into broker_config_group(`id`, `group`, `order`) values(6, '内存预热', 6);
insert into broker_config_group(`id`, `group`, `order`) values(7, 'CommitLog相关', 7);
insert into broker_config_group(`id`, `group`, `order`) values(8, 'ConsumeQueue相关', 8);
insert into broker_config_group(`id`, `group`, `order`) values(9, '堆外内存相关', 9);
insert into broker_config_group(`id`, `group`, `order`) values(10, 'HA机制', 10);
insert into broker_config_group(`id`, `group`, `order`) values(11, '数据文件保留机制', 11);
insert into broker_config_group(`id`, `group`, `order`) values(12, '消息相关', 12);
insert into broker_config_group(`id`, `group`, `order`) values(13, '消费优化', 13);
insert into broker_config_group(`id`, `group`, `order`) values(14, '拉取消息', 14);
insert into broker_config_group(`id`, `group`, `order`) values(15, '快速失败机制', 15);
insert into broker_config_group(`id`, `group`, `order`) values(16, 'broker保护机制', 16);
insert into broker_config_group(`id`, `group`, `order`) values(17, '注册相关', 17);
insert into broker_config_group(`id`, `group`, `order`) values(18, '事务相关', 18);
insert into broker_config_group(`id`, `group`, `order`) values(19, 'salve相关', 19);
insert into broker_config_group(`id`, `group`, `order`) values(20, 'filter相关', 20);
insert into broker_config_group(`id`, `group`, `order`) values(21, 'netty server相关', 21);
insert into broker_config_group(`id`, `group`, `order`) values(22, 'netty client相关', 22);
insert into broker_config_group(`id`, `group`, `order`) values(23, 'rpc消息', 23);
insert into broker_config_group(`id`, `group`, `order`) values(24, '其他配置', 24);
insert into broker_config_group(`id`, `group`, `order`) values(25, 'controller配置', 25);
insert into broker_config_group(`id`, `group`, `order`) values(26, '压缩topic配置', 26);
insert into broker_config_group(`id`, `group`, `order`) values(27, '时间轮延迟消息', 27);
insert into broker_config_group(`id`, `group`, `order`) values(28, '备代主模式', 28);
-- ----------------------------
-- `broker_config` record
-- ----------------------------
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'brokerName', null, 'broker名', null, 1, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'rocketmqHome', null, 'broker安装目录', '启动脚本中已经设置,无需再设置', 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'brokerRole', 'ASYNC_MASTER', 'broker角色', null, 3, 0, 'ASYNC_MASTER:异步复制master;SYNC_MASTER:同步双写master;SLAVE:slave;', 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'flushDiskType', 'ASYNC_FLUSH', '刷盘机制', null, 4, 0, 'ASYNC_FLUSH:异步刷盘;SYNC_FLUSH:同步刷盘;', 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'brokerIP1', null, 'broker的ip', '服务器ip,尤其对于多网卡情况', 5, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'brokerIP2', null, 'master HA ip', '与brokerIP1一致', 6, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'listenPort', '10911', 'broker监听端口', null, 7, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'brokerClusterName', null, '集群名', null, 8, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'brokerId', '0', '0:master,非0:slave', null, 9, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'brokerPermission', '6', 'broker权限', 'broker下线可以设置为只读', 10, 1, '2:只写;4:只读;6:读写', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'storePathRootDir', null, '数据文件存储根目录', '务必设置', 11, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'storePathCommitLog', null, 'CommitLog文件存储根目录', '务必设置', 12, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) VALUES (1, 'physicalMemorySize', '0', '物理内存(单位字节)，0代表使用全部物理内存', '部署到docker或多个broker部署到一台机器时使用', 18, 1, NULL, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'grpcServerPort', '8081', 'proxy grpc协议端口', null, 19, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(1, 'remotingListenPort', '8080', 'proxy remoting协议端口', null, 20, 0, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(2, 'namesrvAddr', null, 'namesrv地址', '若采用域名寻址模式无需设置', 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(2, 'fetchNamesrvAddrByAddressServer', 'true', '域名方式获取NameServer地址', '若配置namesrvAddr无需设置此项', 2, 0, 'true:是;false:否;', 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(2, 'rmqAddressServerDomain', null, 'NameServer地址域名', null, 3, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(2, 'rmqAddressServerSubGroup', null, 'NameServer地址域名子路径', null, 4, 0, null, 1);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(3, 'autoCreateTopicEnable', 'true', '发送消息时没有topic自动创建', '线上建议设置为false', 1, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(3, 'autoCreateSubscriptionGroup', 'true', '自动创建订阅组', '线上建议设置为false', 2, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(3, 'defaultTopicQueueNums', '8', 'autoCreateTopicEnable为true时,创建topic的队列数', '无需修改', 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(3, 'clusterTopicEnable', 'true', '自动创建以cluster为名字的topic', null, 4, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(3, 'brokerTopicEnable', 'true', '自动创建以broker为名字的topic', null, 5, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(3, 'traceTopicEnable', 'false', '是否启用trace topic', null, 6, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(3, 'msgTraceTopicName', 'RMQ_SYS_TRACE_TOPIC', '默认的trace topic名', null, 7, 0, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(4, 'useReentrantLockWhenPutMessage', 'false', '写消息是否使用重入锁', '若不使用建议配合transientStorePool使用；若使用要加大sendMessageThreadPoolNums', 1, 0, 'true:是;false:否;', 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(4, 'sendMessageThreadPoolNums', '1', '处理发消息的线程池大小', '默认使用spin锁', 2, 0, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(4, 'waitTimeMillsInSendQueue', '200', '消息发送请求超过阈值没有处理则返回失败', '若出现broker busy建议调大', 3, 1, null, 1);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(4, 'sendMsgRateLimitQps', '10000', '发送消息限流qps', null, 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(4, 'sendRetryMsgRateLimitQps', '1000', '发送重试消息限流qps', null, 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(4, 'enableRateLimit', 'true', '是否启用发送消息限流', null, 6, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'sendThreadPoolQueueCapacity', '10000', '处理发消息的线程池队列大小', null, 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'pullMessageThreadPoolNums', '16+核数*2', '处理拉消息的线程池大小', null, 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'pullThreadPoolQueueCapacity', '100000', '处理拉消息的线程池队列大小', null, 4, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'queryMessageThreadPoolNums', '8+核数', '处理消息查询的线程池大小', null, 5, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'queryThreadPoolQueueCapacity', '20000', '处理消息查询的线程池队列大小', null, 6, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'adminBrokerThreadPoolNums', '16', '处理admin请求的线程池大小', null, 7, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'clientManageThreadPoolNums', '32', '处理客户端(解注册等)的线程池大小', null, 8, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'clientManagerThreadPoolQueueCapacity', '1000000', '处理客户端(解注册等)的线程池队列大小', null, 9, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'consumerManageThreadPoolNums', '32', '处理消费者请求的线程池大小', null, 10, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'consumerManagerThreadPoolQueueCapacity', '1000000', '处理消费者请求的线程池队列大小', null, 11, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'heartbeatThreadPoolNums', 'min(32, 核数)', '处理客户端心跳的线程池大小', null, 12, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'heartbeatThreadPoolQueueCapacity', '50000', '处理客户端心跳的线程池队列大小', null, 13, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'endTransactionThreadPoolNums', '8+核数*2', '处理结束事务请求的线程池大小', null, 14, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(5, 'endTransactionPoolQueueCapacity', '100000', '处理结束事务请求的线程池队列大小', null, 15, 0, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(6, 'warmMapedFileEnable', 'false', 'mmap时进行是否进行内存预热，避免缺页异常', null, 1, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(6, 'flushLeastPagesWhenWarmMapedFile', '4096', '预热时同时刷多少页内存(同步刷盘时)', null, 2, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(7, 'mappedFileSizeCommitLog', '1073741824', 'CommitLog文件大小', '默认大小1G，如非必要请勿修改', 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(7, 'flushIntervalCommitLog', '500', '异步刷盘时间间隔', '单位ms', 2, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(7, 'flushCommitLogTimed', 'true', '是否定时刷CommitLog，若否会实时刷', null, 3, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(7, 'flushCommitLogLeastPages', '4', '最少凑够多少页内存才刷CommitLog', null, 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(7, 'flushCommitLogThoroughInterval', '10000', '两次刷CommitLog最大间隔，若超过，不校验页数直接刷', '单位ms,默认10秒', 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(7, 'syncFlushTimeout', '5000', '同步刷CommitLog超时时间', '单位ms,默认5秒', 6, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(8, 'mappedFileSizeConsumeQueue', '6000000', 'ConsumeQueue文件存储的条目', '默认为30万，如非必要请勿修改', 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(8, 'flushIntervalConsumeQueue', '1000', '异步刷ConsumeQueue时间间隔', '单位ms,默认1秒', 2, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(8, 'flushConsumeQueueLeastPages', '2', '最少凑够多少页内存才刷ConsumeQueue', null, 3, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(8, 'flushConsumeQueueThoroughInterval', '60000', '两次刷ConsumeQueue最大间隔，若超过，不校验页数直接刷', '单位ms,默认1分钟', 4, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(9, 'transientStorePoolEnable', 'false', '是否启动堆外内存池加速写', null, 1, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(9, 'transientStorePoolSize', '5', '堆外内存池大小', null, 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(9, 'fastFailIfNoBufferInStorePool', 'false', '是否启用快速失败', null, 3, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(9, 'commitIntervalCommitLog', '200', '异步刷堆外内存时间间隔', '单位ms', 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(9, 'commitCommitLogLeastPages', '4', '最少凑够多少页内存才刷堆外内存', null, 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(9, 'commitCommitLogThoroughInterval', '200', '两次刷堆外内存最大间隔，若超过，不校验页数直接刷', '单位ms', 6, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(10, 'haListenPort', '10912', 'master监听的HA端口', null, 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(10, 'haHousekeepingInterval', '20000', 'master与slave链接超时间隔', '单位ms,默认20秒', 2, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(10, 'haTransferBatchSize', '32768', 'master批量传输给slave数据大小', '单位字节,默认32K', 3, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(10, 'haSlaveFallbehindMax', '268435456', '同步双写master，判断slave落后大于多少为不可用', '单位字节,默认256M', 4, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'fileReservedTime', '72', 'CommitLog保留的时间', '单位小时,默认3天', 1, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'deleteWhen', '04', 'CommitLog删除时间点，多个用;分隔', null, 2, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'destroyMapedFileIntervalForcibly', '120000', '删除文件时，若文件被占用，等待多久后强制删除', '单位ms,默认2分钟', 3, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'cleanFileForciblyEnable', 'true', '磁盘超过阈值、且无过期文件情况下, 是否强制删除文件', null, 4, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'diskMaxUsedSpaceRatio', '75', '磁盘最大使用阈值', null, 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'deleteCommitLogFilesInterval', '100', '删除CommitLog间隔，中间将sleep', '单位ms', 6, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'deleteConsumeQueueFilesInterval', '100', '删除ConsumeQueue间隔，中间将sleep', '单位ms', 7, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(11, 'redeleteHangedFileInterval', '120000', '重新删除已经执行过删除却未删掉的文件间隔', '单位ms,默认2分钟', 8, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(12, 'maxMessageSize', '4194304', '单条消息最大大小', '单位字节,默认4M', 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(12, 'messageIndexEnable', 'true', '消息是否开启索引', null, 2, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(12, 'messageIndexSafe', 'false', '消息索引恢复时是否安全校验', null, 3, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(12, 'maxHashSlotNum', '5000000', '单个消息文件hash槽个数', '默认5百万', 4, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(12, 'maxIndexNum', '20000000', '单个消息文件hash槽个数', '默认2千万', 5, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(12, 'messageDelayLevel', '1s 5s 10s 30s 1m 2m 3m 4m 5m 6m 7m 8m 9m 10m 20m 30m 1h 2h', '延迟消息队列', null, 6, 0, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(13, 'slaveReadEnable', 'false', '拉取消息在硬盘时是否可以从slave拉取', '设置为true分担master压力', 1, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(13, 'longPollingEnable', 'true', '针对消费拉消息是否开启长轮询', null, 2, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(13, 'shortPollingTimeMills', '1000', '针对消费拉消息短轮询时间', '单位ms,默认1秒', 3, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(13, 'notifyConsumerIdsChangedEnable', 'true', '消费者上下线时是否通知客户端,以便再平衡', null, 4, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(13, 'transferMsgByHeap', 'true', '传输数据时是否使用零拷贝', '若消息量不大,基本都在pagecache,建议为false.否则消息在硬盘使用零拷贝会卡netty线程', 5, 1, 'true:是;false:否;', 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(14, 'accessMessageInMemoryMaxRatio', '40', '判断消息是否在内存的依据，此值仅为预估值，不准确', null, 1, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(14, 'maxTransferBytesOnMessageInMemory', '262144', '单次拉取内存消息传输的最大字节', '单位字节,默认256K', 2, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(14, 'maxTransferCountOnMessageInMemory', '32', '单次拉取内存消息传输的最大数量', null, 3, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(14, 'maxTransferBytesOnMessageInDisk', '65536', '单次拉取硬盘消息传输的最大字节', '单位字节,默认64K', 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(14, 'maxTransferCountOnMessageInDisk', '8', '单次拉取硬盘消息传输的最大数量', null, 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(14, 'maxMsgsNumBatch', '64', '按照key查询一次返回多少条消息（主要用于admin工具查询）', null, 6, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(14, 'defaultQueryMaxNum', '32', '按照msgId查询一次返回多少条消息（主要用于admin工具查询）', null, 7, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(15, 'osPageCacheBusyTimeOutMills', '1000', '消息存储超过此时间，则将丢弃所有的写入请求', '单位ms,默认1秒', 1, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(15, 'brokerFastFailureEnable', 'true', '是否启用快速失败机制', null, 2, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(15, 'waitTimeMillsInPullQueue', '5000', '消息拉取请求超过阈值没有处理则返回失败', '单位ms,默认5秒', 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(15, 'waitTimeMillsInHeartbeatQueue', '31000', 'client心跳请求超过阈值没有处理则返回失败', '单位ms,默认31秒', 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(15, 'waitTimeMillsInTransactionQueue', '3000', '事务结束请求超过阈值没有处理则返回失败', '单位ms,默认3秒', 6, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(16, 'startAcceptSendRequestTimeStamp', '0', 'broker启动多久后可以接受请求', '单位ms,默认0ms', 1, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(16, 'disableConsumeIfConsumerReadSlowly', 'false', '是否禁用消费慢的消费者', '启用slaveReadEnable代替此功能', 2, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(16, 'consumerFallbehindThreshold', '17179869184', '消费者拉取消息大小超过此值认为消费慢', '单位字节,默认16G', 3, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(16, 'diskFallRecorded', 'true', '记录消费者拉取消息大小', '不启用disableConsumeIfConsumerReadSlowly可以选否', 4, 1, 'true:是;false:否;', 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(17, 'compressedRegister', 'false', '向NameServer注册时数据是否压缩', 'topic过多可以开启', 1, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(17, 'forceRegister', 'true', '向NameServer注册时是否强制每次发送数据', 'topic过多可以关闭', 2, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(17, 'registerNameServerPeriod', '30000', '向NameServer注册周期', '单位ms,默认30秒', 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(17, 'registerBrokerTimeoutMills', '24000', '向NameServer注册时超时时间', '单位ms,默认24秒', 4, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(18, 'rejectTransactionMessage', 'false', '是否拒绝发送事务消息', '非事务集群设置为true', 1, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(18, 'transactionTimeOut', '6000', '事务消息超过多久后首次检查', '单位ms,默认6秒', 2, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(18, 'transactionCheckMax', '15', '事务消息最大检查次数', null, 3, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(18, 'transactionCheckInterval', '30000', '事务消息检查间隔', '单位ms,默认30秒', 4, 1, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(19, 'haSendHeartbeatInterval', '5000', 'slave与master心跳间隔', '单位ms,默认5秒', 1, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(19, 'haMasterAddress', null, 'slave的HA master', '无需设置,向NameServer注册会返回master地址作为HA地址', 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(19, 'offsetCheckInSlave', 'false', '消费者从slave拉取消息offset不正确时，slave是否检查更正', null, 2, 1, 'true:是;false:否;', 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'filterServerNums', '0', '过滤服务数', null, 1, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'enableCalcFilterBitMap', 'false', '是否启用BitMap过滤计算', null, 2, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'bitMapLengthConsumeQueueExt', '112', 'BitMap大小', null, 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'expectConsumerNumUseFilter', '32', '预估的订阅同一topic的消费者数', null, 4, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'maxErrorRateOfBloomFilter', '20', 'bloom filter错误率', '单位%,默认20%', 5, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'filterDataCleanTimeSpan', '86400000', '清理n小时之前的filter数据', '单位ms,默认24小时', 6, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'enableConsumeQueueExt', 'false', '是否生成额外的consume queue文件', null, 7, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'mappedFileSizeConsumeQueueExt', '50331648', '额外的consume queue文件大小', '单位字节,默认48M', 8, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'filterSupportRetry', 'false', '是否支持过滤retry消费者', null, 9, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(20, 'enablePropertyFilter', 'false', '是否支持过滤SQL92', null, 10, 1, 'true:是;false:否;', 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverWorkerThreads', '8', 'worker线程', null, 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverCallbackExecutorThreads', '0', '默认公共线程', null, 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverSelectorThreads', '3', 'selector线程', null, 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverOnewaySemaphoreValue', '256', 'oneway信号量', null, 4, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverAsyncSemaphoreValue', '64', 'aysnc信号量', null, 5, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverChannelMaxIdleTimeSeconds', '120', 'idle最大时间', null, 6, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverSocketSndBufSize', '0', 'SO_SNDBUF', null, 7, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverSocketRcvBufSize', '0', 'SO_RCVBUF', null, 8, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'serverPooledByteBufAllocatorEnable', 'true', '是否开启bytebuffer池', null, 9, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(21, 'useEpollNativeSelector', 'false', '是否使用epoll', null, 10, 0, 'true:是;false:否;', 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientWorkerThreads', '4', 'worker线程', null, 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientCallbackExecutorThreads', '核数', '默认公共线程', null, 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientOnewaySemaphoreValue', '65535', 'oneway信号量', null, 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientAsyncSemaphoreValue', '65535', 'aysnc信号量', null, 4, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'channelNotActiveInterval', '60000', '此项作废', null, 5, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientChannelMaxIdleTimeSeconds', '120', '链接最大idle时间', null, 6, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'connectTimeoutMillis', '3000', '连接超时时间', null, 7, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientSocketSndBufSize', '0', 'SO_SNDBUF', null, 8, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientSocketRcvBufSize', '0', 'SO_RCVBUF', null, 9, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientPooledByteBufAllocatorEnable', 'false', '是否开启bytebuffer池', null, 10, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'clientCloseSocketIfTimeout', 'true', '超时是否关闭连接', null, 11, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(22, 'useTLS', 'false', '是否使用ssl', null, 12, 0, 'true:是;false:否;', 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(23, 'storeReplyMessageEnable', 'true', '是否启用rpc消息', null, 1, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(23, 'processReplyMessageThreadPoolNums', '16+核数*2', '处理rpc消息线程池大小', null, 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(23, 'replyThreadPoolQueueCapacity', '10000', '处理rpc消息的线程池队列大小', null, 3, 0, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'traceOn', 'true', '是否启用trace', null, 1, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'aclEnable', 'false', '是否启用权限校验,若启用需要配置权限文件', null, 2, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'messageStorePlugIn', null, '消息存储插件', null, 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'checkCRCOnRecover', 'true', 'load完消息校验消息是否用CRC32', null, 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'debugLockEnable', 'false', 'commitlog写入超过1秒打印堆栈', null, 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'cleanResourceInterval', '10000', 'CommitLog&ConsumeQueue清除任务执行间隔', '单位ms,默认10秒', 6, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'flushConsumerOffsetInterval', '5000', 'consumerOffset.json持久化间隔', '单位ms,默认5秒', 7, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'flushConsumerOffsetHistoryInterval', '60000', '此项作废,以flushConsumerOffsetInterval为准', null, 8, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'flushDelayOffsetInterval', '10000', 'delayOffset.json持久化间隔', '单位ms,默认10秒', 9, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'abortFile', null, '自动以storePathRootDir拼装', '无需设置', 10, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'storePathIndex', null, '自动以storePathRootDir拼装', '无需设置', 11, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'storeCheckpoint', null, '自动以storePathRootDir拼装', '无需设置', 12, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'highSpeedMode', 'false', '此项作废', null, 14, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'commercialEnable', 'true', '此项作废', null, 15, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'commercialTimerCount', '1', '此项作废', null, 16, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'commercialTransCount', '1', '此项作废', null, 17, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'commercialBigCount', '1', '此项作废', null, 18, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'commercialBaseCount', '1', '此项作废', null, 19, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'putMsgIndexHightWater', '600000', '此项作废', null, 20, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'maxDelayTime', '40', '此项作废', null, 21, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'regionId', 'DefaultRegion', 'broker区域，trace使用', null, 22, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'duplicationEnable', 'false', '是否支持重写consume queue', null, 23, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'enableDLegerCommitLog', 'false', '是否支持DLeger', null, 24, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'dLegerGroup', null, 'DLeger相关配置', null, 25, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'dLegerPeers', null, 'DLeger相关配置', null, 26, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'dLegerSelfId', null, 'DLeger相关配置', null, 27, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'enableScheduleMessageStats', 'true', '开启schedule队列消息统计', null, 28, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'isEnableBatchPush', 'false', 'DLedger批量复制', null, 29, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'autoDeleteUnusedStats', 'false', '删除topic或订阅时一起删除相关统计', null, 30, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'registerBroker', 'true', '是否注册broker', null, 31, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricsExporterType', 'DISABLE', '指标输出类型', null, 32, 0, 'DISABLE:DISABLE;OTLP_GRPC:OTLP_GRPC;PROM:PROM;LOG:LOG;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricsGrpcExporterTarget', null, 'OTLP_GRPC输出地址', null, 33, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricsGrpcExporterHeader', null, 'OTLP_GRPC输出header', null, 34, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricGrpcExporterTimeOutInMills', '3000', 'OTLP_GRPC输出超时时间', '默认3秒，单位ms', 35, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricGrpcExporterIntervalInMills', '60000', 'OTLP_GRPC输出间隔', '默认一分钟，单位ms', 36, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricLoggingExporterIntervalInMills', '10000', '指标日志输出间隔', '默认10秒，单位ms', 37, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricsPromExporterPort', '5557', 'PROM指标输出端口', null, 38, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricsPromExporterHost', null, 'PROM指标输出ip', null, 39, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'metricsLabel', null, '指标标签', '格式:name1:label1,name2:label2', 40, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(24, 'validateSystemTopicWhenUpdateTopic', 'false', '新建topic是否校验是不是系统topic', null, 41, 1, null, 1);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'enableControllerMode', 'false', '是否启用controller模式', null, 1, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'controllerAddr', null, 'controller的地址', 'ip:port;ip:port;或域名:port', 2, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'fetchControllerAddrByDnsLookup', 'false', '是否使用域名获取controller的地址', 'controllerAddr填写域名时请启用该选项', 3, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'controllerHeartBeatTimeoutMills', '10000', 'broker和controller之间心跳超时时间', '单位ms,默认10秒', 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'syncBrokerMetadataPeriod', '5000', '向controller同步broker副本信息的时间间隔', '单位ms,默认5秒', 5, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'checkSyncStateSetPeriod', '5000', '检查SyncStateSet的时间间隔', '单位ms,默认5秒', 6, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'syncControllerMetadataPeriod', '10000', '同步controller元数据的时间间隔，主要是获取active controller的地址', '单位ms,默认10秒', 7, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'haMaxTimeSlaveNotCatchup', '15000', 'slave没有跟上Master的最大时间间隔，若在SyncStateSet中的slave超过该时间间隔会将其从SyncStateSet移除', '单位ms,默认15秒', 8, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'storePathEpochFile', null, '存储epoch文件的位置', '默认在store目录下', 9, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'allAckInSyncStateSet', 'false', '一条消息需要复制到SyncStateSet中的每一个副本才会向客户端返回成功，可以保证消息不丢失', null, 10, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'syncFromLastFile', 'false', '若slave是空盘启动，是否从最后一个文件进行复制', null, 11, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'asyncLearner', 'false', '异步复制的learner', '为true时不参与选举', 12, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'inSyncReplicas', '1', '需保持同步的副本组数量', 'allAckInSyncStateSet=true时该参数无效', 13, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(25, 'minInSyncReplicas', '1', '最小需保持同步的副本组数量', '若SyncStateSet中副本个数小于minInSyncReplicas则putMessage直接返回PutMessageStatus.IN_SYNC_REPLICAS_NOT_ENOUGH', 14, 0, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(26, 'compactionMappedFileSize', '104857600', 'CompactinLog文件大小', '默认100m', 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(26, 'compactionThreadNum', '6', '压缩线程数', null, 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(26, 'compactionScheduleInternal', '900000', '压缩间隔', null, 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(26, 'compactionCqMappedFileSize', '10485760', 'CompactinConsumeQueue文件大小', '默认10m', 4, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(26, 'enableCompaction', 'true', '是否启用压缩', null, 5, 0, 'true:是;false:否;', 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'mappedFileSizeTimerLog', '104857600', 'TimerLog文件大小', '默认100m', 1, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerPrecisionMs', '1000', '时间轮精度', '单位毫秒', 2, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerRollWindowSlot', '172800', '超长延迟消息滚动窗口', '默认超过2天会滚动，单位ms', 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerFlushIntervalMs', '1000', '延迟消息刷新间隔', '默认1秒，单位ms', 4, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerGetMessageThreadNum', '3', '出dequeueGetQueue从commitLog拉取消息，放入dequeuePutQueue的线程数', null, 5, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerPutMessageThreadNum', '3', '出dequeuePutQueue放入原始队列线程数', null, 6, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerEnableDisruptor', 'false', '是否使用Disruptor', null, 7, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerEnableCheckMetrics', 'true', '是否检查指标', null, 8, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerCheckMetricsWhen', '05', '指标检查时间', null, 9, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerMaxDelaySec', '259200', '延迟消息最大延迟', '默认3天，单位s', 10, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerWheelEnable', 'true', '是否启用时间轮延迟消息', null, 11, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerStopEnqueue', 'false', '是否停止写入enqueuePutQueue', null, 12, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerStopDequeue', 'false', '是否停止写入dequeueGetQueue', null, 13, 1, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerSkipUnknownError', 'false', '发生未知错误时是否跳过', null, 14, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerCongestNumEachSlot', '2147483647', '每个槽最大消息量', null, 15, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerMetricSmallThreshold', '1000000', '指标小阈值', null, 16, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerProgressLogIntervalMs', '10000', '延迟消息处理日志打印间隔', '默认10秒，单位ms', 17, 1, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerWarmEnable', 'false', '已废弃', null, 18, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(27, 'timerInterceptDelayLevel', 'false', '已废弃', null, 19, 0, null, 0);

insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'enableSlaveActingMaster', 'false', '是否启用备代主', null, 1, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'enableRemoteEscape', 'false', '是否允许二级消息远程逃逸', null, 2, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'totalReplicas', '1', 'broker副本总个数（包括master）', null, 3, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'brokerHeartbeatInterval', '1000', 'broker向ns发送的轻量心跳的时间间隔', '默认1秒，单位ms', 4, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'brokerNotActiveTimeoutMillis', '10000', '超时ns未收到心跳认为broker下线', '默认10秒，单位ms', 5, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'sendHeartbeatTimeoutMillis', '1000', 'broker向ns发送的轻量心跳的超时时间，单位毫秒', '默认1秒，单位ms', 6, 0, null, 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'skipPreOnline', 'false', 'master重启是否跳过预上线流程', '预上线流程用于master启动后先不注册到ns，从代理备同步元数据后再注册', 7, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'compatibleWithOldNameSrv', 'true', '是否兼容旧的ns', null, 8, 0, 'true:是;false:否;', 0);
insert into broker_config(`gid`, `key`, `value`, `desc`, `tip`, `order`, `dynamic_modify`, `option`, `required`) values(28, 'lockInStrictMode', 'false', 'lockInStrictMode', null, 9, 0, 'true:是;false:否;', 0);

-- ----------------------------
-- Table structure for `topic_traffic_warn_config`
-- ----------------------------
DROP TABLE IF EXISTS `topic_traffic_warn_config`;
CREATE TABLE `topic_traffic_warn_config` (
  `min_warn_count` bigint(20) DEFAULT NULL COMMENT '最小预警数量',
  `avg_multiplier` float(11,3) DEFAULT '5.000' COMMENT '平均流量值的乘数阈值;流量统计时，大于该值乘以平均流量值认定为异常值而被剔除',
  `avg_max_percentage_increase` float(11,3) DEFAULT '200.000' COMMENT '30天内每天流量最大值的平均值的百分比阈值；某时刻流量值大于最大值的平均值的增长阈值，则预警',
  `max_max_percentage_increase` float(11,3) DEFAULT '30.000' COMMENT '30天内流量最大值的增幅百分比阈值；某时刻流量值若大于最大值的该增幅阈值，则预警',
  `alarm_receiver` int(4) DEFAULT '0' COMMENT '告警接收人,0:生产者消费者及管理员,1:生产者和管理员,2:消费者和管理员,3:仅管理员,4:不告警',
  `topic` varchar(64) DEFAULT '' COMMENT 'topic名称，为空代表默认配置，只有一条默认配置',
  UNIQUE KEY `topic` (`topic`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='topic流量突增预警阈值配置';

-- ----------------------------
-- topic_traffic_warn_config init
-- ----------------------------
INSERT INTO `topic_traffic_warn_config`(avg_multiplier,avg_max_percentage_increase,max_max_percentage_increase,alarm_receiver,min_warn_count) VALUES (5, 200, 30, 0, 100);

-- ----------------------------
-- Table structure for `audit_topic_traffic_warn`
-- ----------------------------
CREATE TABLE `audit_topic_traffic_warn` (
  `aid` int(11) NOT NULL COMMENT '审核id',
  `tid` int(11) NOT NULL COMMENT 'topic id',
  `traffic_warn_enabled` int(11) NOT NULL COMMENT '0:不开启topic流量突增预警,1:开启topic流量突增预警'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核topic trafficWarn相关表';

-- ----------------------------
-- Table structure for `user_warn`
-- ----------------------------
DROP TABLE IF EXISTS `user_warn`;
CREATE TABLE `user_warn` (
  `uid` int(11) NOT NULL,
  `type` int(4) NOT NULL COMMENT '警告类型',
  `resource` varchar(100) DEFAULT NULL COMMENT '警告资源:topic,producer等',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `wid` int(11) NOT NULL,
  KEY `ut` (`uid`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户警告表';

-- ----------------------------
-- Table structure for `warn_info`
-- ----------------------------
DROP TABLE IF EXISTS `warn_info`;
CREATE TABLE `warn_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `content` text DEFAULT NULL COMMENT '警告内容',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='警告信息表';

-- ----------------------------
-- Table structure for `user_group`
-- ----------------------------
DROP TABLE IF EXISTS `user_group`;
CREATE TABLE `user_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'group id',
  `name` varchar(64) NOT NULL COMMENT 'name',
  `create_date` date NOT NULL,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户组';

-- ----------------------------
-- Table structure for `user_footprint`
-- ----------------------------
DROP TABLE IF EXISTS `user_footprint`;
CREATE TABLE `user_footprint` (
    `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `uid` int(11) NOT NULL COMMENT 'user id',
    `tid` int(11) NOT NULL COMMENT 'topic id',
    `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `ft_utid` (`uid`, `tid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户轨迹';

-- ----------------------------
-- Table structure for `user_favorite`
-- ----------------------------
DROP TABLE IF EXISTS `user_favorite`;
CREATE TABLE `user_favorite` (
    `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `uid` int(11) NOT NULL COMMENT 'user id',
    `tid` int(11) NOT NULL COMMENT 'topic id',
    `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `fa_utid` (`uid`, `tid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户收藏';

-- ----------------------------
-- Table structure for `client_language`
-- ----------------------------
DROP TABLE IF EXISTS `client_language`;
CREATE TABLE `client_language` (
    `cid` int(11) NOT NULL COMMENT 'cluster id',
    `tid` int(11) NOT NULL COMMENT 'topic id',
    `client_group_name` varchar(255) NOT NULL COMMENT '生产者/消费者名称',
    `client_group_type` tinyint(4) NOT NULL COMMENT '类型 0 生产者 1 消费者',
    `language` tinyint(4) DEFAULT NULL COMMENT '客户端语言',
    `version` varchar(50) DEFAULT NULL COMMENT '版本',
    `relation_uids` varchar(255) DEFAULT NULL COMMENT '关联人员id集合，逗号分隔',
    `modify_type` int(4) NOT NULL DEFAULT '0' COMMENT '修改方式 0 自动 1 手动',
    `create_date` date NOT NULL COMMENT '创建时间',
    `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY `union_key` (`cid`,`tid`,`client_group_name`),
    KEY `nomal_query_index` (`client_group_name`,`client_group_type`,`language`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户端语言';

-- ----------------------------
-- Table structure for `controller`
-- ----------------------------
DROP TABLE IF EXISTS `controller`;
CREATE TABLE `controller` (
    `cid`          int(11) NOT NULL COMMENT '集群id',
    `addr`         varchar(255) NOT NULL COMMENT 'controller 地址',
    `create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `check_status` tinyint(4) DEFAULT 0 COMMENT '检测结果:0:未知,1:正常,2:异常',
    `check_time`   datetime COMMENT '检测时间',
    `base_dir`     varchar(360) DEFAULT '/opt/mqcloud/controller' COMMENT '安装路径',
    UNIQUE KEY `cid` (`cid`, `addr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='controller表';


-- ----------------------------
-- Table structure for `proxy`
-- ----------------------------
DROP TABLE IF EXISTS `proxy`;
CREATE TABLE `proxy` (
    `cid`          int(11) NOT NULL COMMENT '集群id',
    `addr`         varchar(255) NOT NULL COMMENT 'proxy grpc 地址',
    `create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `status`       tinyint(4) default 0 comment '状态:0:正常,1:流量剔除',
    `check_status` tinyint(4) DEFAULT 0 COMMENT '检测结果:0:未知,1:正常,2:异常',
    `check_time`   datetime COMMENT '检测时间',
    `base_dir`     varchar(360) DEFAULT '/opt/mqcloud/proxy' COMMENT '安装路径',
    `config`       text COMMENT '配置',
    UNIQUE KEY `cid` (`cid`, `addr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='proxy表';

DROP TABLE IF EXISTS `audit_wheel_message_cancel`;
create table `audit_wheel_message_cancel`
(
    `id`          int(11)       not null AUTO_INCREMENT,
    `uid`         int(11)       not null COMMENT '申请用户ID',
    `aid`         int(11)       not null COMMENT '审核记录ID',
    `tid`         int(11)       not null COMMENT 'topic ID',
    `uniqueId`    varchar(50)   not null COMMENT '待取消消息uniqId',
    `brokerName`  varchar(50)   not null COMMENT '待取消消息所在的brokerName',
    `deliverTime` bigint        not null COMMENT '定时时间',
    `status`      tinyint(4)    default 0 comment '状态 0失败 1成功 ',
    `createTime`  datetime      null,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='时间轮定时消息取消表';

DROP TABLE IF EXISTS `cancel_uniqid`;
create table `cancel_uniqid`
(
    `tid`        int(11)     not null COMMENT 'topic id',
    `uniqueId`   varchar(50) not null COMMENT '取消消息uniqueId',
    `createTime` datetime    not null COMMENT '生成时间',
    UNIQUE KEY  uniqIndex (uniqueId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='取消ID记录';


-- ----------------------------
-- Table structure for `audit_timespan_message_export`
-- ----------------------------
DROP TABLE IF EXISTS `audit_timespan_message_export`;
CREATE TABLE `audit_timespan_message_export` (
    `aid` int(11) NOT NULL COMMENT '审核id',
    `topic` varchar(64) NOT NULL COMMENT 'topic',
    `start` bigint(20) DEFAULT NULL COMMENT '消费开始时间戳',
    `end` bigint(20) DEFAULT NULL COMMENT '消费结束时间戳'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='时间段消息导出审核表';

-- ----------------------------
-- Table structure for `message_export`
-- ----------------------------
DROP TABLE IF EXISTS `message_export`;
CREATE TABLE `message_export`
(
    `aid`   int(11) NOT NULL COMMENT '审核id',
    `ip` varchar(255) NOT NULL COMMENT '执行导出的机器ip',
    `total_msg_count` bigint(20) COMMENT '总消息量',
    `exported_msg_count` bigint(20) COMMENT '导出的消息量',
    `left_time` bigint(20) COMMENT '剩余时间',
    `export_cost_time` bigint(20) COMMENT '导出用时',
    `compress_cost_time` bigint(20) COMMENT '压缩用时',
    `scp_cost_time` bigint(20) COMMENT 'scp用时',
    `exported_file_path` varchar(255) COMMENT '导出文件路径',
    `info` text COMMENT '任务执行的信息',
    `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    primary key (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='消息导出记录表';

-- ----------------------------
-- Table structure for `consumer_client_metrics`
-- ----------------------------
DROP TABLE IF EXISTS `consumer_client_metrics`;
CREATE TABLE `consumer_client_metrics`
(
    `id`          int(11) NOT NULL AUTO_INCREMENT,
    `consumer`    varchar(64)  NOT NULL COMMENT 'consumer',
    `client`      varchar(100) NOT NULL COMMENT 'client',
    `max`         int(11) NOT NULL COMMENT '最大耗时',
    `avg`         double       NOT NULL COMMENT '平均耗时',
    `count`       int(11) NOT NULL COMMENT '调用次数',
    `exception`   text COMMENT '异常记录',
    `create_date` int(11) NOT NULL COMMENT '创建日期',
    `create_time` char(4)      NOT NULL COMMENT '创建分钟,格式:HHMM',
    `stat_time`   int(11) NOT NULL COMMENT '统计时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `s_s_c` (`consumer`,`stat_time`,`client`),
    KEY           `create_date` (`create_date`,`consumer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='消费者客户端统计';

-- ----------------------------
-- Table structure for `data_migration`
-- ----------------------------
DROP TABLE IF EXISTS `data_migration`;
CREATE TABLE `data_migration`
(
    `id`          int(11) NOT NULL AUTO_INCREMENT,
    `source_ip`     varchar(255) NOT NULL COMMENT '源ip',
    `source_path`   varchar(255) NOT NULL COMMENT '源路径',
    `dest_ip`       varchar(255) NOT NULL COMMENT '目标ip',
    `dest_path`     varchar(255) NOT NULL COMMENT '目标路径',
    `data_count`  bigint(20) NOT NULL COMMENT '数据量',
    `cost_time`   bigint(20) DEFAULT '0' COMMENT '耗时',
    `create_time` timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `status`      tinyint(4) NOT NULL DEFAULT '0' COMMENT '0:未开始,1:进行中,2:完成',
    `info`        text COMMENT '执行的信息',
    primary key (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='数据迁移表';

-- ----------------------------
-- Table structure for `broker_tmp`
-- ----------------------------
DROP TABLE IF EXISTS `broker_tmp`;
CREATE TABLE `broker_tmp`
(
    `cid`         int(11) NOT NULL COMMENT '集群id',
    `addr`        varchar(255) NOT NULL COMMENT 'broker 地址',
    `broker_name` varchar(64)  NOT NULL COMMENT 'broker名字',
    `broker_id`   int(4) NOT NULL COMMENT 'broker ID，0-master，1-slave',
    `create_time` timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `base_dir`    varchar(360)          DEFAULT NULL COMMENT '安装路径',
    UNIQUE KEY `cid` (`cid`,`addr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='broker临时表';

-- ----------------------------
-- Table structure for `audit_http_consumer_config`
-- ----------------------------
DROP TABLE IF EXISTS `audit_http_consumer_config`;
CREATE TABLE `audit_http_consumer_config`
(
    `aid`             int(11) NOT NULL COMMENT '审核id',
    `consumer_id`     int(11) NOT NULL COMMENT 'consumer id',
    `pull_size`       int(11) DEFAULT NULL COMMENT '拉取消息量',
    `pull_timeout`    int(11) DEFAULT NULL COMMENT '拉取超时时间，单位毫秒',
    `consume_timeout` int(11) DEFAULT NULL COMMENT '消费超时时间，单位毫秒',
    PRIMARY KEY (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='审核HTTP消费者配置相关表';

-- ----------------------------
-- Table structure for `topic_warn_config`
-- ----------------------------
DROP TABLE IF EXISTS `topic_warn_config`;
CREATE TABLE `topic_warn_config`
(
    `id`            int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `tid`           int(11) NOT NULL COMMENT 'topic id',
    `operand_type`  tinyint(4) DEFAULT 0 COMMENT '操作类型，0:5分钟生产条数;1:一小时生产条数;2:一天生产条数;3:5分钟环比;4:时环比;5:日环比',
    `operator_type` tinyint(4) DEFAULT 0 COMMENT '比较符类型，0:大于;1:小于;2:大于等于;3:小于等于',
    `threshold`     double DEFAULT 0 COMMENT '阈值',
    `warn_interval` int(11) DEFAULT 0 COMMENT '报警间隔，单位分钟',
    `warn_time`     varchar(64) COMMENT '预警时间，格式：HH:mm-HH:mm',
    `enabled`       int(4) NOT NULL DEFAULT '1' COMMENT '0:未启用,1:启用',
    PRIMARY KEY (`id`),
    KEY `tid_idx` (`tid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='topic报警阈值配置表';

-- ----------------------------
-- Table structure for `broker_auto_update`
-- ----------------------------
DROP TABLE IF EXISTS `broker_auto_update`;
CREATE TABLE `broker_auto_update`
(
    `id`          int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `cid`         int(11) NOT NULL COMMENT 'cluster id',
    `status`      tinyint(4) NOT NULL DEFAULT '0' COMMENT '1:未开始,2:已就绪,3:进行中,4:暂停中,5:成功,6:失败,7:手动结束',
    `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `start_time`  timestamp NULL DEFAULT NULL COMMENT '开始时间',
    `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='broker自动更新表';

-- ----------------------------
-- Table structure for `broker_auto_update_step`
-- ----------------------------
DROP TABLE IF EXISTS `broker_auto_update_step`;
CREATE TABLE `broker_auto_update_step`
(
    `id`                    int(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
    `broker_auto_update_id` int(11) NOT NULL COMMENT 'broker_auto_update id',
    `broker_addr`           varchar(255) NOT NULL COMMENT 'broker 地址',
    `broker_name`           varchar(64)  NOT NULL COMMENT 'broker名字',
    `broker_id`             int(4) NOT NULL COMMENT 'broker ID，0-master，1-slave',
    `broker_base_dir`       varchar(360) NOT NULL COMMENT 'broker安装路径',
    `broker_version`        varchar(64)  NOT NULL COMMENT 'broker版本：4, 5',
    `order`                 int(11) NOT NULL COMMENT '操作顺序',
    `action`                tinyint(4) NOT NULL DEFAULT '0' COMMENT '0:停写,1:取消注册,2:关闭,3:备份数据,4:下载安装包,5:解压安装包,6:恢复数据,7:启动,8:注册,9:恢复写入',
    `status`                tinyint(4) NOT NULL DEFAULT '0' COMMENT '1:未开始,2:进行中,3:成功,4:失败,5:手动结束',
    `info`                  text COMMENT '操作信息',
    `start_time`            timestamp NULL DEFAULT NULL COMMENT '开始时间',
    `end_time`              timestamp NULL DEFAULT NULL COMMENT '结束时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='broker自动更新步骤表';