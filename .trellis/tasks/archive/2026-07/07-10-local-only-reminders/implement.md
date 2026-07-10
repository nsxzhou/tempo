# 实施清单

1. 读取 Trellis Flutter、数据层、后端和测试规范，激活任务。
2. 重构 NotificationService：移除云端所有权/开关，增加权限状态、设置跳转、pending 查询和 90 天 occurrence 计划。
3. 增加串行 LocalReminderCoordinator，并接入 App 生命周期、任务创建/编辑/完成/删除、例外和注销。
4. 实现首次权限说明和任务页权限异常提示条，删除设置页待办提醒开关。
5. 移除 RemoteNotificationService、Firebase 依赖、Gradle 插件、google-services 配置及测试。
6. 新增 Supabase 清理 migration，删除 reminder Edge Function 与配置，更新项目规范。
7. 升级版本至 0.1.2+3，补齐单元和 Widget 测试。
8. 运行 format、analyze、test、release build；修复所有失败。
9. 安装真机，用 ADB 验证权限、AlarmManager 和划掉 App 后提醒。
10. 部署 Supabase 清理，删除线上 Edge Function/Secret，核验后删除 Firebase 项目。
11. 按客户端、云端、测试文档分组提交并推送，记录 journal，归档任务。

## 回滚点

- 云端清理前先完成客户端真机验收。
- Firebase 项目删除必须最后执行，并先确认项目只服务 Tempo FCM。
- 已上线 migration 不回写；回滚需新增恢复 migration。
