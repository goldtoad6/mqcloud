package com.sohu.tv.mq.cloud.task.server.data;

import java.util.*;
import java.util.regex.Pattern;

import com.sohu.tv.mq.cloud.common.util.WebUtil;
import org.apache.commons.lang3.math.NumberUtils;

import static com.sohu.tv.mq.cloud.task.server.nmon.NMONService.DISK_MQ_FLAG;

/**
 * io读写情况
 * 
 * @Description:
 * @author yongfeigao
 * @date 2018年7月18日
 */
public class Disk implements LineParser {
    public static final String FLAG = "DISK";
    public static final Pattern PATTERN = Pattern.compile("^BBBP,[0-9]+,/bin/df-m,");
    public static final Pattern SUBPARTITION_PATTERN = Pattern.compile("[0-9]+$");
    // 包括总的状况及各个分区的状况
    private Map<DiskUsageType, List<Usage>> diskMap = new HashMap<>();

    /**
     * line format: DISKBUSY,Disk %Busy iZ256oe4w5bZ,xvda,xvda1,xvdb,xvdb1
     * DISKREAD,Disk Read KB/s iZ256oe4w5bZ,xvda,xvda1,xvdb,xvdb1 DISKWRITE,Disk
     * Write KB/s iZ256oe4w5bZ,xvda,xvda1,xvdb,xvdb1 DISKXFER,Disk transfers per
     * second iZ256oe4w5bZ,xvda,xvda1,xvdb,xvdb1 DISKBSIZE,Disk Block Size
     * iZ256oe4w5bZ,xvda,xvda1,xvdb,xvdb1 DISKBUSY,T0001,0.0,0.0,0.0,0.0
     * DISKREAD,T0001,0.0,0.0,0.0,0.0 DISKWRITE,T0001,0.0,0.0,0.0,0.0
     * DISKXFER,T0001,0.0,0.0,0.0,0.0 DISKBSIZE,T0001,0.0,0.0,0.0,0.0
     * BBBP,173,/bin/df-m,"ddev/xvda1 20158 16018 3117 84% /"
     */
    public void parse(String line, String timeKey) throws Exception {
        if (line.startsWith(FLAG)) {
            String[] items = line.split(",");
            if (!items[1].equals(timeKey)) {
                DiskUsageType type = DiskUsageType.getType(items[0]);
                if (type == null) {
                    return;
                }
                List<Usage> list = diskMap.computeIfAbsent(type, k -> new ArrayList<>());
                for (int i = 2; i < items.length; ++i) {
                    Usage usage = new Usage();
                    usage.setDiskUsageTyp(type);
                    usage.setName(items[i]);
                    list.add(usage);
                }
            } else {
                DiskUsageType type = DiskUsageType.getType(items[0]);
                if (type == null) {
                    return;
                }
                List<Usage> list = diskMap.get(type);
                if (list == null) {
                    return;
                }
                for (int i = 2; i < items.length; ++i) {
                    float value = NumberUtils.toFloat(items[i]);
                    if (value > 0) {
                        list.get(i - 2).setValue(value);
                    }
                }
            }
        } else if (PATTERN.matcher(line).find()) {
            String[] tmp = line.split(",\"");
            if (tmp.length > 0) {
                parseMount(tmp[tmp.length - 1]);
            }
        } else if (line.startsWith(DISK_MQ_FLAG)) {
            parseMount(line.substring(DISK_MQ_FLAG.length() + 1));
        }
    }

    /**
     * 解析df命令
     * 格式：MQDISK /dev/vdb1         403042 243443    139104  64% /data
     *
     * @param dfLine
     */
    private void parseMount(String dfLine) {
        String[] item = dfLine.split("\\s+");
        if (item.length != 6 || !item[4].contains("%")) {
            return;
        }
        List<Usage> list = diskMap.get(DiskUsageType.busy);
        if (list == null) {
            return;
        }
        String[] tp = item[0].split("/");
        String mount = tp[tp.length - 1];
        for (Usage usage : list) {
            if (!usage.getName().equals(mount)) {
                continue;
            }
            DiskUsage spaceUsage = new DiskUsage();
            spaceUsage.setDiskUsageTyp(DiskUsageType.space);
            spaceUsage.setName(usage.getName());
            spaceUsage.setValue(NumberUtils.toFloat(item[4].split("%")[0]));
            spaceUsage.setMount(item[item.length - 1]);
            spaceUsage.setSize(NumberUtils.toInt(item[1]));
            spaceUsage.setUsed(NumberUtils.toInt(item[2]));
            List<Usage> spaceList = diskMap.computeIfAbsent(DiskUsageType.space, k -> new ArrayList<>());
            spaceList.removeIf(u -> u.getName().equals(mount));
            spaceList.add(spaceUsage);
        }
    }

    public Map<DiskUsageType, List<Usage>> getDiskMap() {
        return diskMap;
    }

    public float getRead() {
        List<Usage> usageList = diskMap.get(DiskUsageType.read);
        return getUsage(usageList);
    }

    public float getWrite() {
        List<Usage> usageList = diskMap.get(DiskUsageType.write);
        return getUsage(usageList);
    }

    public float getIops() {
        List<Usage> usageList = diskMap.get(DiskUsageType.transfer);
        return getUsage(usageList);
    }

    public float getBusy() {
        List<Usage> usageList = diskMap.get(DiskUsageType.busy);
        return getUsage(usageList);
    }

    public String getExt() {
        StringBuilder sb = new StringBuilder();
        for (DiskUsageType type : diskMap.keySet()) {
            if (DiskUsageType.space == type) {
                continue;
            }
            sb.append(type.getValue());
            sb.append("=");
            List<Usage> usageList = diskMap.get(type);
            for (Usage use : usageList) {
                sb.append(use.getName());
                sb.append(":");
                sb.append(use.getValue());
                sb.append(",");
            }
            sb.append(";");
        }
        return sb.toString();
    }

    public String getSpace() {
        StringBuilder sb = new StringBuilder();
        List<Usage> usageList = diskMap.get(DiskUsageType.space);
        if (usageList == null) {
            return sb.toString();
        }
        for (Usage use : usageList) {
            sb.append(use.getName());
            sb.append(":");
            sb.append(use.getValue());
            sb.append(":");
            sb.append(((DiskUsage) use).getMount());
            sb.append(":");
            sb.append(((DiskUsage) use).getSize());
            sb.append(":");
            sb.append(((DiskUsage) use).getUsed());
            sb.append(",");
        }
        return sb.toString();
    }

    private float getUsage(List<Usage> usageList) {
        float usage = 0;
        if (usageList != null) {
            for (Usage u : usageList) {
                if (!SUBPARTITION_PATTERN.matcher(u.getName()).find()) {
                    usage += u.getValue();
                }
            }
        }
        return usage;
    }

    @Override
    public String toString() {
        return "Disk [diskMap=" + diskMap + "]";
    }

    /**
     * 使用率
     */
    public static class Usage {
        // 分区名字
        private String name;
        // 使用率类型
        private DiskUsageType diskUsageType;
        // 使用率
        private float value;

        public DiskUsageType getDiskUsageType() {
            return diskUsageType;
        }

        public void setDiskUsageTyp(DiskUsageType diskUsageType) {
            this.diskUsageType = diskUsageType;
        }

        public float getValue() {
            return value;
        }

        public void setValue(float value) {
            this.value = value;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        @Override
        public String toString() {
            return "Usage [name=" + name + ", diskUsageType=" + diskUsageType
                    + ", value=" + value + "]";
        }
    }

    /**
     * 磁盘使用情况
     */
    public static class DiskUsage extends Usage {
        // 挂载点
        private String mount;
        // 总容量,单位M
        private int size;
        // 已使用,单位M
        private int used;

        public String getMount() {
            return mount;
        }

        public void setMount(String mount) {
            this.mount = mount;
            if (mount.endsWith("\"")) {
                this.mount = mount.substring(0, mount.length() - 1);
            }
        }

        public int getSize() {
            return size;
        }

        public void setSize(int size) {
            this.size = size;
        }

        public int getUsed() {
            return used;
        }

        public void setUsed(int used) {
            this.used = used;
        }

        public String getSizeFormat(){
            return WebUtil.sizeFormat(size *  1024L * 1024);
        }

        public String getUsedFormat(){
            return WebUtil.sizeFormat(used *  1024L * 1024);
        }

        @Override
        public String toString() {
            return "DiskUsage{" +
                    "mount='" + mount + '\'' +
                    ", size=" + size +
                    ", used=" + used +
                    '}';
        }
    }

    /**
     * 使用率类型
     */
    enum DiskUsageType {
        // 繁忙程度
        busy("DISKBUSY"),
        // 读
        read("DISKREAD"),
        // 写
        write("DISKWRITE"),
        // io次数
        transfer("DISKXFER"),
        // 空间使用率
        space("df"),
        ;
        private String value;

        private DiskUsageType(String value) {
            this.value = value;
        }

        public String getValue() {
            return value;
        }

        public static DiskUsageType getType(String type) {
            for (DiskUsageType dut : DiskUsageType.values()) {
                if (dut.getValue().equals(type)) {
                    return dut;
                }
            }
            return null;
        }
    }
}
