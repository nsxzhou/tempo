import React, { useState } from 'react';
import { 
  Target, 
  HelpCircle, 
  Info, 
  Link2, 
  Calendar, 
  Bell, 
  Sliders, 
  User, 
  Zap, 
  Activity, 
  Clock, 
  Sparkles,
  ChevronRight,
  LogOut
} from 'lucide-react';
import { motion } from 'motion/react';

interface SettingsViewProps {
  onShowNotificationBanner: (msg: string) => void;
}

export default function SettingsView({ onShowNotificationBanner }: SettingsViewProps) {
  const [notificationOn, setNotificationOn] = useState<boolean>(true);
  const [syncSiyuan, setSyncSiyuan] = useState<boolean>(true);

  return (
    <div id="view-settings" className="w-full h-full relative font-sans text-stone-900 bg-white overflow-hidden">
      <div className="absolute inset-0 overflow-hidden pt-[44px] pb-[72px]">
        
        {/* Profile and Quick Card Header Block */}
        <div className="px-5 pt-5 pb-3">
          <div className="bg-white border border-zinc-200/80 rounded-2xl p-5 shadow-xs relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/5 rounded-full blur-2xl pointer-events-none" />
            
            {/* Upper profile */}
            <div className="flex items-center justify-between gap-3 select-none">
              <div className="flex items-center gap-3.5">
                {/* Custom Styled Avatar */}
                <div className="relative group shrink-0">
                  <div className="w-14 h-14 bg-[#0A0A0A] text-[#FAFAFA] rounded-full flex items-center justify-center font-serif italic text-xl shadow-md border border-zinc-200">
                    舟
                  </div>
                  <div className="absolute -bottom-0.5 -right-0.5 w-[14px] height-[14px] bg-emerald-500 border-2 border-white rounded-full" title="在线" />
                </div>

                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-bold tracking-tight text-[#0A0A0A]">周舟</h2>
                    <span className="font-sans text-[10px] font-bold text-indigo-700 bg-indigo-50 px-1.5 py-0.2 rounded border border-indigo-100 flex items-center gap-1">
                      <Zap className="w-2.5 h-2.5 fill-indigo-400 text-indigo-500" /> MVP 验证期
                    </span>
                  </div>
                  <p className="font-mono text-[10px] text-zinc-400 mt-1 tracking-tight">zhouzhou@email.com</p>
                </div>
              </div>

              <button 
                onClick={() => onShowNotificationBanner("已注销本次测试虚拟账户连接")}
                className="px-2.5 py-1.5 rounded-lg border border-red-150 hover:border-red-200 hover:bg-red-50/50 text-red-650 hover:text-red-700 text-xs font-semibold tracking-tight transition-all duration-100 active:scale-95 cursor-pointer flex items-center gap-1 shrink-0 bg-transparent font-sans"
              >
                <LogOut className="w-3.5 h-3.5 text-red-500" />
                <span>注销</span>
              </button>
            </div>

            {/* Core user stats embedded layout */}
            <div className="grid grid-cols-3 divide-x divide-zinc-100 mt-5 pt-4 border-t border-zinc-100 select-none">
              <div className="text-center font-sans">
                <span className="font-mono text-xl font-bold tracking-tight block text-[#0A0A0A]">128 项</span>
                <span className="text-[9px] text-zinc-400 font-bold uppercase tracking-wider mt-1 block">累计完成</span>
              </div>
              <div className="text-center font-sans">
                <span className="font-mono text-xl font-bold tracking-tight block text-[#0A0A0A]">14 天</span>
                <span className="text-[9px] text-zinc-400 font-bold uppercase tracking-wider mt-1 block">连续自燃周期</span>
              </div>
              <div className="text-center font-sans">
                <span className="font-mono text-xl font-bold tracking-tight block text-emerald-600">82%</span>
                <span className="text-[9px] text-zinc-400 font-bold uppercase tracking-wider mt-1 block">本周采纳系数</span>
              </div>
            </div>
          </div>
        </div>

        {/* Integration Row */}
        <div className="text-[10px] font-bold text-zinc-450 tracking-widest uppercase px-5 py-3 flex items-center gap-2 select-none">
          外部集成与同步
          <div className="flex-1 h-[1.5px] bg-zinc-200/60" />
        </div>

        <div className="px-5 mb-4">
          <div className="border border-zinc-200 rounded-2xl overflow-hidden bg-white shadow-xs">
            
            {/* SiYuan sync details */}
            <div className="flex items-center gap-3.5 p-3.5 border-b border-zinc-100 hover:bg-zinc-50/50 transition-colors duration-100 cursor-pointer">
              <div className="w-9 h-9 rounded-xl border border-amber-200 bg-amber-50 text-amber-700 flex items-center justify-center shrink-0">
                <Link2 className="w-4 h-4" />
              </div>
              <div className="flex-1 min-w-0 font-sans">
                <h4 className="text-xs font-semibold text-[#0A0A0A] tracking-tight">思源外部笔记 Petal 连接</h4>
                <p className="text-[10px] text-zinc-400 tracking-tight mt-0.5">2 分钟前已本地自动增量联动</p>
              </div>
              <button 
                onClick={() => {
                  setSyncSiyuan(!syncSiyuan);
                  onShowNotificationBanner(syncSiyuan ? "已断开思源中文笔记增量拉取" : "思源笔记已建立增量握手。");
                }}
                className={`font-mono text-[10px] font-bold px-2.5 py-1 rounded-lg transition-all duration-150 border cursor-pointer ${syncSiyuan ? 'text-[#059669] bg-emerald-50 border-emerald-100 hover:bg-emerald-100/60' : 'text-zinc-500 bg-zinc-50 border-zinc-200 hover:bg-zinc-100'}`}
              >
                {syncSiyuan ? '已连通' : '未开启'}
              </button>
            </div>

            {/* Apple Cal sync details */}
            <div 
              onClick={() => onShowNotificationBanner("系统日历服务正在稳定守候中")}
              className="flex items-center gap-3.5 p-3.5 hover:bg-zinc-50/50 transition-colors duration-100 cursor-pointer"
            >
              <div className="w-9 h-9 rounded-xl border border-blue-200 bg-blue-50 text-blue-700 flex items-center justify-center shrink-0">
                <Calendar className="w-4 h-4" />
              </div>
              <div className="flex-1 min-w-0 font-sans">
                <h4 className="text-xs font-semibold text-[#0A0A0A] tracking-tight">本地系统日历订阅</h4>
                <p className="text-[10px] text-zinc-400 tracking-tight mt-0.5">已监听 13 项重要业务冲突日程</p>
              </div>
              <span className="text-[9px] font-mono font-bold text-indigo-700 bg-indigo-50 border border-indigo-150 px-2 py-0.5 rounded-md shrink-0">
                ACTIVE
              </span>
            </div>

          </div>
        </div>

        {/* Preferences */}
        <div className="text-[10px] font-bold text-zinc-450 tracking-widest uppercase px-5 py-3 flex items-center gap-2 select-none">
          个性化偏好
          <div className="flex-1 h-[1.5px] bg-zinc-200/60" />
        </div>

        <div className="px-5 space-y-4">
          <div className="border border-zinc-200 rounded-2xl overflow-hidden bg-white shadow-xs">
            
            {/* Notification alert toggle */}
            <div className="flex items-center justify-between p-3.5 border-b border-zinc-100">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg border border-neutral-200 bg-neutral-50 flex items-center justify-center shrink-0 text-neutral-800">
                  <Bell className="w-4 h-4" />
                </div>
                <div className="font-sans">
                  <h4 className="text-xs font-semibold text-[#0A0A0A] tracking-tight">桌面高频提醒</h4>
                  <p className="text-[10px] text-zinc-400 mt-0.5">任务倒计时与 AI 周期精力诊断</p>
                </div>
              </div>
              <button 
                onClick={() => {
                  setNotificationOn(!notificationOn);
                  onShowNotificationBanner(notificationOn ? "桌面高频提醒已静音" : "已激活精品日程推送");
                }}
                className={`w-[34px] h-[20px] rounded-full relative transition-colors duration-200 border-none cursor-pointer ${notificationOn ? 'bg-black' : 'bg-zinc-250'}`}
              >
                <div className={`w-4 h-4 rounded-full bg-white absolute top-0.5 transition-transform duration-200 ${notificationOn ? 'translate-x-[15px]' : 'translate-x-0.5'}`} />
              </button>
            </div>

            {/* AI Preferences */}
            <div 
              onClick={() => onShowNotificationBanner("AI 分析偏好已锁定智能模式")}
              className="flex items-center justify-between p-3.5 border-b border-zinc-100 hover:bg-zinc-50/50 cursor-pointer"
            >
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg border border-neutral-200 bg-neutral-50 flex items-center justify-center shrink-0 text-neutral-800">
                  <Sliders className="w-4 h-4" />
                </div>
                <div className="font-sans">
                  <h4 className="text-xs font-semibold text-[#0A0A0A] tracking-tight">AI 排程解析偏好</h4>
                  <p className="text-[10px] text-zinc-400 mt-0.5">排期策略优化与长文总结合并</p>
                </div>
              </div>
              <span className="font-mono text-[9px] font-bold text-zinc-500 bg-zinc-100 px-1.5 py-0.5 rounded">
                锌版/Zinc
              </span>
            </div>

            {/* About platform */}
            <div 
              onClick={() => onShowNotificationBanner("Tempo — 智能同步时间规划大师")}
              className="flex items-center justify-between p-3.5 hover:bg-zinc-50/50 cursor-pointer"
            >
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg border border-neutral-200 bg-neutral-50 flex items-center justify-center shrink-0 text-neutral-800">
                  <Info className="w-4 h-4" />
                </div>
                <div className="font-sans">
                  <h4 className="text-xs font-semibold text-[#0A0A0A] tracking-tight">关于 Tempo MVP</h4>
                  <p className="text-[10px] text-zinc-400 mt-0.5">Stripe 精致排版工艺学 V2.0.0</p>
                </div>
              </div>
              <span className="font-mono text-[9px] font-bold text-zinc-500">
                v2.0
              </span>
            </div>

          </div>

          {/* Footer Branding */}
          <div className="text-center py-5">
            <p className="font-mono text-[9px] text-zinc-400 tracking-widest uppercase">TEMPO EXPERIMENT CORP · GOMVP</p>
          </div>
        </div>

      </div>
    </div>
  );
}
