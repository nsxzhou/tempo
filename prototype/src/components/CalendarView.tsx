import { useState, useMemo } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, CheckCircle2, Circle } from 'lucide-react';
import { Task } from '../types';

interface CalendarViewProps {
  tasks: Task[];
  onSelectTask: (task: Task) => void;
}

interface DateObj {
  dayNum: number;
  isOtherMonth: boolean;
  today?: boolean;
  dots: string[];
}

export default function CalendarView({ tasks, onSelectTask }: CalendarViewProps) {
  const [selectedDate, setSelectedDate] = useState<number>(17); // 17 is June 17, 2026 Today
  const [viewMode, setViewMode] = useState<'month' | 'week' | 'day'>('month');

  // Days in week strip
  const weekStrip = [
    { day: '一', num: 16, active: false },
    { day: '二', num: 17, active: true, today: true },
    { day: '三', num: 18, active: false },
    { day: '四', num: 19, active: false },
    { day: '五', num: 20, active: false },
    { day: '六', num: 21, active: false },
    { day: '日', num: 22, active: false },
  ];

  // Month days setup (June 2026 starts on Monday)
  const monthDays: DateObj[] = [
    // May overflow
    { dayNum: 25, isOtherMonth: true, dots: [] },
    { dayNum: 26, isOtherMonth: true, dots: [] },
    { dayNum: 27, isOtherMonth: true, dots: [] },
    { dayNum: 28, isOtherMonth: true, dots: [] },
    { dayNum: 29, isOtherMonth: true, dots: [] },
    { dayNum: 30, isOtherMonth: true, dots: [] },
    { dayNum: 31, isOtherMonth: true, dots: [] },
    // June
    { dayNum: 1, isOtherMonth: false, dots: ['#2563EB'] },
    { dayNum: 2, isOtherMonth: false, dots: [] },
    { dayNum: 3, isOtherMonth: false, dots: ['#D97706', '#71717A'] },
    { dayNum: 4, isOtherMonth: false, dots: [] },
    { dayNum: 5, isOtherMonth: false, dots: ['#DC2626'] },
    { dayNum: 6, isOtherMonth: false, dots: [] },
    { dayNum: 7, isOtherMonth: false, dots: ['#2563EB'] },
    
    { dayNum: 8, isOtherMonth: false, dots: [] },
    { dayNum: 9, isOtherMonth: false, dots: ['#D97706'] },
    { dayNum: 10, isOtherMonth: false, dots: ['#059669'] },
    { dayNum: 11, isOtherMonth: false, dots: [] },
    { dayNum: 12, isOtherMonth: false, dots: ['#D97706', '#2563EB'] },
    { dayNum: 13, isOtherMonth: false, dots: [] },
    { dayNum: 14, isOtherMonth: false, dots: ['#71717A'] },

    { dayNum: 15, isOtherMonth: false, dots: ['#D97706'] },
    { dayNum: 16, isOtherMonth: false, dots: ['#2563EB'] },
    { dayNum: 17, isOtherMonth: false, today: true, dots: ['#DC2626', '#D97706', '#0A0A0A'] },
    { dayNum: 18, isOtherMonth: false, dots: ['#2563EB'] },
    { dayNum: 19, isOtherMonth: false, dots: ['#D97706'] },
    { dayNum: 20, isOtherMonth: false, dots: [] },
    { dayNum: 21, isOtherMonth: false, dots: ['#71717A'] },

    { dayNum: 22, isOtherMonth: false, dots: ['#D97706'] },
    { dayNum: 23, isOtherMonth: false, dots: [] },
    { dayNum: 24, isOtherMonth: false, dots: ['#DC2626'] },
    { dayNum: 25, isOtherMonth: false, dots: ['#2563EB'] },
    { dayNum: 26, isOtherMonth: false, dots: [] },
    { dayNum: 27, isOtherMonth: false, dots: [] },
    { dayNum: 28, isOtherMonth: false, dots: ['#D97706'] },

    { dayNum: 29, isOtherMonth: false, dots: ['#2563EB'] },
    { dayNum: 30, isOtherMonth: false, dots: ['#D97706'] },
    // July overflow
    { dayNum: 1, isOtherMonth: true, dots: [] },
    { dayNum: 2, isOtherMonth: true, dots: [] },
    { dayNum: 3, isOtherMonth: true, dots: [] },
    { dayNum: 4, isOtherMonth: true, dots: [] },
    { dayNum: 5, isOtherMonth: true, dots: [] }
  ];

  // Selected Date events list
  const scheduledTasks = useMemo(() => {
    if (selectedDate === 17) {
      return tasks.filter(t => !t.completed);
    } else if (selectedDate === 16) {
      return tasks.slice(2, 4);
    } else if (selectedDate % 2 === 0) {
      return [tasks[0]];
    } else {
      return tasks.filter(t => t.completed);
    }
  }, [selectedDate, tasks]);

  const handlePrevDay = () => {
    if (selectedDate > 1) setSelectedDate(prev => prev - 1);
  };

  const handleNextDay = () => {
    if (selectedDate < 30) setSelectedDate(prev => prev + 1);
  };

  return (
    <div id="view-calendar" className="w-full h-full relative font-sans text-stone-900 bg-white">
      <div className="absolute inset-0 overflow-y-auto no-scrollbar pt-[44px] pb-[72px]">
        
        {/* Page Header */}
        <div className="px-5 pt-4 pb-3 flex items-end justify-between">
          <div>
            <h1 className="text-[32px] font-semibold tracking-tight text-[#0A0A0A] leading-none">日历</h1>
            <div className="font-mono text-xs text-[#71717A] mt-1.5 tracking-tight">
              {viewMode === 'month' ? '2026 年 6 月' : viewMode === 'week' ? '6 月 · 第 25 周' : `6 月 ${selectedDate} 日`}
            </div>
          </div>
        </div>

        {/* View Mode Switching Tabs (Fusing point) */}
        <div className="px-5 pb-3 flex items-center gap-2 select-none">
          <div className="flex-1 flex border border-[#E4E4E7] rounded-xl p-[3px] bg-[#F4F4F5]">
            <button 
              onClick={() => setViewMode('month')}
              className={`flex-1 py-1.5 text-xs font-semibold rounded-lg transition-all duration-150 ${viewMode === 'month' ? 'bg-white text-[#0a0a0a] shadow-xs' : 'text-[#71717A]'}`}
            >
              月
            </button>
            <button 
              onClick={() => setViewMode('week')}
              className={`flex-1 py-1.5 text-xs font-semibold rounded-lg transition-all duration-150 ${viewMode === 'week' ? 'bg-white text-[#0a0a0a] shadow-xs' : 'text-[#71717A]'}`}
            >
              周
            </button>
            <button 
              onClick={() => setViewMode('day')}
              className={`flex-1 py-1.5 text-xs font-semibold rounded-lg transition-all duration-150 ${viewMode === 'day' ? 'bg-white text-[#0a0a0a] shadow-xs' : 'text-[#71717A]'}`}
            >
              日
            </button>
          </div>

          <button 
            onClick={() => setSelectedDate(17)} 
            className="h-[36px] px-3.5 rounded-xl border border-[#E4E4E7] text-xs font-semibold text-[#18181B] bg-white hover:border-[#D4D4D8] hover:bg-zinc-50 active:scale-95 transition-all duration-150 flex items-center gap-1 shrink-0"
            title="回到今天"
          >
            <CalendarIcon className="w-3.5 h-3.5 text-[#71717A]" />
            <span>今日</span>
          </button>
        </div>

        {/* Unified Responsive Calendar Container */}
        <div className="px-5 py-2">
          {viewMode === 'month' && (
            <div className="border border-[#E4E4E7] rounded-2xl p-4 bg-[#FAFAFA]/40 shadow-xs">
              {/* Weekdays */}
              <div className="grid grid-cols-7 mb-2 select-none">
                {['一', '二', '三', '四', '五', '六', '日'].map(w => (
                  <span key={w} className="text-center font-mono text-[10px] font-bold text-[#A1A1AA] py-0.5 uppercase tracking-wide">
                    {w}
                  </span>
                ))}
              </div>

              {/* Monthly Day Grid */}
              <div className="grid grid-cols-7 gap-y-1 gap-x-0.5 select-none">
                {monthDays.map((date, idx) => {
                  const isSelected = selectedDate === date.dayNum && !date.isOtherMonth;
                  return (
                    <div 
                      key={idx}
                      onClick={() => {
                        if (!date.isOtherMonth) setSelectedDate(date.dayNum);
                      }}
                      className={`aspect-square flex flex-col items-center justify-center cursor-pointer rounded-lg transition-all duration-120 ${isSelected ? '' : 'hover:bg-zinc-100'}`}
                    >
                      <div className={`w-7 h-7 flex items-center justify-center rounded-full font-mono text-xs font-semibold ${
                        date.isOtherMonth ? 'text-zinc-300' :
                        isSelected ? 'bg-[#0A0A0A] text-white shadow-xs' :
                        date.today ? 'border border-[#0A0A0A] text-[#0A0A0A]' : 'text-[#27272A]'
                      }`}>
                        {date.dayNum}
                      </div>
                      {/* Dots of events */}
                      <div className="flex gap-[2px] h-[3px] mt-0.5 justify-center overflow-hidden">
                        {date.dots.slice(0, 3).map((dotColor, dotIdx) => (
                          <div 
                            key={dotIdx} 
                            className="w-[3px] h-[3px] rounded-full" 
                            style={{ backgroundColor: isSelected ? '#FFFFFF' : dotColor }} 
                          />
                        ))}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {viewMode === 'week' && (
            <div className="border border-[#E4E4E7] rounded-2xl p-4 bg-[#FAFAFA]/40 shadow-xs">
              <div className="flex gap-2 select-none">
                {weekStrip.map((item) => {
                  const isSel = selectedDate === item.num;
                  return (
                    <div 
                      key={item.num}
                      onClick={() => setSelectedDate(item.num)}
                      className={`flex-1 py-3 rounded-xl flex flex-col items-center gap-1.5 cursor-pointer transition-all duration-150 ${
                        isSel ? 'bg-[#0A0A0A] text-white shadow-sm' : 'bg-white border border-[#E4E4E7] text-[#71717A] hover:bg-zinc-50'
                      }`}
                    >
                      <span className="font-mono text-[10px] uppercase font-bold tracking-wider opacity-80">
                        {item.day}
                      </span>
                      <span className={`font-mono text-base font-bold tracking-tight ${isSel ? 'text-white' : 'text-[#18181B]'}`}>
                        {item.num}
                      </span>
                      <div className="flex gap-0.5 justify-center">
                        <div className={`w-[4px] h-[4px] rounded-full ${isSel ? 'bg-white' : 'bg-[#D4D4D8]'}`} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {viewMode === 'day' && (
            <div className="border border-[#E4E4E7] rounded-2xl p-4.5 bg-[#FAFAFA]/40 shadow-xs flex items-center justify-between">
              <button 
                onClick={handlePrevDay}
                disabled={selectedDate <= 1}
                className="w-10 h-10 rounded-xl border border-[#E4E4E7] bg-white flex items-center justify-center text-[#71717A] hover:text-[#0A0A0A] hover:bg-zinc-50 active:scale-95 transition-all cursor-pointer disabled:opacity-40 disabled:pointer-events-none"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>

              <div className="text-center font-sans px-4">
                <div className="font-mono text-[10px] font-bold text-zinc-400 uppercase tracking-widest mb-1">
                  SELECTED DAY
                </div>
                <div className="text-2xl font-bold tracking-tight text-[#0a0a0a]">
                  6 月 {selectedDate} 日
                </div>
                <div className="font-mono text-xs text-[#71717A] mt-1">
                  周{selectedDate === 17 ? '二 · 今天' : selectedDate === 16 ? '一' : '三'}
                </div>
              </div>

              <button 
                onClick={handleNextDay}
                disabled={selectedDate >= 30}
                className="w-10 h-10 rounded-xl border border-[#E4E4E7] bg-white flex items-center justify-center text-[#71717A] hover:text-[#0A0A0A] hover:bg-zinc-50 active:scale-95 transition-all cursor-pointer disabled:opacity-40 disabled:pointer-events-none"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          )}
        </div>

        {/* Day Events Panel */}
        <div className="px-5 mt-4">
          <div className="flex items-baseline justify-between mb-3.5 select-none">
            <h3 className="text-xs font-bold text-[#18181B] tracking-wider uppercase">
              待办日程 ({scheduledTasks.length} 项)
            </h3>
            <span className="font-mono text-[10px] text-zinc-400 font-bold">
              6/2026
            </span>
          </div>
 
          {/* List of Tasks / Events */}
          <div className="space-y-3">
            {scheduledTasks.map((task) => (
              <div 
                key={task.id}
                onClick={() => onSelectTask(task)}
                className="p-4 border border-[#E4E4E7] rounded-xl bg-white hover:border-[#D4D4D8] transition-all duration-150 cursor-pointer shadow-xs flex items-center justify-between"
              >
                <div className="min-w-0 pr-4">
                  <h4 className="text-sm font-semibold text-[#0A0A0A] tracking-tight mb-1.5 truncate">{task.title}</h4>
                  <div className="flex items-center gap-2 text-[10px] font-bold text-[#71717A]">
                    <span className={`px-1.5 py-0.2 rounded font-sans text-[8px] uppercase ${
                      task.priority === 'p0' ? 'text-red-700 bg-red-50 border border-red-150' :
                      task.priority === 'p1' ? 'text-amber-700 bg-amber-50 border border-amber-150' :
                      task.priority === 'p2' ? 'text-blue-700 bg-blue-50 border border-blue-150' :
                      'text-[#71717A] bg-[#F4F4F5] border border-zinc-200'
                    }`}>
                      {task.priority.toUpperCase()}
                    </span>
                    <span className="font-mono bg-zinc-50 px-1.5 py-0.2 rounded border border-zinc-150">{task.allocatedTime}</span>
                  </div>
                </div>
                {task.completed ? (
                  <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 border border-emerald-100 rounded-full px-2 py-0.5 shrink-0">已完成</span>
                ) : (
                  <span className="font-mono text-xs text-[#71717A] shrink-0 font-medium">{task.estimate}</span>
                )}
              </div>
            ))}

            {scheduledTasks.length === 0 && (
              <div className="p-8 border border-dashed border-[#E4E4E7] rounded-xl bg-zinc-50/20 text-center select-none">
                <p className="text-xs text-zinc-400 font-semibold font-sans">本日暂无排期日程</p>
              </div>
            )}

            {selectedDate === 17 && (
              <div className="p-4 border border-dashed border-zinc-200 rounded-xl bg-zinc-50/50 flex items-start gap-3 select-none">
                <span className="text-[9px] bg-black text-white px-1.5 py-0.5 rounded font-bold uppercase tracking-wider scale-90">AI</span>
                <div>
                  <h4 className="text-xs text-zinc-500 font-semibold tracking-tight">AI 智能推荐排期：整理读书笔记</h4>
                  <p className="font-mono text-[10px] text-zinc-400 mt-1">16:00 – 17:30 · 待办高优先智能填充</p>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="h-[40px]" />
      </div>
    </div>
  );
}
