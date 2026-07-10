# 将提醒系统改为完全本地通知

## 目标

将 Tempo Android 待办提醒从 FCM/Supabase 定时推送改为完全本地通知，确保本机已有任务在 App 被普通划掉、锁屏或进程回收后仍能提醒，并消除重复任务历史提醒集中补发。

## 已确认事实

- 真机为小米 Android 16，通知权限、精确闹钟权限和高重要性通知渠道均已启用。
- 现版本启动时在 Firebase 初始化前访问 `FirebaseMessaging.instance`，抛出 `[core/no-app]` 并中断通知 bootstrap。
- 当前服务端 `notification_devices` 没有有效设备，FCM 链路没有产生提醒。
- 产品决定完全移除 FCM 和服务端提醒，不保留云端兜底。

## 需求

- 所有本机已同步且未完成、带到期时间的任务使用 Android 本地通知。
- 单次任务只排一个未来提醒；重复任务滚动预排未来 90 天。
- 仅排 `reminderAt > now` 的提醒，历史提醒永不补发。
- 全天任务于本地日期 08:00 提醒；具体时间任务按任务时间提醒。
- 重复规则遵守每日、每周、每月、INTERVAL、COUNT、UNTIL、完成记录、取消例外、改期及标题覆盖。
- 排程更新串行化，启动重建不得误删并发创建或编辑产生的新提醒。
- 提醒默认开启，移除产品层总开关。
- 首次进入主界面后解释通知用途并申请 Android 通知权限；拒绝后不重复弹系统权限框。
- “我的”页面移除待办提醒入口；任务页在存在定时任务且权限异常时显示系统设置提示条。
- 注销取消本账号全部本地通知；其他设备变更需本机再次打开同步后才会排程。
- Android 强行停止不在保证范围内。

## 云端清理

- 客户端移除 Firebase Core、Firebase Messaging、Google Services 配置及远端通知代码。
- 停用并删除 Supabase reminder Cron、Edge Function、Secret、通知表和重试函数。
- 保留历史 migration，新增清理 migration。
- 真机验收通过且确认无其他用途后删除 Firebase 项目 `tempo-37633`。

## 验收标准

- 创建 3–5 分钟后的任务，划掉 App 并锁屏后仍按时收到。
- 重复任务只包含未来 90 天的系统闹钟，不包含历史 occurrence，打开 App 不批量补发。
- 编辑、删除、完成、取消或改期 occurrence 后系统排程同步更新。
- 权限未允许时任务页有恢复入口；权限正常时不显示。
- App 不再初始化或引用 Firebase；线上无 reminder Cron、函数、通知表和 Firebase 项目。
- `dart format lib test`、`flutter analyze`、`flutter test`、Android release 构建通过。
- 版本为 `0.1.2+3`，真机安装验收完成。
