# Tempo 思源笔记插件

将思源笔记文档中的未完成任务块（`- [ ]` / `☐`）单向导入 Tempo App。

## 安装

1. 在 Tempo 项目根目录配置 `.env`（需包含 `SUPABASE_URL`、`SUPABASE_ANON_KEY`）
2. 构建插件包：

```bash
cd siyuan-plugin
npm install
npm run package
```

产物：`dist/tempo-sync.zip`

3. 打开思源笔记 → **设置 → 集市 → 导入插件包**，选择 `tempo-sync.zip`
4. 启用插件后，在右侧 Dock 打开 **Tempo 同步** 面板

## 绑定与导入

1. Tempo App → **我的** → **思源外部笔记 Petal 连接** → 生成 6 位配对码
2. 在思源插件面板输入配对码并绑定
3. 打开含待办列表的文档（含 `- [ ]` 任务项）
4. 点击 **扫描当前文档任务**，新任务会写入 Tempo 云端
5. 回到 Tempo App 待办列表下拉刷新即可看到导入的任务

## 说明

- 仅 **思源 → Tempo** 单向导入，Tempo 内完成状态不会回写思源
- 已导入的块会写入 `custom-tempo-id` 属性，重复扫描会自动跳过
- 解绑需在思源插件与 Tempo App 两侧分别操作

## 开发

```bash
npm run build   # 输出 dist/index.js
npm run package # 输出 dist/tempo-sync.zip
```

构建时会从项目根目录 `.env` 注入 Supabase 配置。
