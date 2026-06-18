import React, { useState, useMemo } from 'react';
import { 
  CheckSquare, 
  Calendar as CalendarIcon, 
  Sparkles, 
  User, 
  Terminal, 
  Monitor, 
  Smartphone, 
  ChevronRight, 
  Info,
  Undo,
  Link,
  ClipboardList,
  Send,
  Star,
  FileText,
  Check
} from 'lucide-react';
import { Task, PlannerBlock, TabName } from './types';
import { INITIAL_TASKS, INITIAL_PLANNER_BLOCKS } from './data';

// Subcomponents
import StatusBar from './components/StatusBar';
import TasksView from './components/TasksView';
import CalendarView from './components/CalendarView';
import PlanView from './components/PlanView';
import SettingsView from './components/SettingsView';
import DetailView from './components/DetailView';
import VoiceOverlay from './components/VoiceOverlay';
import Snackbar from './components/Snackbar';

import { motion, AnimatePresence } from 'motion/react';

export default function App() {
  // Navigation & View States
  const [activeTab, setActiveTab] = useState<TabName>('tasks');
  const [previousTab, setPreviousTab] = useState<TabName>('tasks'); // helps back trace after details view
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  
  // Showcase view preferences (Simulator Framed vs. Responsive Full width Fit)
  const [viewFramed, setViewFramed] = useState<boolean>(true);

  // App core interactive states
  const [tasks, setTasks] = useState<Task[]>(INITIAL_TASKS);
  const [plannerBlocks, setPlannerBlocks] = useState<PlannerBlock[]>(INITIAL_PLANNER_BLOCKS);
  const [isReplanning, setIsReplanning] = useState<boolean>(false);
  const [voiceOpen, setVoiceOpen] = useState<boolean>(false);

  // MVP v2.0 Simulation & Testing States
  const [siyuanMarkdown, setSiyuanMarkdown] = useState<string>(
    `# 🌲 周四工作与复盘笔记
☐ 审阅本周产品设计迭代大纲 @工作
☑ 晨间脑力恢复呼吸冥想 @生活
☐ 测试 H3 假设并提交实验评语 @产品
☐ 校对第三季度设计系统文档 @工作

# 🌿 购物及日常习惯
☐ 准备一杯双倍浓缩意式咖啡 @生活
☐ 打扫工作台、调整桌椅高度 @生活`
  );
  const [onboardingStep, setOnboardingStep] = useState<number | null>(0);
  const [h1Score, setH1Score] = useState<number>(60);
  const [h2Score, setH2Score] = useState<number>(70);
  const [h3Score, setH3Score] = useState<number>(4.2);
  const [feedbackInput, setFeedbackInput] = useState<string>("");
  const [feedbackList, setFeedbackList] = useState<Array<{ time: string; text: string }>>([
    { time: "09:44", text: "希望能对已排期的时间块直接拖拽二次调整，这会带来更强的秩序感！" }
  ]);
  const [rightPanelTab, setRightPanelTab] = useState<'simulator' | 'hypotheses' | 'scope'>('simulator');

  // Undo buffers
  const [snapshotTasks, setSnapshotTasks] = useState<Task[] | null>(null);

  // Toast / Snackbar state
  const [snackbar, setSnackbar] = useState<{
    show: boolean;
    message: string;
    hasUndo: boolean;
  }>({
    show: false,
    message: '',
    hasUndo: false
  });

  // Simulator Logs for high-craftsmanship diagnostic panel
  const [simLogs, setSimLogs] = useState<Array<{ time: string; msg: string; type: 'action' | 'system' }>>([
    { time: '09:41', msg: 'Tempo Engine 启动成功 · Stripe Minimalist 版', type: 'system' },
    { time: '09:42', msg: '脑波精力分析已增量加载 (12个时段矩阵)', type: 'system' },
    { time: '09:42', msg: '思源本地客户端建立安全联动，增量 3 项笔记关联', type: 'system' }
  ]);

  const addLog = (msg: string, type: 'action' | 'system' = 'action') => {
    const now = new Date();
    const pad = (n: number) => n.toString().padStart(2, '0');
    // We can use mock morning hours to match simulated timeline
    const timeStr = `${pad(pad(now.getHours()) === '00' ? 9 : now.getHours())}:${pad(now.getMinutes())}`;
    setSimLogs(prev => [
      { time: timeStr, msg, type },
      ...prev.slice(0, 7) // keep last 8 logs
    ]);
  };

  // Toggle tasks check
  const handleToggleTask = (id: string) => {
    // Save snapshot for real undo command!
    setSnapshotTasks(JSON.parse(JSON.stringify(tasks)));
    
    setTasks(prev => prev.map(t => {
      if (t.id === id) {
        const nextState = !t.completed;
        addLog(`切换任务状态: "${t.title}" -> ${nextState ? '已完成' : '未完成'}`);
        // Real-time metric boost!
        if (nextState) {
          setH2Score(prevScore => Math.min(prevScore + 5, 100));
        }
        return {
          ...t,
          completed: nextState,
          // Sync appropriate deadline badges
          deadline: nextState ? '刚刚完成' : t.deadline === '已完成' ? '今天' : t.deadline
        };
      }
      return t;
    }));

    const target = tasks.find(t => t.id === id);
    if (target) {
      triggerNotification(!target.completed ? `已完成: ${target.title}` : `已恢复: ${target.title}`, true);
    }
  };

  // Detail item updates
  const handleUpdateTaskDetail = (updatedTask: Task) => {
    setTasks(prev => prev.map(t => (t.id === updatedTask.id ? updatedTask : t)));
    // If the active viewed task has details, sync selectedTask reference
    if (selectedTask && selectedTask.id === updatedTask.id) {
      setSelectedTask(updatedTask);
    }
    addLog(`编辑更新子任务列表: "${updatedTask.title}"`);
  };

  // Handle Voice input submissions
  const handleAddTaskParsed = (newTask: Task) => {
    setSnapshotTasks(JSON.parse(JSON.stringify(tasks)));
    setTasks(prev => [newTask, ...prev]);
    
    addLog(`AI 解析语音并成功排程: "${newTask.title}"`);
    triggerNotification(`AI 成功识别并排入任务 "${newTask.title}"`, true);
  };

  // Quick generic task insertion
  const handleAddTaskQuick = () => {
    setSnapshotTasks(JSON.parse(JSON.stringify(tasks)));
    const genericTitles = [
      '校对 Notion 中第三季度目标 (OKR)',
      '审查产品主线导航交互原型细节',
      '在 Slack 中知会运营部宣发物料进度',
      '检查财务季度预算审批通过情况',
      '购买人体工学座椅及配件'
    ];
    const categories = ['产品', '工作', '产品', '工作', '生活'];
    const pOptions: Array<'p0' | 'p1' | 'p2' | 'p3'> = ['p1', 'p0', 'p2', 'p1', 'p3'];
    
    const rng = Math.floor(Math.random() * genericTitles.length);

    const newTask: Task = {
      id: `qt-${Date.now()}`,
      title: genericTitles[rng],
      priority: pOptions[rng],
      deadline: '今天 18:00',
      tag: categories[rng],
      completed: false,
      overdue: false,
      description: '这是通过快捷按钮自主动效生成的全新待办。完美搭载 Stripe 优雅工艺与 shadcn 极简逻辑。',
      siyuanLink: null,
      subtasks: [],
      estimate: '45m',
      allocatedTime: '16:00 – 16:45',
      energyMatch: '能量均衡匹配'
    };

    setTasks(prev => [newTask, ...prev]);
    addLog(`快捷排期添加任务: "${newTask.title}"`);
    triggerNotification(`已快速排入 "${newTask.title}"`, true);
  };

  // Reverse complete actions via undo trigger
  const handleUndoAction = () => {
    if (snapshotTasks) {
      setTasks(snapshotTasks);
      setSnapshotTasks(null);
      addLog('成功执行撤销操作，状态已重置');
      triggerNotification('已被成功撤销重置');
    }
  };

  const triggerNotification = (message: string, hasUndo: boolean = false) => {
    setSnackbar({
      show: true,
      message,
      hasUndo
    });
  };

  // Navigation Tab controllers
  const handleSwitchTab = (tab: TabName) => {
    if (tab === 'detail') return; // details must only be loaded with a selectedTask
    setPreviousTab(activeTab);
    setActiveTab(tab);
    addLog(`导航切换到 [${
      tab === 'tasks' ? '任务大厅' :
      tab === 'calendar' ? '月度日历' :
      tab === 'plan' ? 'AI 智能排程' : '我的设置'
    }] 面板`);
  };

  const handleSelectTaskForDetails = (task: Task) => {
    setSelectedTask(task);
    setPreviousTab(activeTab);
    setActiveTab('detail');
    addLog(`锁定并调取任务微调浮窗: "${task.title}"`);
  };

  const handleCloseDetails = () => {
    setSelectedTask(null);
    setActiveTab(previousTab);
    addLog('收起任务微调浮窗');
  };

  // Re-plan simulated progress trigger
  const handleReplanTrigger = () => {
    setIsReplanning(true);
    addLog('开始 AI 智能运算，正在重构今日精力冲突时空区...', 'system');
    
    setTimeout(() => {
      setIsReplanning(false);
      // Re-order or shuffle state to simulate AI schedule refinement
      setPlannerBlocks(prev => {
        return prev.map(b => {
          if (b.tag === 'p1' || b.tag === 'p2') {
            // Swap times or marks slightly
            return {
              ...b,
              reason: b.reason.includes('重排') ? b.reason : `🔄 已在精力高峰重新对齐 - ${b.reason}`
            };
          }
          return b;
        });
      });
      // Real-time metric boost for AI Scheduling confirmation!
      setH1Score(prevScore => Math.min(prevScore + 15, 100));
      addLog('AI 重新排期方案已部署，脑力损耗减少 15%', 'system');
      triggerNotification('AI 重新规划精力排程成功');
    }, 1200);
  };

  const handleToggleBlockActive = (id: string) => {
    setPlannerBlocks(prev => prev.map(b => {
      if (b.id === id) {
        addLog(`标记流程块 [${b.title}] 为 ${!b.active ? '进行中' : '等待'}`);
        return { ...b, active: !b.active };
      }
      return b;
    }));
  };

  // MVP Dynamic Logic: 1. Siyuan Note Sync Parser (Phase 1 core)
  const handleImportFromSiyuan = () => {
    const lines = siyuanMarkdown.split('\n');
    let importedCount = 0;
    const incomingTasks: Task[] = [];

    lines.forEach((line, index) => {
      const trimmed = line.trim();
      // Check for markdown uncompleted task: ☐ (or [ ])
      if (trimmed.startsWith('☐') || trimmed.toLowerCase().startsWith('- [ ]')) {
        let taskText = trimmed.replace('☐', '').replace('- [ ]', '').trim();
        
        // Extract tag like @工作 / @生活 / @产品
        let tag = '工作';
        const tagMatch = taskText.match(/@(工作|生活|产品|阅读)/);
        if (tagMatch) {
          tag = tagMatch[1];
          taskText = taskText.replace(tagMatch[0], '').trim();
        }

        // Generate consistent priorities based on keyword triggers or randomly
        let priority: 'p0' | 'p1' | 'p2' | 'p3' = 'p1';
        if (taskText.includes('H3') || taskText.includes('高优') || taskText.includes('审阅')) {
          priority = 'p0';
        } else if (taskText.includes('咖啡') || taskText.includes('日常')) {
          priority = 'p3';
        } else if (index % 3 === 0) {
          priority = 'p2';
        }

        // Avoid adding duplicates by checking title
        if (!tasks.some(t => t.title === taskText)) {
          incomingTasks.push({
            id: `siyuan-block-${Date.now()}-${index}`,
            title: taskText,
            priority,
            deadline: '今天 18:00',
            tag,
            completed: false,
            overdue: false,
            description: '这是由思源笔记 Petal 插件通过 Supabase API 增量派送的未完行动项，已自带 custom-tempo-id 自定义块关联。',
            siyuanLink: {
              title: '思源原块',
              url: `siyuan://blocks/${Date.now()}-${index}`
            },
            subtasks: [],
            estimate: '30m',
            allocatedTime: '待排期',
            energyMatch: '匹配精力段'
          });
          importedCount++;
        }
      }
    });

    if (importedCount > 0) {
      setTasks(prev => [...incomingTasks, ...prev]);
      addLog(`[思源同步] 成功扫描到 ${importedCount} 项全新 ☐ 待办项。已赋予 custom-tempo-id 反向写入链。`, 'system');
      triggerNotification(`同步成功: 已自思源笔记增量导入 ${importedCount} 项待办`, true);
      
      // Drive H2 User retention score upwards!
      setH2Score(prev => Math.min(prev + 12, 100));
    } else {
      addLog(`[思源同步] 扫描完毕。当前笔记中已无新增未完成项 (或已完成去重)`, 'system');
      triggerNotification(`笔记中的代办此前已全部拉取同步`);
    }
  };

  // MVP Dynamic Logic: 2. Submit Qualitative UX Feedback (MVP H1/H2 feedback loop)
  const handleSubmitFeedback = (e: React.FormEvent) => {
    e.preventDefault();
    if (!feedbackInput.trim()) return;

    const newFeedback = {
      time: new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
      text: feedbackInput.trim()
    };

    setFeedbackList(prev => [newFeedback, ...prev]);
    addLog(`用户递交 qualitative 反馈评语: "${newFeedback.text}"`, 'action');
    triggerNotification('感谢您的反馈！评语已成功合并入实验指标中心');
    setFeedbackInput("");
    
    // Increment H2 & H5 scores due to healthy user engagement!
    setH2Score(prev => Math.min(prev + 8, 100));
  };

  return (
    <div className="min-h-screen w-full bg-[#ECECEE] flex items-center justify-center p-0 md:p-6 select-none font-sans antialiased text-[#0A0A0A]">
      <div className="w-full max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-12 gap-8 items-center">
        
        {/* LEFT / MAIN SIDE: SIMULATOR OR FULL FILL VIEW */}
        <div className={`md:col-span-7 flex justify-center py-4 ${viewFramed ? '' : 'md:col-span-12'}`}>
          
          {viewFramed ? (
            /* Simulator iPhone Mock Showcase Frame */
            <div 
              id="showcase-device"
              className="bg-[#1A1A1C] p-2 rounded-[48px] shadow-2xl border border-black/8 w-[398px] h-[852px] relative transform transition-all duration-300"
            >
              <div className="w-[382px] h-[836px] bg-white rounded-[40px] overflow-hidden relative border border-zinc-200 flex flex-col">
                
                {/* Simulated Top Dynamic Notch */}
                <div className="absolute top-[11px] left-1/2 transform -translate-x-1/2 w-[98px] h-[28px] bg-[#0A0A0A] rounded-[14px] z-[200] flex items-center justify-center select-none shadow-inner" />
                
                {/* Mock iOS upper status bar */}
                <StatusBar />

                {/* Onboarding Overlay inside phone simulator */}
                <AnimatePresence>
                  {onboardingStep !== null && (
                    <motion.div 
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      className="absolute inset-0 z-[190] bg-[#0A0A0A]/95 text-white flex flex-col justify-between p-7 pt-16 select-none font-sans"
                    >
                      <div className="space-y-4">
                        <div className="flex justify-between items-center">
                          <span className="font-mono text-[10px] text-zinc-400 bg-zinc-800/80 px-2.5 py-0.5 rounded-full uppercase tracking-widest font-semibold">
                            Tempo MVP 指南
                          </span>
                          <span className="font-mono text-[10px] text-zinc-500 font-bold">
                            {onboardingStep + 1} / 3
                          </span>
                        </div>

                        <div className="space-y-1 pt-4">
                          <h3 className="text-xl font-normal italic font-serif leading-tight text-white">
                            {onboardingStep === 0 && "🔌 思源中文笔记单向导入"}
                            {onboardingStep === 1 && "🌅 脑电波动与精力分配"}
                            {onboardingStep === 2 && "🧪 致命假设前置验证反馈"}
                          </h3>
                          <div className="w-12 h-[1.5px] bg-white mt-1.5" />
                        </div>

                        <p className="text-xs text-zinc-300 leading-relaxed pt-2.5">
                          {onboardingStep === 0 && "Tempo MVP 2.0 聚焦解决个人知识和行动系统的分裂。您可以在右侧‘思源笔记模拟器’中撰写任务列表，然后一键同步拉取，无需在工具间手动搬运数据。"}
                          {onboardingStep === 1 && "结合在设置页中点击微调的脑力精力曲线，Tempo 让每个习惯代办得到黄金专注带的妥协和舒展。智能排期（计划页）旨在验证高优承载 H1 与 H3。"}
                          {onboardingStep === 2 && "遵循 OPC MVP 实验方法论，我们致力于先收集真实的采纳比。您可以随意在使用待办或重新排期后，在右方测评中心对 LLM 方案质量评分打 1-5 星并递交评语！"}
                        </p>

                        <div className="grid grid-cols-3 gap-1.5 pt-6 select-none">
                          <div className={`h-1.5 rounded transition-colors ${onboardingStep === 0 ? "bg-white" : "bg-zinc-800"}`} />
                          <div className={`h-1.5 rounded transition-colors ${onboardingStep === 1 ? "bg-white" : "bg-zinc-800"}`} />
                          <div className={`h-1.5 rounded transition-colors ${onboardingStep === 2 ? "bg-white" : "bg-zinc-800"}`} />
                        </div>
                      </div>

                      <div className="space-y-3 pb-4">
                        <div className="flex gap-3">
                          {onboardingStep > 0 ? (
                            <button 
                              type="button"
                              onClick={() => setOnboardingStep(prev => prev !== null ? prev - 1 : null)}
                              className="flex-1 py-3 text-xs bg-transparent border border-zinc-700 hover:border-zinc-400 text-zinc-300 rounded-lg transition-colors cursor-pointer"
                            >
                              上一步
                            </button>
                          ) : (
                            <button 
                              type="button"
                              onClick={() => setOnboardingStep(null)}
                              className="flex-1 py-3 text-xs bg-transparent border border-zinc-800 hover:border-zinc-750 text-zinc-500 rounded-lg transition-colors cursor-pointer"
                            >
                              跳过
                            </button>
                          )}
                          
                          {onboardingStep < 2 ? (
                            <button 
                              type="button"
                              onClick={() => setOnboardingStep(prev => prev !== null ? prev + 1 : null)}
                              className="flex-1 py-3 text-xs bg-white text-black font-semibold rounded-lg hover:bg-zinc-150 transition-colors cursor-pointer text-center"
                            >
                              下一步
                            </button>
                          ) : (
                            <button 
                              type="button"
                              onClick={() => {
                                setOnboardingStep(null);
                                addLog("已完成 Tempo 新人排期策略手册引导", "system");
                                triggerNotification("迎刃而解！开始您的 MVP 同步试验吧");
                              }}
                              className="flex-1 py-3 text-xs bg-emerald-500 hover:bg-emerald-600 font-semibold text-white rounded-lg transition-colors cursor-pointer text-center"
                            >
                              开始同步体验
                            </button>
                          )}
                        </div>
                        <p className="text-[9px] text-zinc-500 text-center select-none font-mono">
                          TEMPO EXPERIMENT CORP · GOMVP DESIGN
                        </p>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* Switch Render tab views */}
                <div className="flex-1 w-full h-full relative overflow-hidden bg-white">
                  <AnimatePresence mode="wait">
                    {activeTab === 'tasks' && (
                      <motion.div 
                        key="tasks"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="w-full h-full"
                      >
                        <TasksView 
                          tasks={tasks}
                          onToggleTask={handleToggleTask}
                          onSelectTask={handleSelectTaskForDetails}
                          onOpenVoice={() => setVoiceOpen(true)}
                          onAddTaskQuick={handleAddTaskQuick}
                          onAddTaskParsed={handleAddTaskParsed}
                          onUpdateTask={handleUpdateTaskDetail}
                        />
                      </motion.div>
                    )}

                    {activeTab === 'calendar' && (
                      <motion.div 
                        key="calendar"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="w-full h-full"
                      >
                        <CalendarView 
                          tasks={tasks}
                          onSelectTask={handleSelectTaskForDetails}
                        />
                      </motion.div>
                    )}

                    {activeTab === 'plan' && (
                      <motion.div 
                        key="plan"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="w-full h-full"
                      >
                        <PlanView 
                          blocks={plannerBlocks}
                          onToggleBlockActive={handleToggleBlockActive}
                          onReplan={handleReplanTrigger}
                          isReplanning={isReplanning}
                        />
                      </motion.div>
                    )}

                    {activeTab === 'settings' && (
                      <motion.div 
                        key="settings"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="w-full h-full"
                      >
                        <SettingsView 
                          onShowNotificationBanner={triggerNotification}
                        />
                      </motion.div>
                    )}

                    {activeTab === 'detail' && selectedTask && (
                      <motion.div 
                        key="detail"
                        initial={{ x: '100%' }}
                        animate={{ x: 0 }}
                        exit={{ x: '100%' }}
                        transition={{ type: 'spring', damping: 25, stiffness: 350 }}
                        className="w-full h-full absolute inset-0 z-50 bg-white"
                      >
                        <DetailView 
                          task={selectedTask}
                          onClose={handleCloseDetails}
                          onUpdateTask={handleUpdateTaskDetail}
                          onShowBanner={triggerNotification}
                        />
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>

                {/* Lower Navigation Tabs Bar */}
                {activeTab !== 'detail' && (
                  <nav className="absolute bottom-0 left-0 right-0 h-[64px] bg-white/85 backdrop-blur-xl border-t border-[#E4E4E7] flex px-2 pb-[16px] z-50 select-none">
                    <button 
                      onClick={() => handleSwitchTab('tasks')}
                      className={`flex-1 flex flex-col items-center justify-center gap-1 border-none bg-transparent transition-colors duration-150 cursor-pointer ${activeTab === 'tasks' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                    >
                      <CheckSquare className="w-5 h-5 stroke-[2]" />
                      <span className="text-[10px] font-medium font-sans">TODO</span>
                    </button>
                    
                    <button 
                      onClick={() => handleSwitchTab('calendar')}
                      className={`flex-1 flex flex-col items-center justify-center gap-1 border-none bg-transparent transition-colors duration-150 cursor-pointer ${activeTab === 'calendar' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                    >
                      <CalendarIcon className="w-5 h-5 stroke-[2]" />
                      <span className="text-[10px] font-medium font-sans">日历</span>
                    </button>
                    
                    <button 
                      onClick={() => handleSwitchTab('plan')}
                      className={`flex-1 flex flex-col items-center justify-center gap-1 border-none bg-transparent transition-colors duration-150 cursor-pointer ${activeTab === 'plan' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                    >
                      <Sparkles className="w-5 h-5 stroke-[2]" />
                      <span className="text-[10px] font-medium font-sans">计划</span>
                    </button>
                    
                    <button 
                      onClick={() => handleSwitchTab('settings')}
                      className={`flex-1 flex flex-col items-center justify-center gap-1 border-none bg-transparent transition-colors duration-150 cursor-pointer ${activeTab === 'settings' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                    >
                      <User className="w-5 h-5 stroke-[2]" />
                      <span className="text-[10px] font-medium font-sans">我的</span>
                    </button>
                  </nav>
                )}

                {/* sliding panels (Microphone voice overlays) */}
                <VoiceOverlay 
                  isOpen={voiceOpen}
                  onClose={() => setVoiceOpen(false)}
                  onAddTaskParsed={handleAddTaskParsed}
                />

                {/* Absolute absolute bottom-toasts alert */}
                <Snackbar 
                  show={snackbar.show}
                  message={snackbar.message}
                  onUndo={snackbar.hasUndo ? handleUndoAction : undefined}
                  onClose={() => setSnackbar(prev => ({ ...prev, show: false }))}
                />

                {/* iPhone Home bottom indicator */}
                <div className="absolute bottom-[4px] left-[125px] w-[130px] h-[4.5px] bg-[#0A0A0A] rounded-[3px] z-[150] pointer-events-none select-none" />

              </div>
            </div>
          ) : (
            /* Responsive Fluid Web Fit View directly on core desktop viewport */
            <div className="w-full max-w-xl mx-auto bg-white rounded-2xl border border-zinc-200 shadow-xl overflow-hidden h-[780px] relative flex flex-col">
              <StatusBar />
              <div className="flex-1 w-full bg-white relative overflow-hidden mt-6 pb-12">
                {activeTab === 'tasks' && (
                  <TasksView 
                    tasks={tasks}
                    onToggleTask={handleToggleTask}
                    onSelectTask={handleSelectTaskForDetails}
                    onOpenVoice={() => setVoiceOpen(true)}
                    onAddTaskQuick={handleAddTaskQuick}
                    onAddTaskParsed={handleAddTaskParsed}
                    onUpdateTask={handleUpdateTaskDetail}
                  />
                )}
                {activeTab === 'calendar' && (
                  <CalendarView 
                    tasks={tasks}
                    onSelectTask={handleSelectTaskForDetails}
                  />
                )}
                {activeTab === 'plan' && (
                  <PlanView 
                    blocks={plannerBlocks}
                    onToggleBlockActive={handleToggleBlockActive}
                    onReplan={handleReplanTrigger}
                    isReplanning={isReplanning}
                  />
                )}
                {activeTab === 'settings' && (
                  <SettingsView 
                    onShowNotificationBanner={triggerNotification}
                  />
                )}
                {activeTab === 'detail' && selectedTask && (
                  <DetailView 
                    task={selectedTask}
                    onClose={handleCloseDetails}
                    onUpdateTask={handleUpdateTaskDetail}
                    onShowBanner={triggerNotification}
                  />
                )}
              </div>

              {/* Responsive Bottom navigation bar */}
              {activeTab !== 'detail' && (
                <nav className="h-[64px] border-t border-[#E4E4E7] flex px-2 bg-[#FAFAFA] shrink-0">
                  <button 
                    onClick={() => handleSwitchTab('tasks')}
                    className={`flex-1 flex flex-col items-center justify-center gap-1 cursor-pointer ${activeTab === 'tasks' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                  >
                    <CheckSquare className="w-5 h-5" />
                    <span className="text-[10px] font-semibold">TODO</span>
                  </button>
                  <button 
                    onClick={() => handleSwitchTab('calendar')}
                    className={`flex-1 flex flex-col items-center justify-center gap-1 cursor-pointer ${activeTab === 'calendar' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                  >
                    <CalendarIcon className="w-5 h-5" />
                    <span className="text-[10px] font-semibold">日历</span>
                  </button>
                  <button 
                    onClick={() => handleSwitchTab('plan')}
                    className={`flex-1 flex flex-col items-center justify-center gap-1 cursor-pointer ${activeTab === 'plan' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                  >
                    <Sparkles className="w-5 h-5" />
                    <span className="text-[10px] font-semibold">计划</span>
                  </button>
                  <button 
                    onClick={() => handleSwitchTab('settings')}
                    className={`flex-1 flex flex-col items-center justify-center gap-1 cursor-pointer ${activeTab === 'settings' ? 'text-[#0A0A0A]' : 'text-[#A1A1AA]'}`}
                  >
                    <User className="w-5 h-5" />
                    <span className="text-[10px] font-semibold">我的</span>
                  </button>
                </nav>
              )}

              <VoiceOverlay 
                isOpen={voiceOpen}
                onClose={() => setVoiceOpen(false)}
                onAddTaskParsed={handleAddTaskParsed}
              />

              <Snackbar 
                show={snackbar.show}
                message={snackbar.message}
                onUndo={snackbar.hasUndo ? handleUndoAction : undefined}
                onClose={() => setSnackbar(prev => ({ ...prev, show: false }))}
              />
            </div>
          )}

        </div>

        {/* RIGHT SIDE: PRESENTATION DESK (Only shown on Desktop, occupies remainder md:5) */}
        <div className={`md:col-span-5 h-[830px] flex flex-col justify-between p-4 md:p-2 select-none ${viewFramed ? '' : 'hidden'}`}>
          <div className="space-y-4">
            
            {/* Title / Identity */}
            <div className="flex justify-between items-start">
              <div className="space-y-1">
                <span className="font-mono text-[9px] font-bold text-indigo-700 bg-indigo-50 border border-indigo-100 px-2 py-0.5 rounded-full uppercase tracking-wider leading-none">
                  MVP EXPERIMENT v2.0
                </span>
                <h2 className="text-[#0A0A0A] text-xl font-bold tracking-tight">
                  Tempo 智能实验沙盒
                </h2>
                <p className="text-zinc-500 text-[11px] leading-relaxed">
                  基于 OPC 实验方法重设。在此可同步思源笔记，亦可追踪五个硬核致命假设评分。
                </p>
              </div>
              <button 
                type="button"
                onClick={() => {
                  setOnboardingStep(0);
                  addLog("重新开启 MVP 体验向导手册");
                }}
                className="px-2.5 py-1 text-[10px] font-bold bg-[#0A0A0A] hover:bg-[#1A1A1C] text-white border-none rounded-md cursor-pointer flex items-center gap-1 shrink-0"
              >
                💡 重开引导
              </button>
            </div>

            {/* Quick configuration selector */}
            <div className="grid grid-cols-2 gap-1.5 p-0.5 bg-zinc-50 rounded-lg border border-zinc-200 text-[11px]">
              <button 
                type="button"
                onClick={() => {
                  setViewFramed(true);
                  addLog("已切断至 iPhone 仿真模型");
                }}
                className={`flex items-center justify-center gap-1.5 py-1.5 font-bold rounded-md bg-transparent border-none transition-all cursor-pointer ${viewFramed ? 'bg-white! text-[#0a0a0a] shadow-sm font-semibold' : 'text-zinc-500 bg-transparent border-none'}`}
              >
                <Smartphone className="w-3 h-3" /> 仿真手机框
              </button>
              <button 
                type="button"
                onClick={() => {
                  setViewFramed(false);
                  addLog("已切断至平面自适应排版");
                }}
                className={`flex items-center justify-center gap-1.5 py-1.5 font-bold rounded-md bg-transparent border-none transition-all cursor-pointer ${!viewFramed ? 'bg-white! text-[#0a0a0a] shadow-sm font-semibold' : 'text-zinc-500 bg-transparent border-none'}`}
              >
                <Monitor className="w-3 h-3" /> 宽版大屏契合
              </button>
            </div>

            {/* MVP WORKSPACE SECTOR */}
            <div className="bg-white rounded-xl border border-zinc-200 shadow-sm flex flex-col h-[400px] overflow-hidden">
              
              {/* Tab Selector */}
              <div className="flex border-b border-zinc-200 bg-zinc-50/50">
                <button 
                  type="button"
                  onClick={() => {
                    setRightPanelTab('simulator');
                    addLog("查阅: 思源中文笔记实时模拟输入");
                  }}
                  className={`flex-1 flex items-center justify-center gap-1 ps-2 pe-1.5 py-2.5 text-xs font-bold border-r border-b border-t-0 border-l-0 border-zinc-200 bg-transparent transition-colors cursor-pointer ${rightPanelTab === 'simulator' ? 'bg-white text-black border-b-transparent!' : 'text-zinc-500 hover:text-zinc-800'}`}
                >
                  <Link className="w-3.5 h-3.5 text-amber-500" /> 思源记事同步
                </button>
                <button 
                  type="button"
                  onClick={() => {
                    setRightPanelTab('hypotheses');
                    addLog("查阅: v2.0 MVP 实验假设指标中心");
                  }}
                  className={`flex-1 flex items-center justify-center gap-1 ps-2 pe-1.5 py-2.5 text-xs font-bold border-r border-b border-t-0 border-l-0 border-zinc-200 bg-transparent transition-colors cursor-pointer ${rightPanelTab === 'hypotheses' ? 'bg-white text-black border-b-transparent!' : 'text-zinc-500 hover:text-zinc-800'}`}
                >
                  <ClipboardList className="w-3.5 h-3.5 text-indigo-500" /> 致命假设追踪
                </button>
                <button 
                  type="button"
                  onClick={() => {
                    setRightPanelTab('scope');
                    addLog("查阅: MVP v2.0 骨架削减与研发细节");
                  }}
                  className={`flex-1 flex items-center justify-center gap-1 ps-2 pe-1.5 py-2.5 text-xs font-bold border-b border-t-0 border-r-0 border-l-0 border-zinc-200 bg-transparent transition-colors cursor-pointer ${rightPanelTab === 'scope' ? 'bg-white text-black border-b-transparent!' : 'text-zinc-500 hover:text-zinc-800'}`}
                >
                  <Info className="w-3.5 h-3.5 text-zinc-500" /> 裁剪清单
                </button>
              </div>

              {/* Tab Outputs Content */}
              <div className="flex-1 overflow-y-auto p-4 no-scrollbar">
                {rightPanelTab === 'simulator' && (
                  <div className="space-y-3.5 h-full flex flex-col justify-between">
                    <div className="space-y-1.5">
                      <div className="flex items-center justify-between">
                        <span className="text-[10px] uppercase font-bold text-zinc-400 tracking-wider font-mono">
                          思源本地草稿 Markdown (可编辑内容)
                        </span>
                        <span className="text-[9px] font-mono text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded border border-amber-100">
                          连接开启: localhost:6806
                        </span>
                      </div>
                      <textarea 
                        className="w-full h-[220px] font-mono text-xs p-3 bg-zinc-50 rounded-lg border border-zinc-200 focus:outline-none focus:border-amber-400/80 resize-none text-zinc-800 leading-relaxed shadow-inner"
                        value={siyuanMarkdown}
                        onChange={(e) => setSiyuanMarkdown(e.target.value)}
                        placeholder="在此输入带有☐的 Markdown 笔记，一键同步拉取..."
                      />
                    </div>

                    <button 
                      type="button"
                      onClick={handleImportFromSiyuan}
                      className="w-full py-3 bg-[#D97706] hover:bg-[#B45309] text-white font-semibold text-xs rounded-lg transition-all transform active:scale-[0.98] shadow-sm flex items-center justify-center gap-2 cursor-pointer border-none"
                    >
                      <span>🔌 一键同步抓取未同步 (单向联动 Phase 1)</span>
                    </button>
                  </div>
                )}

                {rightPanelTab === 'hypotheses' && (
                  <div className="space-y-4">
                    {/* H1-H3 Hypotheses tracking list */}
                    <div className="space-y-2.5">
                      <span className="text-[10px] uppercase font-mono font-bold text-zinc-400 block tracking-wider">
                        OPC 核心假设验证分值
                      </span>
                      
                      <div className="space-y-2 text-[11px]">
                        {/* H1 */}
                        <div className="p-2.5 bg-zinc-50 rounded-lg border border-zinc-200 space-y-1.5">
                          <div className="flex justify-between items-center font-sans">
                            <span className="font-semibold text-zinc-800">H1: AI时间轴排期采纳痛点价值</span>
                            <span className="font-mono text-[10px] text-indigo-700 bg-indigo-50 px-1 rounded font-bold">
                              {h1Score}% (验证中)
                            </span>
                          </div>
                          <div className="w-full bg-zinc-200 h-1.5 rounded-full overflow-hidden">
                            <div className="bg-indigo-650 h-full transition-all duration-550" style={{ width: `${h1Score}%` }} />
                          </div>
                          <span className="text-[9px] text-zinc-500 leading-tight block">
                            *验证方式: 在计划页中点击“重新进行精力排期”时可增涨验证分。
                          </span>
                        </div>

                        {/* H2 */}
                        <div className="p-2.5 bg-zinc-50 rounded-lg border border-zinc-200 space-y-1.5">
                          <div className="flex justify-between items-center font-sans">
                            <span className="font-semibold text-zinc-800">H2: 用户愿意为独立 App 留存度</span>
                            <span className="font-mono text-[10px] text-emerald-700 bg-emerald-50 px-1 rounded font-bold">
                              {h2Score}% (验证稳定)
                            </span>
                          </div>
                          <div className="w-full bg-zinc-200 h-1.5 rounded-full overflow-hidden">
                            <div className="bg-emerald-600 h-full transition-all duration-550" style={{ width: `${h2Score}%` }} />
                          </div>
                          <span className="text-[9px] text-zinc-500 leading-tight block">
                            *验证方式: 导入思源笔记项或勾选任务状态时可上涨体验留存。
                          </span>
                        </div>

                        {/* H3 */}
                        <div className="p-2.5 bg-zinc-50 rounded-lg border border-zinc-200 space-y-2">
                          <div className="flex justify-between items-center font-sans">
                            <div className="flex flex-col">
                              <span className="font-semibold text-zinc-800 font-sans">H3: LLM 排期质量多维打分</span>
                              <span className="text-[8px] text-zinc-500 font-sans">
                                Phase 0 Benchmark 评分验证节点
                              </span>
                            </div>
                            <span className="font-mono text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-100 px-1.5 py-0.5 rounded">
                              ⭐ {h3Score} / 5.0
                            </span>
                          </div>
                          
                          {/* Rating interactable */}
                          <div className="flex items-center gap-2">
                            <span className="text-[9px] text-zinc-500 font-bold block shrink-0 font-sans">对此排期评分打分:</span>
                            <div className="flex gap-1">
                              {[1, 2, 3, 4, 5].map((starIdx) => (
                                <button 
                                  type="button"
                                  key={starIdx}
                                  onClick={() => {
                                    setH3Score(starIdx);
                                    addLog(`[H3 Benchmark] 您递交了 ${starIdx}.0 星评测以支持 LLM 数据校准`, 'system');
                                    triggerNotification(`评定星级已更新为 ${starIdx} 星`);
                                  }}
                                  className="p-0 border-none bg-transparent cursor-pointer hover:scale-115 transition-transform"
                                >
                                  <Star className={`w-4 h-4 ${starIdx <= h3Score ? 'fill-amber-450 text-amber-500' : 'text-zinc-300'}`} />
                                </button>
                              ))}
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Feedback Form Sub-module */}
                    <div className="space-y-2 pt-2 border-t border-zinc-200">
                      <span className="text-[10px] uppercase font-mono font-bold text-zinc-400 block tracking-wider font-sans">
                        MVP 缺点/Qualitative 建议收集
                      </span>
                      
                      <form onSubmit={handleSubmitFeedback} className="flex gap-2">
                        <input 
                          type="text"
                          className="flex-1 bg-zinc-50 text-[11px] p-2.5 border border-zinc-200 rounded-lg italic text-zinc-800 focus:outline-none focus:border-indigo-400 font-sans"
                          placeholder="写下对 MVP 排期体验的缺陷或评语..."
                          value={feedbackInput}
                          onChange={(e) => setFeedbackInput(e.target.value)}
                        />
                        <button 
                          type="submit"
                          className="px-3 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg cursor-pointer border-none flex items-center justify-center shrink-0"
                        >
                          <Send className="w-3.5 h-3.5" />
                        </button>
                      </form>

                      {/* feedback log list */}
                      <div className="space-y-1 max-h-[90px] overflow-y-auto no-scrollbar pt-1">
                        {feedbackList.map((feedback, idx) => (
                          <div key={idx} className="bg-zinc-50 p-2 rounded border border-zinc-150 flex items-start gap-1.5 text-[10px]">
                            <span className="font-mono text-zinc-450 pt-0.5 shrink-0">{feedback.time}</span>
                            <span className="text-zinc-700 leading-relaxed font-sans">{feedback.text}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                )}

                {rightPanelTab === 'scope' && (
                  <div className="space-y-4 text-xs text-zinc-700 leading-relaxed font-sans">
                    <div>
                      <h4 className="font-bold text-[#0A0A0A] mb-1 flex items-center gap-1">
                        <span className="text-emerald-700 font-bold bg-emerald-50 px-1.5 py-0.2 rounded font-mono">Phase 1 P0</span> 
                        当前已落地 MVP 骨干
                      </h4>
                      <ul className="space-y-1.5 ps-3.5 list-disc text-zinc-650">
                        <li><b>基础待办管理</b>：优先级设置、状态切换与 5 秒黄金 Undo 撤回</li>
                        <li><b>过滤器分类芯片</b>：今天、周视图、已过期及自定义多项键键联动</li>
                        <li><b>思源单向同步引擎</b>：通过 Petal 同步插件实时拉取 ☐ 并赋予 <code>custom-tempo-id</code></li>
                        <li><b>3 屏 Onboarding 手册</b>：首次载入体验即时，支持重度指引</li>
                        <li><b>意见意见反馈渠道</b>：融入 H2-H5 致命假设前置闭环验证</li>
                      </ul>
                    </div>

                    <div className="pt-2 border-t border-zinc-200">
                      <h4 className="font-bold text-zinc-500 mb-1 flex items-center gap-1">
                        <span className="text-amber-700 font-bold bg-amber-50 px-1.5 py-0.2 rounded font-mono">Phase 2+</span> 
                        已安全砍掉延迟模块 (防过载)
                      </h4>
                      <ul className="space-y-1.5 ps-3.5 list-disc text-zinc-400">
                        <li><b>AI 智能自动排期分段</b>：延迟到 Phase 2（仅保留计划页预览并关联打分，防写代码验证不通过）</li>
                        <li><b>火山引擎 ASR 语音支持</b>：延迟到 Phase 2（只在用户习惯和留存通过后投资）</li>
                        <li><b>系统日历拖拽与日时轴</b>：延迟到 Phase 2</li>
                        <li><b>思源双向同步反写</b>：延迟到 Phase 3 阶段</li>
                      </ul>
                    </div>
                  </div>
                )}
              </div>
            </div>

          </div>

          {/* REAL TIME CONSOLE WORKSPACE */}
          <div className="p-4 bg-zinc-950 border border-zinc-900 text-zinc-100 rounded-xl font-mono text-[11px] space-y-3 shadow-xl shrink-0">
            <div className="flex items-center justify-between border-b border-zinc-800 pb-2">
              <span className="flex items-center gap-1.5 text-zinc-400 uppercase font-semibold text-[10px]">
                <Terminal className="w-3.5 h-3.5 text-amber-500 animate-pulse" /> Tempo Logger
              </span>
              <span className="text-zinc-500 text-[9px] font-semibold uppercase">
                Real-Time Diagnostics
              </span>
            </div>

            <div className="space-y-1.5 max-h-[140px] overflow-y-auto no-scrollbar scroll-smooth">
              {simLogs.map((log, idx) => (
                <div key={idx} className="flex gap-2">
                  <span className="text-zinc-500 select-none">{log.time}</span>
                  <span className={log.type === 'system' ? 'text-amber-400/90' : 'text-zinc-300'}>
                    {log.msg}
                  </span>
                </div>
              ))}
            </div>
            
            <div className="text-[10px] text-zinc-500 text-center border-t border-zinc-900 pt-2 select-none leading-none">
              和原型进行交互、打分或提交反馈时，上方日志会同步打印
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
