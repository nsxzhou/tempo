# Design

## Architecture

提醒按任务同步状态划分唯一所有者：本地-only/待同步任务由 `NotificationService` 调度；云端已同步任务由 Supabase Cron + Edge Function + FCM 调度。`SyncTaskRepository` 通过可注入的同步成功回调通知上层取消本地兜底，数据层不直接依赖通知插件。

## Client data flow

1. 创建/编辑任务后，本地服务只在 `userId == null || task.syncPending` 时排程。
2. 重复任务通过 `RecurrenceEngine.nextOccurrence` 只取最近一次 pending occurrence。
3. Repository upsert 云端成功并落地 `syncPending=false` 后调用 `onTaskSynced(taskId)`；Provider 将其连接到 `NotificationService.cancelTaskReminders`。
4. App bootstrap 先 `cancelAll`，再按所有权重建本地提醒；同时初始化 RemoteNotificationService 并同步当前设备。
5. 前台 FCM 由 RemoteNotificationService 监听，使用 NotificationService 的即时展示 API；后台 FCM 由系统通知 payload 展示。
6. 注销前禁用当前 token，再退出 Supabase session。

## Server data flow

Cron 每分钟调用函数。函数按设备时区构造严格的一分钟候选窗口，只选择当天 occurrence。`notification_deliveries` 记录 attempt_count/last_attempt_at/status：

- 首次候选插入 pending 并发送。
- 唯一键冲突时，仅当 status=failed、attempt_count 未超限、当前时间仍在 reminderAt 后 2 分钟内时 claim 重试。
- sent 或超窗 failed 均跳过，不补发。

FCM payload 使用 `reminderKey = taskId:occurrenceDate-or-single:reminderAtISO`；Android notification tag 使用相同键，客户端前台即时通知 ID 由该键稳定哈希。

## Compatibility and rollout

- 保留现有通知总开关；升级启动的 cancelAll 清理旧 14 条预排。
- 新增数据库列使用 IF NOT EXISTS/default，不破坏旧数据。
- Edge Function 部署后再启用/确认 Cron；失败时可回滚函数版本，本地未同步兜底仍可工作。
