# 技术设计

## 边界

`NotificationService` 只负责 Android/iOS 本地通知能力、权限状态和稳定 ID；新增 `LocalReminderCoordinator` 作为唯一排程写入口，串行执行全量 reconcile 和按任务更新。UI、同步仓库和任务操作不直接操作插件。

## 排程模型

- 单次任务键：`task:<taskId>`。
- 重复 occurrence 键：`task:<taskId>:occurrence:<yyyy-MM-dd>`。
- reconcile 将任务、完成记录、例外展开成未来 90 天的期望提醒集合。
- 过滤已完成、已取消和 `reminderAt <= now` 的记录。
- 对每个任务先取消该任务现有 pending，再按期望集合重建；所有写操作进入同一个 Future 队列，避免 `cancelAll` 竞态。
- 首次升级使用版本标记执行一次 `cancelAll`，随后全量重建；以后不在普通启动流程无条件清空全部通知。
- 插件 BootReceiver 保留，用于设备重启后恢复持久化排程。

## 生命周期

- App bootstrap：初始化本地通知、处理一次性升级清理、请求/检查权限、读取仓库快照并 reconcile。
- App resume、登录后同步完成：重新读取快照并 reconcile。
- 创建、编辑、完成、删除、重复例外变化：串行更新对应任务或触发快照 reconcile。
- 注销：串行 `cancelAll`。

## 权限体验

- 新增通知权限状态对象：通知展示权限、精确闹钟能力。
- 首次主界面仅展示一次说明；确认后申请通知权限。权限被拒后通过任务页提示条进入系统设置。
- exact alarm 不可用时使用 inexact 排程并显示提示条，不在启动时连续弹多个系统页面。

## 删除远端链路

- 删除 RemoteNotificationService 及 Provider/监听。
- 删除 Firebase Flutter 依赖、Android Google Services 插件和配置文件。
- 新 migration 安全 unschedule Cron，删除重试函数和通知表。
- 删除 Edge Function 源码与配置；线上部署后删除函数、Secret，最终删除 Firebase 项目。
