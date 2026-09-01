package com.demo.erp.common;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * 单据编号工具:规则为 前缀 + yyyyMMdd + "-" + 4 位当日流水号,如 PO20260901-0001
 */
public final class OrderNoUtil {

    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    private OrderNoUtil() {
    }

    /** 生成当日前缀,如 PO20260901 */
    public static String todayPrefix(String type) {
        return type + LocalDate.now().format(DATE);
    }

    /**
     * 根据当日已有最大单号推算下一个单号
     *
     * @param prefix 当日前缀(如 PO20260901)
     * @param maxNo  当日已有最大单号,可为 null
     */
    public static String next(String prefix, String maxNo) {
        int seq = 1;
        if (maxNo != null && maxNo.startsWith(prefix)) {
            seq = Integer.parseInt(maxNo.substring(maxNo.lastIndexOf('-') + 1)) + 1;
        }
        return prefix + "-" + String.format("%04d", seq);
    }
}
