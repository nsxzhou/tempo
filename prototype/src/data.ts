import { Task, PlannerBlock } from './types';

export const INITIAL_TASKS: Task[] = [
  {
    id: 't-1',
    title: 'Review PRD — 用户中心改版 v2',
    priority: 'p1',
    deadline: '14:00 截止',
    tag: '产品',
    completed: false,
    overdue: false,
    description: '检查产品团队提交的「用户中心改版 v2」PRD，重点关注：个人信息编辑流程、头像上传限制、多设备登录管理三个模块的交互方案。标注需要在评审会上讨论的问题点。',
    siyuanLink: {
      title: '用户中心改版 v2 — PRD',
      url: 'siyuan://产品设计/PRD'
    },
    subtasks: [
      { id: 'sub-1', title: '通读全文标注疑问点', completed: true },
      { id: 'sub-2', title: '整理交互流程图反馈', completed: true },
      { id: 'sub-3', title: '撰写评审意见文档', completed: false },
      { id: 'sub-4', title: '同步到评审会 Notion 页面', completed: false }
    ],
    estimate: '1h 30m',
    allocatedTime: '14:00 – 15:30',
    energyMatch: '精力匹配 84%'
  },
  {
    id: 't-2',
    title: '提交 Q2 季度报告',
    priority: 'p0',
    deadline: '已过期',
    tag: '工作',
    completed: false,
    overdue: true,
    description: '整理第二季度所有项目交付及核心业务指标增长情况，制作总结幻灯片并与各业务负责人校对关键数据，确保在董事会评审时汇报信息精准。',
    siyuanLink: {
      title: 'Q2 季度核心增长数据',
      url: 'siyuan://财务汇报/Q2数据'
    },
    subtasks: [
      { id: 'sub2-1', title: '汇总各部门研发交付物', completed: false },
      { id: 'sub2-2', title: '校查财务报销与预算偏离度', completed: false }
    ],
    estimate: '2h',
    allocatedTime: '09:30 – 11:30',
    energyMatch: '精力匹配 92%'
  },
  {
    id: 't-3',
    title: '整理读书笔记 —《思考，快与慢》',
    priority: 'p2',
    deadline: '明天',
    tag: '阅读',
    completed: false,
    overdue: false,
    description: '重读第5-8章关于「系统 1」和「系统 2」的信息加工偏差，提取核心模型并配合日常决策案例，输出到个人知识库中，用于后期课程分享。',
    siyuanLink: null,
    subtasks: [
      { id: 'sub3-1', title: '提炼核心图表并绘制思维导图', completed: false }
    ],
    estimate: '1h 30m',
    allocatedTime: '16:00 – 17:30',
    energyMatch: '精力匹配 74%'
  },
  {
    id: 't-4',
    title: '预约周四牙医',
    priority: 'p3',
    deadline: '本周内',
    tag: '生活',
    completed: false,
    overdue: false,
    description: '致电瑞尔齿科预约本周四下午 15:00 的牙齿例行洁治与敏感修复情况复查。',
    siyuanLink: null,
    subtasks: [],
    estimate: '15m',
    allocatedTime: '11:30 – 11:45',
    energyMatch: '精力匹配 60%'
  },
  {
    id: 't-5',
    title: '更新 Tempo 项目路线图',
    priority: 'p1',
    deadline: '今天 18:00',
    tag: '产品',
    completed: false,
    overdue: false,
    description: '基于技术团队反馈，微调 Tempo 原型演进里程碑。更新交互细节与高保真原型迭代说明，使版本路线同步到团队频道。',
    siyuanLink: null,
    subtasks: [
      { id: 'sub5-1', title: '增加 shadcn UI 组件设计图', completed: true },
      { id: 'sub5-2', title: '增加微交互动效定义', completed: true },
      { id: 'sub5-3', title: '修正跨端协作接口时延范围', completed: false },
      { id: 'sub5-4', title: '更新 Notion 主路线图甘特图', completed: false }
    ],
    estimate: '30m',
    allocatedTime: '17:30 – 18:00',
    energyMatch: '精力匹配 88%'
  },
  {
    id: 't-6',
    title: '晨间站会',
    priority: 'p3',
    deadline: '09:30 已完成',
    tag: '工作',
    completed: true,
    overdue: false,
    description: '每日早会，同步昨日进展与今日计划，清除排期冲突阻碍。',
    siyuanLink: null,
    subtasks: [],
    estimate: '30m',
    allocatedTime: '09:00 – 09:30',
    energyMatch: '日程项'
  },
  {
    id: 't-7',
    title: '回复 Slack — 设计评审反馈',
    priority: 'p2',
    deadline: '08:45 已完成',
    tag: '产品',
    completed: true,
    overdue: false,
    description: '就产品主色调微调及侧边导航操作热区，给出交互层面的最终确认。',
    siyuanLink: null,
    subtasks: [],
    estimate: '15m',
    allocatedTime: '08:45 – 09:00',
    energyMatch: '轻量沟通'
  },
  {
    id: 't-8',
    title: '购买咖啡豆',
    priority: 'p3',
    deadline: '昨天 已完成',
    tag: '生活',
    completed: true,
    overdue: false,
    description: '下单埃塞俄比亚耶加雪菲半水洗单品咖啡豆，深度烘焙。',
    siyuanLink: null,
    subtasks: [],
    estimate: '10m',
    allocatedTime: '08:30 – 08:40',
    energyMatch: '私人琐事'
  }
];

export const INITIAL_PLANNER_BLOCKS: PlannerBlock[] = [
  {
    id: 'block-1',
    start: '09:00',
    end: '09:30',
    title: '晨间站会',
    reason: '日程事件 · 已自动识别并录入日历',
    tag: 'calendar',
    active: false
  },
  {
    id: 'block-2',
    start: '09:30',
    end: '11:30',
    title: '提交 Q2 季度报告',
    reason: 'P0 紧急高耗能活动 ⚡ 建议安排在晨间最高精力段',
    tag: 'p0',
    active: true
  },
  {
    id: 'block-3',
    start: '11:30',
    end: '12:00',
    title: '回复邮件和消息',
    reason: '生理精力下降期 📉 适合低认知复发碎事与缓冲',
    tag: 'buff',
    active: false
  },
  {
    id: 'block-4',
    start: '12:00',
    end: '13:30',
    title: '优雅午休 & 精力蓄能',
    reason: '脑体保护时间，屏蔽一切推送与外部干扰',
    tag: 'break',
    active: false
  },
  {
    id: 'block-5',
    start: '14:00',
    end: '15:30',
    title: 'Review PRD — 用户中心改版 v2',
    reason: '咖啡因生效期 🧉 适合复杂 PRD 梳理与架构深度思考',
    tag: 'p1',
    active: false
  },
  {
    id: 'block-6',
    start: '16:00',
    end: '17:30',
    title: '整理读书笔记 —《思考，快与慢》',
    reason: '独立阅读提炼 · 完美融入个人学术研究低谷期',
    tag: 'p2',
    active: false
  },
  {
    id: 'block-7',
    start: '17:30',
    end: '18:00',
    title: '更新 Tempo 项目路线图',
    reason: '本日收尾活动 🏁 校准交付状态，优雅迎接明日节奏',
    tag: 'p1',
    active: false
  }
];

export const ENERGY_HEATMAP = [
  { day: '一', levels: [1, 2, 3, 4, 4, 3, 2, 1, 2, 3, 3, 2] },
  { day: '二', levels: [2, 3, 3, 4, 3, 2, 1, 1, 2, 2, 3, 2] },
  { day: '三', levels: [2, 2, 3, 3, 2, 2, 1, 1, 3, 3, 3, 2] },
  { day: '四', levels: [3, 4, 4, 3, 3, 2, 1, 1, 2, 2, 3, 3] },
  { day: '五', levels: [2, 3, 4, 3, 3, 1, 1, 1, 2, 2, 2, 1] },
  { day: '六', levels: [1, 1, 2, 2, 3, 3, 2, 2, 2, 3, 3, 2] },
  { day: '日', levels: [1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1] }
];
