import { useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';

interface SnackbarProps {
  message: string;
  show: boolean;
  onUndo?: () => void;
  onClose: () => void;
}

export default function Snackbar({ 
  message, 
  show, 
  onUndo, 
  onClose 
}: SnackbarProps) {
  
  // Auto dismiss timeout
  useEffect(() => {
    if (!show) return;
    const t = setTimeout(() => {
      onClose();
    }, 4500);

    return () => clearTimeout(t);
  }, [show, onClose]);

  return (
    <AnimatePresence>
      {show && (
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 8 }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          className="absolute bottom-[80px] left-4 right-4 bg-[#0A0A0A] text-white p-4.5 rounded-lg flex items-center justify-between shadow-lg z-[250] pointer-events-auto"
        >
          <span className="text-xs font-semibold tracking-tight leading-snug">
            {message}
          </span>
          {onUndo && (
            <button 
              onClick={(e) => {
                e.stopPropagation();
                onUndo();
                onClose();
              }}
              className="text-xs font-bold text-white underline underline-offset-4 hover:opacity-100 opacity-90 tracking-tight ml-3 shrink-0 cursor-pointer"
            >
              撤销更改
            </button>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
