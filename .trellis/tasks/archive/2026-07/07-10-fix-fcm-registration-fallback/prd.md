# 修复 FCM 注册失败时本地提醒兜底

## Goal

只有 Android 设备成功注册 FCM token 后，已同步任务才切换为云端提醒；FCM 不可用或注册失败时继续使用本地系统通知，避免关闭 App 后完全没有提醒。

## Confirmed Facts

- 任务已成功同步云端，Cron 每分钟返回 200。
- `notification_devices` 在安装最新版并打开后仍为 0。
- 当前 `cloudRemindersAvailable` 仅判断登录态，导致无 token 的登录设备也取消本地排程。

## Requirements

- `RemoteNotificationService.syncDevice` 返回设备是否已成功注册。
- 用响应式注册状态而不是登录态决定通知所有权。
- token 为空、Firebase 不可用、Supabase upsert 失败时注册状态为 false，并重建本地兜底提醒。
- 注册成功时状态为 true，清理云端任务本地排程，避免双发。
- 通知开关关闭和注销时注册状态复位。

## Acceptance Criteria

- FCM token 获取失败时，登录且已同步任务仍创建本地提醒。
- 设备 upsert 成功时，云端任务不保留本地提醒。
- App 启动、恢复前台和登录切换均刷新注册状态与本地排程。
- `flutter analyze`、相关测试及全量测试通过。
