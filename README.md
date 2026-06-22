# Tempo

智能待办 App（Flutter）+ 思源笔记单向导入。在线优先同步，支持语音/文本创建任务、日历视图与本地到期提醒。

## 功能概览

| 模块 | 状态 | 说明 |
|------|------|------|
| 任务 CRUD | 已上线 | 列表/详情、工作·生活分类、全天任务、左滑删除、5s 撤回 |
| 语音创建 | 已上线 | 火山流式 ASR + `parse-task` LLM 解析；高置信自动创建，低置信草稿确认 |
| 文本/快速创建 | 已上线 | QuickCreate Sheet + LLM 日期/分类解析 |
| 日历视图 | 已上线 | 月视图 + 周视图（应用内任务，非系统日历） |
| 本地通知 | 已上线 | 有具体时间的任务：到期前 15 分钟 + 到期时；设置页可开关 |
| 思源导入 | MVP 已交付 | 配对码 + 可安装插件 zip；思源 → Tempo 单向导入 |
| AI 智能排期 | 未实现 | 计划页为占位，设置项标记「即将推出」 |
| 系统日历 | 未实现 | 设置项标记「即将推出」 |

## 技术栈

- **客户端**：Flutter 3 · Riverpod · GoRouter · Drift (SQLite)
- **后端**：Supabase（PostgreSQL · Auth · Edge Functions）
- **AI/语音**：豆包 LLM（`parse-task`）· 火山引擎流式 ASR（`asr-session` / `asr-relay`）
- **思源插件**：TypeScript · esbuild · Petal Plugin API

## 项目结构

```
tempo/
├── lib/                      # Flutter 应用
│   ├── features/
│   │   ├── tasks/            # 任务 CRUD、语音、通知
│   │   ├── calendar/         # 日历视图
│   │   ├── settings/         # 设置、思源配对、反馈
│   │   ├── auth/             # Magic Link 登录
│   │   └── ai_planner/       # 计划页占位
│   ├── database/             # Drift 本地缓存
│   └── core/                 # 路由、主题、常量
├── supabase/
│   ├── functions/            # Edge Functions
│   │   ├── parse-task/       # 文本/语音结构化解析
│   │   ├── asr-session/      # 流式 ASR 会话配置
│   │   ├── asr-relay/        # ASR WebSocket 中继
│   │   └── siyuan-pairing/   # 思源配对码换 token
│   └── migrations/           # 数据库迁移（0001–0005）
├── siyuan-plugin/            # 思源 Petal 插件
│   ├── src/                  # TypeScript 源码
│   └── dist/tempo-sync.zip   # 构建产物（npm run package）
├── test/                     # 单元/Widget 测试（54 项）
├── tempo-mvp.html            # MVP 实验设计文档（浏览器打开）
└── prototype/                # React 原型（仅 UI 参考）
```

## 快速开始

### 环境要求

- Flutter SDK ^3.11
- Node.js 18+（思源插件构建）
- Supabase CLI（后端部署）
- 思源笔记 3.0+（插件安装，可选）

### 1. 配置环境变量

```bash
cp .env.example .env
# 填入 SUPABASE_URL、SUPABASE_ANON_KEY 及各 Edge Function 端点
```

### 2. 启动 Flutter 应用

```bash
flutter pub get
flutter run
```

### 3. 部署 Supabase（首次或迁移更新后）

```bash
supabase link --project-ref <your-project-ref>
supabase db push
supabase functions deploy parse-task
supabase functions deploy asr-session
supabase functions deploy asr-relay
supabase functions deploy siyuan-pairing
```

Edge Function Secrets 见 [`.env.example`](.env.example) B 部分说明。

### 4. 构建思源插件

```bash
cd siyuan-plugin
npm install
npm run package
# 产物：dist/tempo-sync.zip
```

安装：思源笔记 → 设置 → 集市 → 导入插件包。详细步骤见 [`siyuan-plugin/README.zh-CN.md`](siyuan-plugin/README.zh-CN.md)。

## 核心流程

### 语音创建任务

```
按住麦克风 → 流式 ASR (asr-relay) → 转写文本
    → parse-task (豆包 LLM) → 标题/日期/分类/置信度
    → 高置信自动入库 · 低置信草稿确认 → 本地通知调度
```

- 仅说日期（如「星期四去吃 KFC」）→ **全天任务**（`is_all_day: true`），不默认 9:00
- 餐饮/外出类语音任务 → 自动归为「生活」

### 思源单向导入

```
Tempo 生成配对码 → 思源插件输入配对码 → siyuan-pairing 换 session
    → 扫描文档中 - [ ] 任务块 → RPC create_task_from_siyuan
    → 写回 custom-tempo-id → App 拉取云端任务
```

设置页展示真实绑定状态（`siyuan_bindings` 表）与最近同步时间。

### 数据同步策略

- **写入**：在线优先（先 Supabase，失败降级本地 `syncPending`）
- **读取**：本地 Drift 毫秒级响应 + 后台静默刷新
- **冲突**：last-write-wins；离线修改不覆盖 pending 记录

## 测试

```bash
flutter test   # 54 项单元/Widget 测试

cd siyuan-plugin && npm run build   # 插件构建验证
```

## 文档

- [MVP 实验设计](tempo-mvp.html) — 在浏览器中打开，含假设验证框架与实现进度
- [思源插件安装](siyuan-plugin/README.zh-CN.md)
- [环境变量说明](.env.example)

## 路线图（摘要）

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 1 | 待办 + 日历 + 语音 + 思源 MVP + 通知 | **已交付** |
| Phase 1.5 | 5–10 人 Dogfooding + 反馈收集 | 待启动 |
| Phase 2 | AI 排期、系统日历、日视图拖拽 | 未开始 |
| Phase 3 | 思源双向同步 + Widget 嵌入 | 未开始 |

## License

Private project. All rights reserved.
