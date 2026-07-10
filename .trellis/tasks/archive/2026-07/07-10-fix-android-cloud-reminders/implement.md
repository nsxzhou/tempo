# Implementation Plan

1. 加载 backend/frontend 规范与 before-dev 检查。
2. 重构 NotificationService：重复只排最近一次、增加所有权过滤与前台即时展示。
3. 为 SyncTaskRepository 增加同步成功回调，并接入 Provider/启动重建/创建编辑流程。
4. 扩展 RemoteNotificationService：前台消息、登录态设备同步、注销禁用、payload 去重。
5. 调整设置页文案与注销顺序。
6. 重构 Edge Function 为可测试模块，增加严格当天窗口与两分钟失败重试。
7. 新增 notification delivery 重试迁移与 Cron 安装/验证 SQL/README。
8. 补齐 Flutter 与 Deno/TypeScript 测试。
9. 运行 dart format、flutter analyze、flutter test、Edge 测试；检查 Git diff 和 Trellis 质量门。

## Rollback points

- 客户端所有权切换可独立回滚到原 NotificationService 调度。
- 数据库新增列向后兼容，无需删除即可回滚函数。
- Cron 安装脚本单独提供 unschedule 命令。
