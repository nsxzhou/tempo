import React, { useState, useMemo } from 'react';
import { Search, Mic, Plus, Link2, Check, AlertCircle, Sparkles, ChevronRight } from 'lucide-react';
import { Task } from '../types';
import { motion, AnimatePresence } from 'motion/react';

interface TasksViewProps {
  tasks: Task[];
  onToggleTask: (id: string) => void;
  onSelectTask: (task: Task) => void;
  onOpenVoice: () => void;
  onAddTaskQuick: () => void;
  onAddTaskParsed?: (task: Task) => void;
  onUpdateTask?: (task: Task) => void;
}

type FilterType = 'today' | 'week' | 'overdue' | 'all' | 'work' | 'life' | 'product';

export default function TasksView({
  tasks,
  onToggleTask,
  onSelectTask,
  onOpenVoice,
  onAddTaskQuick,
  onAddTaskParsed,
  onUpdateTask
}: TasksViewProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [activeFilter, setActiveFilter] = useState<FilterType>('today');

  // Inline Composer States
  const [showComposer, setShowComposer] = useState(false);
  const [composeTitle, setComposeTitle] = useState('');
  const [composePriority, setComposePriority] = useState<'p0' | 'p1' | 'p2' | 'p3'>('p1');
  const [composeTag, setComposeTag] = useState('工作');
  const [composeDeadline, setComposeDeadline] = useState('今天 18:00');

  // Inline expanded subtasks
  const [expandedTaskIds, setExpandedTaskIds] = useState<Record<string, boolean>>({});

  // Stats calculation
  const stats = useMemo(() => {
    const todayTasks = tasks.filter(t => !t.completed);
    const completedTasks = tasks.filter(t => t.completed);
    const overdueTasks = tasks.filter(t => t.overdue && !t.completed);
    
    return {
      pending: todayTasks.length,
      completed: completedTasks.length,
      overdue: overdueTasks.length
    };
  }, [tasks]);

  // Categories helper
  const filteredTasks = useMemo(() => {
    let result = tasks;

    // Search query
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      result = result.filter(t => t.title.toLowerCase().includes(query) || (t.description && t.description.toLowerCase().includes(query)));
    }

    // Secondary category tabs filter
    if (activeFilter === 'today') {
      result = result.filter(t => !t.completed || t.deadline.includes('今天') || t.deadline.includes('已完成'));
    } else if (activeFilter === 'week') {
      result = result.filter(t => t.deadline.includes('本周') || t.deadline.includes('明天') || t.deadline.includes('今天'));
    } else if (activeFilter === 'overdue') {
      result = result.filter(t => t.overdue && !t.completed);
    } else if (activeFilter === 'work') {
      result = result.filter(t => t.tag === '工作' || t.tag === '产品');
    } else if (activeFilter === 'life') {
      result = result.filter(t => t.tag === '生活' || t.tag === '阅读');
    } else if (activeFilter === 'product') {
      result = result.filter(t => t.tag === '产品');
    }

    return result;
  }, [tasks, activeFilter, searchQuery]);

  // Separate active & completed items
  const activeItems = useMemo(() => filteredTasks.filter(t => !t.completed), [filteredTasks]);
  const completedItems = useMemo(() => filteredTasks.filter(t => t.completed), [filteredTasks]);

  // Quick category tag filter triggers
  const handleTagClick = (tag: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const tagLower = tag.toLowerCase();
    if (tagLower === '工作' || tagLower === '@工作') setActiveFilter('work');
    else if (tagLower === '生活' || tagLower === '@生活') setActiveFilter('life');
    else if (tagLower === '产品' || tagLower === '@产品') setActiveFilter('product');
  };

  // Inline Subtasks expansion toggler
  const toggleExpandTask = (taskId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setExpandedTaskIds(prev => ({
      ...prev,
      [taskId]: !prev[taskId]
    }));
  };

  // Submit custom created task
  const handleComposeSubmit = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!composeTitle.trim()) return;

    if (onAddTaskParsed) {
      const newTask: Task = {
        id: `custom-${Date.now()}`,
        title: composeTitle.trim(),
        priority: composePriority,
        deadline: composeDeadline,
        tag: composeTag,
        completed: false,
        overdue: false,
        description: '这是您在今天待办面板中手动快捷建立的全新工作项。完美符合今日效率。',
        siyuanLink: null,
        subtasks: [],
        estimate: '30m',
        allocatedTime: '待重新进行精力排期',
        energyMatch: '智能排期中'
      };
      onAddTaskParsed(newTask);
      setComposeTitle('');
      setShowComposer(false);
    } else {
      // Fallback
      onAddTaskQuick();
    }
  };

  return (
    <div id="view-tasks" className="w-full h-full relative font-sans">
      <div className="absolute inset-0 overflow-y-auto no-scrollbar pt-[44px] pb-[72px]">
        
        {/* Page Header */}
        <div className="px-5 pt-4 pb-3 flex items-end justify-between gap-3">
          <div>
            <h1 className="text-[32px] font-bold tracking-tight text-[#0A0A0A] leading-none">TODO</h1>
            <div className="font-mono text-xs text-[#71717A] mt-1.5 tracking-tight">6 月 17 日 · 周二</div>
          </div>
          <button 
            id="search-btn"
            onClick={() => setShowSearch(!showSearch)}
            className={`w-8 h-8 rounded-md border flex items-center justify-center text-[#18181B] transition-all duration-150 ${showSearch ? 'border-[#0A0A0A] bg-[#FAFAFA]' : 'border-[#E4E4E7] hover:border-[#D4D4D8]'}`}
            aria-label="搜索"
          >
            <Search className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Search input animated */}
        <AnimatePresence>
          {showSearch && (
            <motion.div 
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="px-5 overflow-hidden"
            >
              <div className="relative mb-3.5">
                <input
                  type="text"
                  placeholder="检索日常任务或内容..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full text-sm py-2 pl-9 pr-4 rounded-lg bg-[#F4F4F5] border border-transparent focus:border-[#0A0A0A] outline-none transition-all duration-150 text-[#0A0A0A] placeholder-[#A1A1AA]"
                />
                <Search className="absolute left-3 top-2.5 w-3.5 h-3.5 text-[#A1A1AA]" />
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Integrated interactive Bento Filter Grid */}
        <div className="px-5 mb-5 select-none animate-fade-in">
          <div className="grid grid-cols-2 gap-3">
            {/* Card 1: Today pending tasks */}
            <div 
              onClick={() => setActiveFilter('today')} 
              className={`p-4 rounded-2xl border transition-all duration-150 cursor-pointer flex flex-col justify-between h-[96px] ${
                activeFilter === 'today' 
                  ? 'bg-[#0a0a0a] border-[#0a0a0a] text-white shadow-xs' 
                  : 'bg-white border-[#E4E4E7] hover:border-zinc-400 text-[#0a0a0a] shadow-3xs'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-[10px] uppercase font-bold tracking-wider ${activeFilter === 'today' ? 'text-zinc-400' : 'text-[#71717A]'}`}>
                  今日待办
                </span>
                <span className="w-1.5 h-1.5 rounded-full bg-indigo-500" />
              </div>
              <div className="flex items-baseline justify-between mt-auto">
                <span className="font-mono text-2xl font-bold tracking-tight">
                  {tasks.filter(t => !t.completed).length}
                </span>
                <span className={`text-[10px] font-bold ${activeFilter === 'today' ? 'text-zinc-400' : 'text-[#71717A]'}`}>
                  项未完成
                </span>
              </div>
            </div>

            {/* Card 2: Overdue tasks */}
            <div 
              onClick={() => setActiveFilter('overdue')} 
              className={`p-4 rounded-2xl border transition-all duration-150 cursor-pointer flex flex-col justify-between h-[96px] ${
                activeFilter === 'overdue' 
                  ? 'bg-red-950 border-red-900 text-red-100 shadow-xs' 
                  : stats.overdue > 0 
                    ? 'bg-red-50/50 border-red-200 text-red-700 hover:border-red-300' 
                    : 'bg-white border-[#E4E4E7] hover:border-zinc-400 text-zinc-750'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-[10px] uppercase font-bold tracking-wider ${activeFilter === 'overdue' ? 'text-red-300' : 'text-[#71717A]'}`}>
                  已过期
                </span>
                {stats.overdue > 0 && <span className="w-1.5 h-1.5 rounded-full bg-red-600 animate-pulse" />}
              </div>
              <div className="flex items-baseline justify-between mt-auto">
                <span className={`font-mono text-2xl font-bold tracking-tight ${stats.overdue > 0 && activeFilter !== 'overdue' ? 'text-red-650' : ''}`}>
                  {stats.overdue}
                </span>
                <span className="text-[10px] font-bold opacity-80">
                  项超期
                </span>
              </div>
            </div>

            {/* Card 3: Week arrange */}
            <div 
              onClick={() => setActiveFilter('week')} 
              className={`p-4 rounded-2xl border transition-all duration-150 cursor-pointer flex flex-col justify-between h-[96px] ${
                activeFilter === 'week' 
                  ? 'bg-[#0a0a0a] border-[#0a0a0a] text-white shadow-xs' 
                  : 'bg-white border-[#E4E4E7] hover:border-zinc-400 text-[#0a0a0a] shadow-3xs'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-[10px] uppercase font-bold tracking-wider ${activeFilter === 'week' ? 'text-zinc-400' : 'text-[#71717A]'}`}>
                  本周安排
                </span>
                <span className="w-1.5 h-1.5 rounded-full bg-zinc-300" />
              </div>
              <div className="flex items-baseline justify-between mt-auto">
                <span className="font-mono text-2xl font-bold tracking-tight">
                  {tasks.length}
                </span>
                <span className={`text-[10px] font-bold ${activeFilter === 'week' ? 'text-zinc-400' : 'text-[#71717A]'}`}>
                  项总代办
                </span>
              </div>
            </div>

            {/* Card 4: All completed tasks */}
            <div 
              onClick={() => setActiveFilter('all')} 
              className={`p-4 rounded-2xl border transition-all duration-150 cursor-pointer flex flex-col justify-between h-[96px] ${
                activeFilter === 'all' 
                  ? 'bg-[#0a0a0a] border-[#0a0a0a] text-white shadow-xs' 
                  : 'bg-white border-[#E4E4E7] hover:border-zinc-400 text-[#0a0a0a] shadow-3xs'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-[10px] uppercase font-bold tracking-wider ${activeFilter === 'all' ? 'text-zinc-400' : 'text-[#71717A]'}`}>
                  全部任务
                </span>
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              </div>
              <div className="flex items-baseline justify-between mt-auto">
                <span className="font-mono text-2xl font-bold tracking-tight">
                  {tasks.filter(t => t.completed).length}
                </span>
                <span className={`text-[10px] font-bold ${activeFilter === 'all' ? 'text-zinc-400' : 'text-[#71717A]'}`}>
                  项已完成
                </span>
              </div>
            </div>
          </div>

          {/* Solid segmented controller for Work vs Life classifications */}
          <div className="flex gap-2.5 mt-4 p-1 rounded-xl bg-[#F4F4F5] border border-zinc-200/60 font-sans shadow-3xs">
            <button
              type="button"
              onClick={() => setActiveFilter('work')}
              className={`flex-1 py-1.5 text-xs font-bold rounded-lg transition-all duration-100 cursor-pointer flex items-center justify-center gap-1 ${
                activeFilter === 'work'
                  ? 'bg-white text-[#0a0a0a] shadow-2xs border border-zinc-250/50'
                  : 'text-[#52525B] hover:text-[#0a0a0a]'
              }`}
            >
              <span>💻 工作分类</span>
              <span className={`text-[9px] font-mono px-1 rounded-full ${activeFilter === 'work' ? 'bg-black/5' : 'bg-black/[0.03]'}`}>
                {tasks.filter(t => t.tag === '工作' || t.tag === '产品').length}
              </span>
            </button>
            <button
              type="button"
              onClick={() => setActiveFilter('life')}
              className={`flex-1 py-1.5 text-xs font-bold rounded-lg transition-all duration-100 cursor-pointer flex items-center justify-center gap-1 ${
                activeFilter === 'life'
                  ? 'bg-white text-[#0a0a0a] shadow-2xs border border-zinc-250/50'
                  : 'text-[#52525B] hover:text-[#0a0a0a]'
              }`}
            >
              <span>🌿 生活分类</span>
              <span className={`text-[9px] font-mono px-1 rounded-full ${activeFilter === 'life' ? 'bg-black/5' : 'bg-black/[0.03]'}`}>
                {tasks.filter(t => t.tag === '生活' || t.tag === '阅读').length}
              </span>
            </button>
          </div>
        </div>

        {/* Inline Task Composer Toggler Placeholder */}
        {!showComposer && (
          <div className="px-5 mb-4">
            <button
              onClick={() => {
                setShowComposer(true);
                setComposeTitle('');
              }}
              className="w-full py-2.5 px-3.5 rounded-lg border border-dashed border-[#E4E4E7] hover:border-zinc-400 text-left text-xs text-[#71717A] bg-zinc-50/40 hover:bg-white transition-all cursor-pointer flex items-center justify-between group"
            >
              <div className="flex items-center gap-2">
                <Plus className="w-3.5 h-3.5 text-zinc-400 group-hover:text-black transition-colors" />
                <span>在此处添加拟定待办...</span>
              </div>
              <span className="text-[9px] bg-zinc-100 text-zinc-500 px-1.5 py-0.5 rounded font-mono group-hover:bg-black group-hover:text-white transition-colors">
                Enter
              </span>
            </button>
          </div>
        )}

        {/* Inline Composer Block */}
        <AnimatePresence>
          {showComposer && (
            <motion.div
              initial={{ opacity: 0, height: 0, marginBottom: 0 }}
              animate={{ opacity: 1, height: 'auto', marginBottom: 16 }}
              exit={{ opacity: 0, height: 0, marginBottom: 0 }}
              className="px-5 overflow-hidden"
            >
              <form 
                onSubmit={handleComposeSubmit} 
                className="p-4 border border-[#0A0A0A] rounded-lg bg-white shadow-md space-y-3.5"
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-bold text-[#0A0A0A] uppercase tracking-wider flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-amber-500" /> 拟定全新待办
                  </span>
                  <button 
                    type="button"
                    onClick={() => setShowComposer(false)}
                    className="text-xs hover:text-zinc-500 text-zinc-400 font-semibold cursor-pointer"
                  >
                    取消
                  </button>
                </div>

                <div className="space-y-1">
                  <input 
                    type="text"
                    required
                    autoFocus
                    placeholder="例如: 编写第三季度设计系统文档..."
                    value={composeTitle}
                    onChange={(e) => setComposeTitle(e.target.value)}
                    className="w-full text-sm font-medium py-1 text-black bg-transparent border-b border-zinc-200 focus:border-black outline-none transition-colors placeholder-[#A1A1AA]"
                  />
                </div>

                {/* Meta details switches */}
                <div className="grid grid-cols-2 gap-3.5 py-1 text-[11px]">
                  
                  {/* Priority select */}
                  <div className="space-y-1">
                    <label className="text-[10px] text-zinc-500 block font-semibold">优先级</label>
                    <div className="flex gap-1.5">
                      {(['p0', 'p1', 'p2', 'p3'] as const).map((p) => (
                        <button
                          key={p}
                          type="button"
                          onClick={() => setComposePriority(p)}
                          className={`px-2 py-0.5 rounded text-[10px] font-bold border transition-all cursor-pointer ${
                            composePriority === p 
                              ? p === 'p0' ? 'text-red-700 bg-red-100 border-red-300' :
                                p === 'p1' ? 'text-amber-700 bg-amber-100 border-amber-300' :
                                p === 'p2' ? 'text-blue-700 bg-blue-100 border-blue-300' :
                                'text-[#71717A] bg-zinc-200 border-zinc-300'
                              : 'text-zinc-400 border-zinc-200 bg-transparent hover:border-zinc-300'
                          }`}
                        >
                          {p.toUpperCase()}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Tag Category select */}
                  <div className="space-y-1">
                    <label className="text-[10px] text-zinc-500 block font-semibold">分类标签</label>
                    <div className="flex gap-1.5">
                      {['工作', '生活', '产品'].map((t) => (
                        <button
                          key={t}
                          type="button"
                          onClick={() => setComposeTag(t)}
                          className={`px-2 py-0.5 rounded text-[10px] font-semibold border transition-all cursor-pointer ${
                            composeTag === t 
                              ? 'text-black bg-zinc-100 border-black' 
                              : 'text-zinc-400 border-zinc-200 bg-transparent hover:border-zinc-300'
                          }`}
                        >
                          @{t}
                        </button>
                      ))}
                    </div>
                  </div>

                </div>

                {/* Row: Deadline input & Submit button */}
                <div className="flex items-center justify-between border-t border-zinc-105 pt-3">
                  <div className="flex items-center gap-1.5 text-[11px] text-zinc-500">
                    <span className="font-semibold select-none">截止日期:</span>
                    <input 
                      type="text"
                      value={composeDeadline}
                      onChange={(e) => setComposeDeadline(e.target.value)}
                      className="font-mono text-[11px] text-black w-24 border-none bg-transparent outline-none focus:ring-0 p-0"
                    />
                  </div>

                  <button 
                    type="submit"
                    className="px-3.5 py-1.5 bg-[#0a0a0a] text-white rounded text-xs font-semibold cursor-pointer hover:bg-zinc-800 transition-colors flex items-center gap-1"
                  >
                    确认创建
                  </button>
                </div>
              </form>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Pending Task List */}
        <div className="text-[10px] font-semibold text-[#71717A] tracking-wider uppercase px-5 py-2.5 flex items-center gap-2 select-none">
          待办 · {activeItems.length}
          <div className="flex-1 h-[1px] bg-[#E4E4E7]" />
        </div>
        
        <div className="px-5 space-y-2">
          <AnimatePresence initial={false}>
            {activeItems.map((item) => {
              const checkedSubCount = item.subtasks.filter(sub => sub.completed).length;
              const totalSubCount = item.subtasks.length;
              const isExpanded = !!expandedTaskIds[item.id];
              
              return (
                <motion.div
                  key={item.id}
                  layoutId={`task-${item.id}`}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  transition={{ duration: 0.2 }}
                  onClick={() => onSelectTask(item)}
                  className={`flex items-start gap-3 p-3.5 border rounded-lg bg-white hover:border-[#A1A1AA] transition-all duration-200 cursor-pointer shadow-sm relative group`}
                >
                  {/* Custom Checkbox wrapper (Anti-misclick armor with 34px hitzone) */}
                  <div 
                    onClick={(e) => {
                      e.stopPropagation();
                      onToggleTask(item.id);
                    }}
                    className="p-2.5 -m-2.5 mr-0.5 shrink-0 select-none cursor-pointer z-10 flex items-center justify-center group/check"
                    title="标记为完成"
                  >
                    <div 
                      className={`w-[18px] h-[18px] rounded-full border flex items-center justify-center bg-white transition-all duration-200 ${item.completed ? 'bg-[#0A0A0A] border-[#0A0A0A]' : 'border-[#D4D4D8] group-hover/check:border-[#0A0A0A] hover:scale-105 active:scale-90'}`}
                    >
                      <Check className={`w-2.5 h-2.5 text-white stroke-[3] transition-all duration-200 ${item.completed ? 'scale-100 opacity-100' : 'scale-50 opacity-0'}`} />
                    </div>
                  </div>

                  {/* Task Content */}
                  <div className="flex-1 min-w-0 pr-1 select-none">
                    <p className="text-sm font-medium text-[#0A0A0A] line-clamp-1 group-hover:text-black leading-snug">
                      {item.title}
                    </p>
                    <div className="flex items-center gap-1.5 mt-2 flex-wrap text-[10px] font-medium font-sans">
                      <span className={`px-1.5 py-0.5 rounded-full border text-[10px] select-none ${
                        item.priority === 'p0' ? 'text-red-700 bg-red-50 border-red-200' :
                        item.priority === 'p1' ? 'text-amber-700 bg-amber-50 border-amber-200' :
                        item.priority === 'p2' ? 'text-blue-700 bg-blue-50 border-blue-200' :
                        'text-[#71717A] bg-[#F4F4F5] border-[#E4E4E7]'
                      }`}>
                        {item.priority.toUpperCase()}
                      </span>
                      {item.overdue ? (
                        <span className="px-1.5 py-0.5 rounded-full border text-red-600 bg-red-50 border-red-200 flex items-center gap-0.5">
                          <AlertCircle className="w-2.5 h-2.5" /> 已过期
                        </span>
                      ) : (
                        <span className="px-1.5 py-0.5 rounded-full border text-[#71717A] bg-transparent border-[#E4E4E7]">
                          {item.deadline}
                        </span>
                      )}
                      
                      {/* Active Tag with hover ring & quick filter callback */}
                      <span 
                        onClick={(e) => handleTagClick(item.tag, e)}
                        className="px-1.5 py-0.5 rounded-full bg-[#F4F4F5] border border-[#E4E4E7] text-[#71717A] hover:bg-[#E4E4E7] hover:text-black hover:border-zinc-400 transition-colors pointer-events-auto"
                      >
                        @{item.tag}
                      </span>
                    </div>

                    {/* Inline subtasks accordion checklist */}
                    <AnimatePresence>
                      {totalSubCount > 0 && isExpanded && (
                        <motion.div
                          initial={{ height: 0, opacity: 0, marginTop: 0 }}
                          animate={{ height: 'auto', opacity: 1, marginTop: 12 }}
                          exit={{ height: 0, opacity: 0, marginTop: 0 }}
                          className="overflow-hidden space-y-1.5 pt-2.5 border-t border-zinc-100"
                          onClick={(e) => e.stopPropagation()} // stop parent Detail modal trigger
                        >
                          {item.subtasks.map((sub) => (
                            <div 
                              key={sub.id}
                              onClick={(e) => {
                                e.stopPropagation();
                                if (onUpdateTask) {
                                  const updatedSubtasks = item.subtasks.map(s => s.id === sub.id ? { ...s, completed: !s.completed } : s);
                                  onUpdateTask({ ...item, subtasks: updatedSubtasks });
                                }
                              }}
                              className="flex items-center gap-2 py-1 px-1.5 rounded hover:bg-zinc-50 transition-all cursor-pointer group/sub"
                            >
                              <div className={`w-[14px] h-[14px] rounded-full border flex items-center justify-center shrink-0 transition-colors ${sub.completed ? 'bg-black border-black' : 'border-zinc-300 bg-white group-hover/sub:border-black'}`}>
                                <Check className={`w-1.5 h-1.5 text-white stroke-[4] transition-all duration-150 ${sub.completed ? 'scale-100 opacity-100' : 'scale-50 opacity-0'}`} />
                              </div>
                              <span className={`text-[12px] leading-tight transition-colors ${sub.completed ? 'text-zinc-400 line-through' : 'text-zinc-600'}`}>
                                {sub.title}
                              </span>
                            </div>
                          ))}
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>

                  {/* Right Icons: SiYuan / Subtasks count */}
                  <div className="flex items-center gap-1.5 shrink-0 self-center">
                    {/* Expandable subtasks controller badge */}
                    {totalSubCount > 0 && (
                      <button 
                        onClick={(e) => toggleExpandTask(item.id, e)}
                        className={`font-mono text-[10px] rounded px-1.5 py-0.5 flex items-center gap-1 cursor-pointer transition-all border outline-none select-none ${isExpanded ? 'bg-[#0A0A0A] text-white border-black' : 'bg-[#F4F4F5] hover:bg-zinc-150 text-[#18181B] border-[#E4E4E7] hover:border-[#1A1A1A]'}`}
                        title={isExpanded ? "收起子任务" : "展开子任务列表"}
                      >
                        <span>{checkedSubCount}/{totalSubCount}</span>
                        <motion.span
                          animate={{ rotate: isExpanded ? 180 : 0 }}
                          transition={{ duration: 0.15 }}
                          className="inline-block text-[7px]"
                        >
                          ▼
                        </motion.span>
                      </button>
                    )}
                    {item.siyuanLink && (
                      <Link2 className="w-3.5 h-3.5 text-[#71717A] opacity-75 group-hover:text-black cursor-help" />
                    )}
                    <ChevronRight className="w-3 text-zinc-300 group-hover:text-zinc-600 group-hover:translate-x-0.5 transition-all" />
                  </div>
                </motion.div>
              );
            })}
          </AnimatePresence>
        </div>

        {/* Completed Task List */}
        {completedItems.length > 0 && (
          <>
            <div className="text-[10px] font-semibold text-[#A1A1AA] tracking-wider uppercase px-5 py-2.5 mt-4 flex items-center gap-2 select-none">
              已完成 · {completedItems.length}
              <div className="flex-1 h-[1px] bg-[#F4F4F5]" />
            </div>
            
            <div className="px-5 space-y-2">
              <AnimatePresence>
                {completedItems.map((item) => (
                  <motion.div
                    key={item.id}
                    layoutId={`task-${item.id}`}
                    initial={{ opacity: 0.5, y: 0 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    onClick={() => onSelectTask(item)}
                    className="flex items-start gap-3 p-3.5 border border-[#F4F4F5] rounded-lg bg-white opacity-60 hover:opacity-100 hover:border-zinc-300 transition-all duration-200 cursor-pointer shadow-xs relative group"
                  >
                    {/* Checkbox completed with armored click */}
                    <div 
                      onClick={(e) => {
                        e.stopPropagation();
                        onToggleTask(item.id);
                      }}
                      className="p-2.5 -m-2.5 mr-0.5 shrink-0 select-none cursor-pointer z-10 flex items-center justify-center"
                      title="取消勾选完成"
                    >
                      <div className="w-[18px] h-[18px] rounded-full border flex items-center justify-center bg-[#0A0A0A] border-[#0A0A0A] hover:scale-105 active:scale-90 transition-transform">
                        <Check className="w-2.5 h-2.5 text-white stroke-[3]" />
                      </div>
                    </div>

                    <div className="flex-1 min-w-0 pr-1 select-none">
                      <p className="text-sm font-medium text-[#71717A] line-through line-clamp-1 leading-snug">
                        {item.title}
                      </p>
                      <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                        <span className="px-1.5 py-0.5 rounded-full bg-emerald-50 border border-emerald-100 text-emerald-700 text-[10px] font-medium font-sans">
                          已完成
                        </span>
                        <span className="px-1.5 py-0.5 rounded-full bg-[#FAFAFA] border border-zinc-200 text-zinc-400 text-[10px]">
                          {item.tag}
                        </span>
                      </div>
                    </div>
                    
                    <ChevronRight className="w-3 text-zinc-300 self-center" />
                  </motion.div>
                ))}
              </AnimatePresence>
            </div>
          </>
        )}

        <div className="h-[100px]" />
      </div>

      {/* Floating Buttons in container */}
      <div className="absolute right-5 bottom-[84px] flex flex-col gap-3.5 z-40">
        <button 
          onClick={onOpenVoice}
          className="w-12 h-12 rounded-lg bg-white border border-[#E4E4E7] flex items-center justify-center text-[#0A0A0A] hover:border-[#A1A1AA] transition-all duration-150 shadow-md transform hover:-translate-y-0.5 active:scale-95 cursor-pointer"
          aria-label="语音录入"
        >
          <Mic className="w-5 h-5" />
        </button>
        <button 
          onClick={() => {
            setShowComposer(true);
            setComposeTitle('');
            // Scroll view automatically to top to view composer
            const viewEl = document.getElementById('view-tasks')?.querySelector('.overflow-y-auto');
            if (viewEl) {
              viewEl.scrollTo({ top: 0, behavior: 'smooth' });
            }
          }}
          className="w-12 h-12 rounded-lg bg-[#0A0A0A] text-white flex items-center justify-center hover:bg-zinc-800 transition-all duration-150 shadow-md transform hover:-translate-y-0.5 active:scale-95 cursor-pointer"
          aria-label="快速创建"
        >
          <Plus className="w-5.5 h-5.5 stroke-[2.5]" />
        </button>
      </div>
    </div>
  );
}
