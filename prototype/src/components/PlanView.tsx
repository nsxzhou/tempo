import { useState } from 'react';
import { Sparkles, Calendar, Coffee, RotateCw, CheckCircle } from 'lucide-react';
import { PlannerBlock } from '../types';
import { motion, AnimatePresence } from 'motion/react';

interface PlanViewProps {
  blocks: PlannerBlock[];
  onToggleBlockActive: (id: string) => void;
  onReplan: () => void;
  isReplanning: boolean;
}

export default function PlanView({ 
  blocks, 
  onToggleBlockActive,
  onReplan,
  isReplanning
}: PlanViewProps) {
  
  // Simulated energys segments
  const energyLevels = [2, 3, 4, 4, 3, 2, 1, 1, 2, 3, 3, 2];
  const energyTimes = ['8', '10', '12', '14', '16', '18', '20'];

  return (
    <div id="view-plan" className="w-full h-full relative font-sans">
      <div className="absolute inset-0 overflow-y-auto no-scrollbar pt-[44px] pb-[72px]">
        
        {/* Page Header */}
        <div className="px-5 pt-4 pb-3 flex items-end justify-between gap-3">
          <div>
            <h1 className="text-[32px] font-normal italic font-serif tracking-tight text-[#0A0A0A] leading-none">今日计划</h1>
            <div className="font-mono text-xs text-[#71717A] mt-1.5 tracking-tight">AI 已根据待办和精力自动排期</div>
          </div>
          <div className="shrink-0">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-[#FAFAFA] border border-[#E4E4E7] text-xs font-medium text-[#18181B] rounded-full font-mono">
              <Sparkles className="w-3 h-3 text-black animate-pulse" /> V2.0
            </span>
          </div>
        </div>

        {/* AI Schedule Overview */}
        <div className="mx-5 mb-4 border border-[#E4E4E7] rounded-lg bg-white overflow-hidden select-none shadow-sm">
          <div className="px-4.5 py-3.5 border-b border-[#F4F4F5] flex items-center justify-between">
            <div className="flex items-center gap-1.5 text-[11px] font-semibold text-[#71717A] uppercase tracking-wider">
              <Sparkles className="w-3.5 h-3.5 text-[#0A0A0A]" /> AI 智能排排期
            </div>
            <span className="font-mono text-[9px] px-1.5 py-0.5 bg-black text-white rounded-full uppercase scale-90">
              ACTIVE
            </span>
          </div>
          <div className="grid grid-cols-3 divide-x divide-[#E4E4E7]">
            <div className="p-3.5 text-left">
              <span className="font-mono text-lg font-medium tracking-tight block">5 个</span>
              <span className="text-[9px] text-[#71717A] uppercase tracking-wider mt-1 block font-medium">已排期任务</span>
            </div>
            <div className="p-3.5 text-left">
              <span className="font-mono text-lg font-medium tracking-tight block">6.5 小时</span>
              <span className="text-[9px] text-[#71717A] uppercase tracking-wider mt-1 block font-medium">排程时长</span>
            </div>
            <div className="p-3.5 text-left">
              <span className="font-mono text-lg font-medium tracking-tight block text-emerald-600">82%</span>
              <span className="text-[9px] text-[#71717A] uppercase tracking-wider mt-1 block font-medium">脑值匹配</span>
            </div>
          </div>
        </div>

        {/* Energy bar representation */}
        <div className="mx-5 mb-5 border border-[#E4E4E7] rounded-lg bg-white p-4.5 select-none shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <span className="text-[11px] font-bold text-[#71717A] tracking-wider uppercase">今日精力曲线</span>
            <div className="flex items-center gap-2 font-mono text-[9px] text-[#71717A]">
              低 <span className="w-1.5 h-1.5 rounded bg-zinc-100" />
              <span className="w-1.5 h-1.5 rounded bg-zinc-300" />
              <span className="w-1.5 h-1.5 rounded bg-zinc-500" />
              <span className="w-1.5 h-1.5 rounded bg-black" /> 高
            </div>
          </div>
          
          <div className="flex gap-[3px] h-10 items-stretch">
            {energyLevels.map((lvl, index) => (
              <div 
                key={index}
                className="flex-1 rounded-[3px] border border-transparent transition-all duration-300"
                style={{
                  backgroundColor: lvl === 1 ? 'rgba(0,0,0,0.04)' :
                                   lvl === 2 ? 'rgba(0,0,0,0.14)' :
                                   lvl === 3 ? 'rgba(0,0,0,0.32)' :
                                   '#0A0A0A'
                }}
                title={`Level ${lvl}`}
              />
            ))}
          </div>
          <div className="flex justify-between mt-1.5 font-mono text-[9px] text-[#A1A1AA] tracking-tight">
            {energyTimes.map((t, idx) => <span key={idx}>{t}点</span>)}
          </div>
        </div>

        {/* Timeline Blocks */}
        <div className="text-[10px] font-semibold text-[#71717A] tracking-wider uppercase px-5 py-2.5 flex items-center gap-2 select-none">
          流程排期 · {blocks.length}
          <div className="flex-1 h-[1px] bg-[#E4E4E7]" />
        </div>

        <div className="px-5 space-y-0.5">
          <AnimatePresence mode="popLayout">
            {isReplanning ? (
              <div className="py-12 flex flex-col items-center justify-center gap-3">
                <motion.div 
                  animate={{ rotate: 360 }}
                  transition={{ repeat: Infinity, duration: 1, ease: 'linear' }}
                  className="w-6 h-6 border-2 border-black border-t-transparent rounded-full"
                />
                <span className="font-sans text-xs text-[#71717A] animate-pulse">Tempo 正在为您重新优化时间窗并排期...</span>
              </div>
            ) : (
              blocks.map((block, idx) => {
                const isActive = block.active;
                return (
                  <motion.div 
                    key={block.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: idx * 0.04 }}
                    className="flex gap-4.5 py-3.5 relative"
                  >
                    {/* Left Timeline Guide Line */}
                    {idx < blocks.length - 1 && (
                      <div className={`absolute left-[54px] top-[38px] bottom-[-16px] w-[1.5px] ${isActive ? 'bg-[#0A0A0A]' : 'bg-[#E4E4E7]'}`} />
                    )}

                    {/* Time Column */}
                    <div className="w-[50px] shrink-0 text-right pt-0.5 select-none">
                      <div className="font-mono text-xs font-semibold text-[#0A0A0A] leading-tight select-none">
                        {block.start}
                      </div>
                      <div className="font-mono text-[10px] text-[#71717A] mt-1 tracking-tight select-none">
                        {block.end}
                      </div>
                    </div>

                    {/* Timeline Marker Dot */}
                    <div 
                      onClick={() => onToggleBlockActive(block.id)}
                      className={`w-3 h-3 rounded-full border-[2px] bg-white transition-all duration-300 z-10 mt-1.5 shrink-0 ${isActive ? 'border-[#0a0a0a] bg-zinc-900 scale-125 shadow-[0_0_0_3px_#FFFFFF,0_0_0_4.5px_#0A0A0A]' : 'border-[#D4D4D8] hover:border-[#18181B] cursor-pointer'}`}
                    />

                    {/* Content Card with styling matching tag */}
                    <div 
                      onClick={() => onToggleBlockActive(block.id)}
                      className={`flex-1 p-4.5 border rounded-lg bg-white hover:border-[#D4D4D8] transition-all duration-200 shadow-sm cursor-pointer ${isActive ? 'border-[#0A0A0A] ring-1 ring-black' : 'border-[#E4E4E7]'}`}
                    >
                      <h4 className="text-sm font-medium text-[#0A0A0A] tracking-tight leading-snug mb-1">
                        {block.title}
                      </h4>
                      <p className="text-xs text-[#71717A] tracking-tight mb-2.5 leading-relaxed">
                        {block.reason}
                      </p>
                      
                      {/* Sub-tag indicator */}
                      <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 text-[9px] font-semibold uppercase tracking-wider border rounded-full font-sans ${
                        block.tag === 'calendar' ? 'text-zinc-600 bg-zinc-50 border-zinc-200' :
                        block.tag === 'p0' ? 'text-red-700 bg-red-50 border-red-200' :
                        block.tag === 'p1' ? 'text-amber-700 bg-amber-50 border-amber-200' :
                        block.tag === 'p2' ? 'text-blue-700 bg-blue-50 border-blue-200' :
                        block.tag === 'break' ? 'text-emerald-700 bg-emerald-50 border-emerald-200' :
                        'text-indigo-700 bg-indigo-50 border-indigo-200'
                      }`}>
                        {block.tag === 'calendar' ? '日程订阅' : 
                         block.tag === 'break' ? '脑力保护 🌴' : 
                         block.tag === 'buff' ? '轻量收尾 🗃️' : block.tag.toUpperCase() + ' 专注'}
                      </span>
                    </div>
                  </motion.div>
                );
              })
            )}
          </AnimatePresence>
        </div>

        {/* Action button */}
        <button 
          onClick={onReplan}
          disabled={isReplanning}
          className="mx-5 mt-6 mb-8 w-calc-diff border border-[#E4E4E7] bg-white rounded-lg py-3 flex items-center justify-center gap-2 font-medium text-sm text-[#0A0A0A] hover:bg-zinc-50 hover:border-black/50 transition-all duration-150 cursor-pointer disabled:opacity-50 select-none"
          style={{ width: 'calc(100% - 40px)' }}
        >
          <RotateCw className={`w-3.5 h-3.5 ${isReplanning ? 'animate-spin' : ''}`} />
          重新进行精力排期
        </button>

        <div className="h-[40px]" />
      </div>
    </div>
  );
}
