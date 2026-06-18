import { Wifi, Battery } from 'lucide-react';

interface StatusBarProps {
  time?: string;
}

export default function StatusBar({ time = '09:41' }: StatusBarProps) {
  return (
    <div 
      id="status-bar"
      className="absolute top-0 left-0 right-0 h-[44px] flex items-center justify-between px-7 z-[100] pointer-events-none select-none"
    >
      <span className="font-mono text-sm font-semibold tracking-tight text-[#0A0A0A]">
        {time}
      </span>
      <div className="flex items-center gap-1 text-[#0A0A0A]">
        <Wifi className="w-3.5 h-3.5 stroke-2" />
        <div className="relative w-5 h-3 border border-[#0A0A0A]/80 rounded-[4px] p-[1px] flex items-center">
          <div className="h-full bg-[#0A0A0A] rounded-[2px] w-[85%]" />
          <div className="absolute -right-[3px] top-[3px] w-[2px] h-[4px] bg-[#0A0A0A]/80 rounded-r-[1px]" />
        </div>
      </div>
    </div>
  );
}
