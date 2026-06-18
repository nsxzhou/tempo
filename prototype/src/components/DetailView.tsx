import { useState, useEffect } from 'react';
import { ChevronLeft, Edit2, MoreVertical, Calendar, Folder, Clock, Sparkles, Check, CheckCircle2, Circle, AlertCircle } from 'lucide-react';
import { Task, SubTask } from '../types';

interface DetailViewProps {
  task: Task;
  onClose: () => void;
  onUpdateTask: (updatedTask: Task) => void;
  onShowBanner: (msg: string) => void;
}

export default function DetailView({ 
  task, 
  onClose, 
  onUpdateTask,
  onShowBanner
}: DetailViewProps) {
  
  const [desc, setDesc] = useState(task.description);
  const [isEditingDesc, setIsEditingDesc] = useState(false);

  // Sync state if task changes
  useEffect(() => {
    setDesc(task.description);
    setIsEditingDesc(false);
  }, [task]);

  const handleSubtaskToggle = (subtaskId: string) => {
    const updatedSubtasks = task.subtasks.map(sub => {
      if (sub.id === subtaskId) {
        return { ...sub, completed: !sub.completed };
      }
      return sub;
    });

    const updatedTask = {
      ...task,
      subtasks: updatedSubtasks
    };
    
    // We also automatically flip total completed parameter under certain conditions,
    // but usually we just update state and notify parent component
    onUpdateTask(updatedTask);
    
    // Toast notification
    const totalCount = updatedSubtasks.length;
    const completedCount = updatedSubtasks.filter(s => s.completed).length;
    onShowBanner(`子任务状态已更新 (${completedCount}/${totalCount})`);
  };

  const handleSaveDescription = () => {
    const updatedTask = {
      ...task,
      description: desc
    };
    onUpdateTask(updatedTask);
    setIsEditingDesc(false);
    onShowBanner("任务备考详情已更新记录");
  };

  const totalSubtasks = task.subtasks.length;
  const completedSubtasks = task.subtasks.filter(sub => sub.completed).length;

  return (
    <div id="view-detail" className="w-full h-full relative bg-white font-sans">
      <div className="absolute inset-0 overflow-y-auto no-scrollbar pt-[44px] pb-5">
        
        {/* Navigation Action Row */}
        <div className="flex items-center justify-between px-4 py-2 bg-white sticky top-0 z-10 border-b border-[#F4F4F5]">
          <button 
            onClick={onClose}
            className="inline-flex items-center gap-1 text-[#18181B] font-medium text-[13px] hover:text-black py-1 px-1 cursor-pointer"
            aria-label="返回"
          >
            <ChevronLeft className="w-4.5 h-4.5 stroke-[2]" /> 返回
          </button>
          
          <div className="flex items-center gap-1.5">
            <button 
              onClick={() => {
                setIsEditingDesc(!isEditingDesc);
                if (isEditingDesc) handleSaveDescription();
              }}
              className="w-8 h-8 rounded-md border border-[#E4E4E7] flex items-center justify-center text-[#18181B] hover:border-[#A1A1AA] transition-all duration-150 cursor-pointer"
              aria-label="快速修改"
            >
              <Edit2 className="w-3.5 h-3.5" />
            </button>
            <button 
              onClick={() => onShowBanner(`更多选项展开中 (Mock)`)}
              className="w-8 h-8 rounded-md border border-[#E4E4E7] flex items-center justify-center text-[#18181B] hover:border-[#A1A1AA] transition-all duration-150 cursor-pointer"
              aria-label="选项"
            >
              <MoreVertical className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Title Content Block */}
        <div className="px-5 pt-4 pb-4">
          <div className="flex items-center gap-2 mb-2.5">
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold border ${
              task.priority === 'p0' ? 'text-red-700 bg-red-50 border-red-200' :
              task.priority === 'p1' ? 'text-amber-700 bg-amber-50 border-amber-200' :
              task.priority === 'p2' ? 'text-blue-700 bg-blue-50 border-blue-200' :
              'text-[#71717A] bg-[#F4F4F5] border-[#E4E4E7]'
            }`}>
              {task.priority.toUpperCase()} 级别
            </span>
            <span className="px-2 py-0.5 rounded bg-zinc-100 text-[#71717A] text-[10px] border border-[#E4E4E7]/60 font-semibold font-sans">
              #{task.tag}
            </span>
          </div>

          <h2 className="text-[32px] font-normal font-serif italic text-[#0A0A0A] leading-[1.1] tracking-tight">
            {task.title}
          </h2>
        </div>

        {/* Properties metadata lists */}
        <div className="border-t border-b border-[#E4E4E7] bg-[#FAFAFA]/40 mb-5">
          
          {/* Deadline field */}
          <div className="flex items-center gap-3 px-5 py-3.5 border-b border-[#F4F4F5]/85">
            <Calendar className="w-3.5 h-3.5 text-[#71717A] shrink-0" />
            <span className="text-[11px] font-semibold text-[#71717A] uppercase tracking-wider w-12 select-none">截止</span>
            <div className="flex-1 flex items-center justify-between text-sm text-[#0A0A0A]">
              <span className="font-mono font-medium">{task.deadline.includes('已完成') ? '今天 12:00' : task.deadline}</span>
              {!task.completed && (
                <span className={`text-[10px] px-2 py-0.5 rounded-full font-semibold ${task.overdue ? 'text-red-700 bg-red-50 border border-red-150' : 'text-amber-700 bg-amber-50 border border-amber-150'}`}>
                  {task.overdue ? '已延误' : '即将截止'}
                </span>
              )}
            </div>
          </div>

          {/* List classification */}
          <div className="flex items-center gap-3 px-5 py-3.5 border-b border-[#F4F4F5]/85">
            <Folder className="w-3.5 h-3.5 text-[#71717A] shrink-0" />
            <span className="text-[11px] font-semibold text-[#71717A] uppercase tracking-wider w-12 select-none">归属</span>
            <span className="text-sm font-medium text-[#0A0A0A]">{task.tag === '生活' || task.tag === '阅读' ? '生活与灵感' : '工作项目'}</span>
          </div>

          {/* Expected focus estimate */}
          <div className="flex items-center gap-3 px-5 py-3.5 border-b border-[#F4F4F5]/85">
            <Clock className="w-3.5 h-3.5 text-[#71717A] shrink-0" />
            <span className="text-[11px] font-semibold text-[#71717A] uppercase tracking-wider w-12 select-none">预估</span>
            <span className="text-sm font-semibold text-[#0A0A0A] font-mono">{task.estimate}</span>
          </div>

          {/* Expected AI slots */}
          <div className="flex items-center gap-3 px-5 py-3.5">
            <Sparkles className="w-3.5 h-3.5 text-[#0A0A0A] shrink-0 animate-pulse" />
            <span className="text-[11px] font-semibold text-[#71717A] uppercase tracking-wider w-12 select-none">AI排排程</span>
            <div className="flex-1 flex items-center justify-between text-xs text-[#0A0A0A]">
              <span className="font-mono font-semibold">{task.allocatedTime}</span>
              <span className="font-sans text-[10px] text-[#A1A1AA]">{task.energyMatch}</span>
            </div>
          </div>

        </div>

        {/* Text descriptions editable */}
        <div className="px-5 mb-5.5 select-text">
          {isEditingDesc ? (
            <div className="space-y-2">
              <textarea
                value={desc}
                onChange={(e) => setDesc(e.target.value)}
                rows={3}
                className="w-full text-sm p-3 border border-black rounded-lg outline-none font-sans text-[#0A0A0A] focus:ring-0 leading-relaxed"
                placeholder="键入备考信息或交互重点说明..."
              />
              <div className="flex justify-end gap-2">
                <button 
                  onClick={() => setIsEditingDesc(false)}
                  className="px-3.5 py-1 text-xs font-semibold rounded border border-[#E4E4E7] text-[#71717A]"
                >
                  取消
                </button>
                <button 
                  onClick={handleSaveDescription}
                  className="px-3.5 py-1 text-xs font-semibold rounded bg-[#0A0A0A] text-white"
                >
                  保存
                </button>
              </div>
            </div>
          ) : (
            <div 
              onClick={() => setIsEditingDesc(true)}
              className="text-xs tracking-tight text-[#18181B] bg-zinc-50 border border-[#F4F4F5] rounded-lg p-4 font-sans leading-relaxed cursor-pointer hover:border-zinc-300"
              title="点击可编辑任务备考"
            >
              {task.description ? task.description : <span className="text-[#A1A1AA] italic">无附加任务描述。点击可输入备注...</span>}
            </div>
          )}
        </div>

        {/* Subtask Lists Checklist */}
        {totalSubtasks > 0 && (
          <div className="px-5 mb-5 select-none">
            <div className="flex items-center justify-between text-[10px] font-bold text-[#71717A] tracking-wider uppercase mb-2.5">
              子任务
              <span className="font-mono text-[9px] px-1.5 py-0.5 bg-[#F4F4F5] rounded text-[#71717A]">
                {completedSubtasks}/{totalSubtasks} 已勾选
              </span>
            </div>
            
            <div className="border border-[#E4E4E7] rounded-lg overflow-hidden bg-white shadow-xs">
              {task.subtasks.map((sub) => (
                <div 
                  key={sub.id}
                  onClick={() => handleSubtaskToggle(sub.id)}
                  className="flex items-center gap-3 p-3 border-b last:border-b-0 border-[#F4F4F5] hover:bg-[#FAFAFA]/50 transition-colors duration-100 cursor-pointer"
                >
                  {/* Circle Check toggle */}
                  <div className={`w-[15px] h-[15px] rounded-full border flex items-center justify-center shrink-0 ${sub.completed ? 'bg-black border-black' : 'border-[#D4D4D8] bg-white'}`}>
                    <Check className={`w-2 h-2 text-white stroke-[3.5] ${sub.completed ? 'scale-100' : 'scale-0'}`} />
                  </div>
                  
                  <span className={`text-[12.5px] leading-snug tracking-tight font-medium ${sub.completed ? 'text-[#71717A] line-through' : 'text-[#0A0A0A]'}`}>
                    {sub.title}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Related Note Links (SiYuan Note Integration) */}
        {task.siyuanLink && (
          <div className="px-5 select-none">
            <div className="text-[10px] font-bold text-[#71717A] tracking-wider uppercase mb-2.5">
              思源关联卡片
            </div>
            
            <div 
              onClick={() => onShowBanner(`已在思源本地桌面端成功打开笔记: \n${task.siyuanLink?.title}`)}
              className="flex items-center gap-3 p-3 border border-[#E4E4E7] rounded-lg bg-[#FAFAFA] hover:bg-white hover:border-[#D4D4D8] transition-all duration-150 cursor-pointer shadow-xs"
            >
              <div className="w-7 h-7 rounded bg-amber-50 text-amber-700 border border-amber-200/50 flex items-center justify-center shrink-0">
                <Folder className="w-3.5 h-3.5" />
              </div>
              <div className="flex-1 min-w-0">
                <h4 className="text-[12.5px] font-semibold text-[#0A0A0A] line-clamp-1 leading-snug">
                  {task.siyuanLink.title}
                </h4>
                <p className="font-mono text-[9.5px] text-[#A1A1AA] mt-1.5 leading-none">
                  {task.siyuanLink.url}
                </p>
              </div>
              <svg className="w-3.5 h-3.5 text-[#A1A1AA] shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                <polyline points="9 18 15 12 9 6" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
        )}

        <div className="h-10" />
      </div>
    </div>
  );
}
