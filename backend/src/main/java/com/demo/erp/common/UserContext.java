package com.demo.erp.common;

/**
 * 登录用户上下文(ThreadLocal 持有,请求结束后由拦截器清理)
 */
public final class UserContext {

    private static final ThreadLocal<LoginUser> HOLDER = new ThreadLocal<>();

    private UserContext() {
    }

    public static void set(LoginUser user) {
        HOLDER.set(user);
    }

    /** 获取当前登录用户,未登录时抛出 401 业务异常 */
    public static LoginUser get() {
        LoginUser user = HOLDER.get();
        if (user == null) {
            throw new BizException(401, "未登录或登录已过期");
        }
        return user;
    }

    /** 校验当前用户为管理员 */
    public static void checkAdmin() {
        if (!get().isAdmin()) {
            throw new BizException(403, "无权限,仅管理员可操作");
        }
    }

    public static void clear() {
        HOLDER.remove();
    }
}
