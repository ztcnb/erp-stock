package com.demo.erp.common;

import lombok.Getter;
import lombok.Setter;

/**
 * 统一响应体
 *
 * @param <T> 业务数据类型
 */
@Getter
@Setter
public class Result<T> {

    /** 状态码: 200 成功, 400 业务失败, 401 未认证, 403 无权限, 500 服务器错误 */
    private int code;

    /** 提示信息 */
    private String msg;

    /** 业务数据 */
    private T data;

    private Result(int code, String msg, T data) {
        this.code = code;
        this.msg = msg;
        this.data = data;
    }

    public static <T> Result<T> ok() {
        return new Result<>(200, "操作成功", null);
    }

    public static <T> Result<T> ok(T data) {
        return new Result<>(200, "操作成功", data);
    }

    public static <T> Result<T> fail(String msg) {
        return new Result<>(400, msg, null);
    }

    public static <T> Result<T> fail(int code, String msg) {
        return new Result<>(code, msg, null);
    }
}
