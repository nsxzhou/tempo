# Tempo 思源待办插件

在思源笔记中使用 Tempo 待办与日历，与手机 App 共享同一 Supabase 云端数据。

## 安装

1. 在 Tempo 项目根目录配置 `.env`（需包含 `SUPABASE_URL`、`SUPABASE_ANON_KEY`）
2. 构建插件包：

```bash
cd siyuan-plugin
npm install
npm run package
```

产物：`dist/tempo.zip`（兼容副本 `dist/tempo-sync.zip`）

3. 打开思源笔记 → **设置 → 集市 → 导入插件包**，选择 `dist/tempo.zip`
4. **确认安装目录名为 `tempo`**（必须与 `plugin.json` 的 `name` 一致）。若手动解压，请放到 `data/plugins/tempo/`，不要命名为 `tempo-sync` 等其它名称
5. 启用插件后，点击顶栏 **Tempo** 打开 Tab 页

## 使用

1. Tempo App → **我的** → **思源外部笔记 Petal 连接** → 生成 6 位配对码
2. 在思源 Tempo Tab 输入配对码并绑定
3. 绑定成功后使用顶部 **待办 | 日历** 切换页面
4. 与手机 App 的数据通过 Supabase Realtime 近实时同步

## 功能（v0.3.0）

- **待办**：Bento 四卡横排、工作/生活分类、任务 CRUD、右下角新建
- **日历**：月 / 周 / 日三视图、选中日期任务面板
- **宽屏适配**：日历页 ≥900px 时左右分栏；配对页 ≥768px 双栏引导
- **配对 / 解绑**：右上角齿轮入口

## 开发

```bash
npm run verify  # tsc + 冒烟测试
npm run build   # 输出 dist/index.js
npm run package # 输出 dist/tempo-sync.zip
```

构建时会从项目根目录 `.env` 注入 Supabase 配置。

## 说明

- 解绑需在思源插件设置与 Tempo App 两侧分别操作
- v2 计划：思源块导入、语音创建、完成状态回写思源
