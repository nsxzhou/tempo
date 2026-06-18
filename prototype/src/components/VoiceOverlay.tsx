import { useState, useEffect } from 'react';
import { Mic, X, Calendar, Flag, Hash } from 'lucide-react';
import { Task } from '../types';

interface VoiceOverlayProps {
  isOpen: boolean;
  onClose: () => void;
  onAddTaskParsed: (task: Task) => void;
}

export default function VoiceOverlay({ 
  isOpen, 
  onClose, 
  onAddTaskParsed 
}: VoiceOverlayProps) {
  
  const [isRecording, setIsRecording] = useState<boolean>(true);
  const [transcription, setTranscription] = useState<string>("明天下午三点提交设计稿，优先级高");
  const [statusText, setStatusText] = useState<string>("语音采音中 · 点击麦克风暂停");

  // Simulated recording waveforms pulse
  const [waveScale, setWaveScale] = useState<number>(1.2);

  useEffect(() => {
    if (!isOpen) return;
    
    // Wave pulse visual interval
    const interval = setInterval(() => {
      setWaveScale(prev => (prev === 1.5 ? 1.0 : 1.5));
    }, 800);

    return () => clearInterval(interval);
  }, [isOpen]);

  const handleMicToggle = () => {
    if (isRecording) {
      setIsRecording(false);
      setStatusText("拾音已暂停 · 点击重新采音");
    } else {
      setIsRecording(true);
      setStatusText("语音采音中 · 点击麦克风暂停");
    }
  };

  const handleCreateTask = () => {
    // Dynamically draft a mock parsed voice inputs task
    const parsedTask: Task = {
      id: `vt-${Date.now()}`,
      title: '提交设计稿 (语音录入)',
      priority: 'p1',
      deadline: '明天 15:00',
      tag: '产品',
      completed: false,
      overdue: false,
      description: '通过智能语音输入自动识别排期。识别内容: "' + transcription + '"',
      siyuanLink: null,
      subtasks: [
        { id: 'vsub-1', title: '整理画板与颜色变量', completed: false },
        { id: 'vsub-2', title: '检查标注边距配置', completed: false }
      ],
      estimate: '1h',
      allocatedTime: '15:00 – 16:00',
      energyMatch: '能量充沛段排期'
    };

    onAddTaskParsed(parsedTask);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div 
      className="absolute inset-0 bg-black/45 backdrop-blur-[3.5px] z-[210] flex items-end justify-center transition-all duration-200 select-none animate-fadeIn"
      onClick={onClose}
    >
      <div 
        className="w-full bg-white rounded-t-2xl border-t border-[#E4E4E7] p-5 pb-9 transform translate-y-0 transition-transform duration-300 shadow-[0_-8px_30px_rgb(0,0,0,0.12)]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top bar indicator drag handle */}
        <div className="w-10 h-[4px] bg-[#E4E4E7] rounded-full mx-auto mb-4" />

        {/* Recording elements row */}
        <div className="flex items-center gap-4 p-4 border border-[#E4E4E7] rounded-xl bg-[#FAFAFA] mb-4">
          <div className="relative shrink-0">
            {/* Visual Pulse ring */}
            {isRecording && (
              <div 
                className="absolute inset-0 rounded-full border border-black transition-all duration-1000 ease-out" 
                style={{
                  transform: `scale(${waveScale})`,
                  opacity: waveScale === 1.5 ? 0 : 0.85
                }}
              />
            )}
            <button 
              onClick={handleMicToggle}
              className={`w-11 h-11 rounded-full flex items-center justify-center transition-all duration-150 ${isRecording ? 'bg-[#0a0a0a] text-white animate-pulse' : 'bg-[#F4F4F5] border border-[#E4E4E7] text-[#0A0A0A]'}`}
            >
              <Mic className="w-5 h-5 stroke-[1.8]" />
            </button>
          </div>
          
          <div className="flex-1">
            <span className="text-xs font-semibold text-[#0A0A0A] tracking-tight block">
              {statusText}
            </span>
            <span className="font-mono text-[10px] text-[#A1A1AA] mt-1.5 block">
              Gemini Whisper V2 Engine
            </span>
          </div>
        </div>

        {/* Current transcription panel */}
        <div className="p-3.5 border border-[#E4E4E7] rounded-xl text-sm text-[#0a0a0a] min-h-[50px] leading-relaxed bg-white shadow-xs focus-within:border-zinc-400">
          <textarea
            value={transcription}
            onChange={(e) => setTranscription(e.target.value)}
            className="w-full h-full bg-transparent border-none outline-none resize-none font-sans font-medium"
            rows={2}
          />
        </div>

        {/* NLP Tag parsing outputs */}
        <div className="flex flex-wrap gap-1.5 my-4">
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 bg-zinc-50 border border-zinc-200 text-[#71717A] text-[10.5px] font-medium rounded-full font-mono">
            <Calendar className="w-3 h-3 text-black" /> 明天 15:00
          </span>
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 bg-amber-50 border border-amber-200 text-amber-800 text-[10.5px] font-medium rounded-full font-mono">
            <Flag className="w-3 h-3" /> P1 高
          </span>
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 bg-blue-50 border border-blue-200 text-blue-800 text-[10.5px] font-medium rounded-full font-mono">
            <Hash className="w-3 h-3" /> 产品
          </span>
        </div>

        {/* Actions button arrays */}
        <div className="flex gap-2.5">
          <button 
            onClick={onClose}
            className="flex-1 py-2.5 border border-[#E4E4E7] rounded-lg text-sm font-semibold text-[#71717A] bg-white hover:bg-[#F4F4F5] transition-colors duration-150 cursor-pointer text-center"
          >
            取消
          </button>
          <button 
            onClick={handleCreateTask}
            className="flex-1 py-2.5 bg-black text-white hover:bg-zinc-800 rounded-lg text-sm font-semibold transition-colors duration-150 cursor-pointer text-center"
          >
            智能分析并排入今天
          </button>
        </div>

      </div>
    </div>
  );
}
