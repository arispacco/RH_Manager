import React from 'react';
import { motion } from 'motion/react';
import { 
  QrCode, 
  MapPin, 
  Clock, 
  CheckCircle2, 
  History,
  Calendar,
  AlertCircle
} from 'lucide-react';
import { cn } from '@/src/lib/utils';
import { User } from '@/src/types';

interface EmployeeDashboardProps {
  user: User;
}

export default function EmployeeDashboard({ user }: EmployeeDashboardProps) {
  const today = new Date().toLocaleDateString('en-US', { 
    weekday: 'long', 
    month: 'long', 
    day: 'numeric' 
  });

  return (
    <div className="p-6 lg:p-10 max-w-md mx-auto space-y-10">
      <header className="space-y-1">
        <h1 className="text-4xl font-bold text-primary tracking-tight">Good morning, {user.name.split(' ')[0]}</h1>
        <p className="text-on-surface-variant font-medium">{today}</p>
      </header>

      {/* Main Scan Action */}
      <div className="flex justify-center py-4">
        <motion.button 
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.95 }}
          className="relative w-72 h-72 rounded-[40px] bg-secondary text-white flex flex-col items-center justify-center gap-6 shadow-2xl shadow-secondary/40 border-[6px] border-secondary-container/20 group overflow-hidden"
        >
          <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none" />
          <motion.div 
            animate={{ 
              scale: [1, 1.1, 1],
              rotate: [0, 5, -5, 0]
            }}
            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
            className="relative z-10"
          >
            <QrCode size={84} strokeWidth={1.5} className="text-white drop-shadow-xl" />
          </motion.div>
          <span className="text-2xl font-bold tracking-tight relative z-10">Scan QR Code</span>
        </motion.button>
      </div>

      {/* Location Status Card */}
      <div className="bg-white rounded-3xl p-6 border border-outline-variant/30 shadow-sm flex items-center gap-5 transition-shadow hover:shadow-md">
        <div className="h-14 w-14 rounded-full bg-secondary-container/20 text-secondary flex items-center justify-center shrink-0">
          <MapPin size={28} />
        </div>
        <div className="flex-1">
          <p className="text-xs font-bold text-on-surface-variant uppercase tracking-widest">Location Status</p>
          <p className="text-xl font-bold text-on-surface leading-tight mt-0.5">Within 50m of Office</p>
        </div>
        <div className="text-secondary bg-emerald-50 p-2 rounded-full">
          <CheckCircle2 size={24} />
        </div>
      </div>

      {/* Attendance Summary */}
      <section className="bg-white rounded-3xl p-8 border border-outline-variant/30 shadow-sm space-y-8">
        <h2 className="text-xl font-bold text-primary flex items-center gap-3">
          My Today's Attendance
        </h2>
        
        <div className="space-y-6">
          <div className="flex items-center justify-between pb-6 border-b border-outline-variant/10">
            <div className="flex items-center gap-3 text-on-surface-variant font-medium">
              <Clock size={20} />
              <span>Clock-in Time</span>
            </div>
            <span className="text-2xl font-bold text-primary">08:45 AM</span>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3 text-on-surface-variant font-medium">
              <History size={20} />
              <span>Status</span>
            </div>
            <span className="inline-flex items-center px-4 py-2 rounded-full font-bold text-xs uppercase tracking-wider gap-2 bg-emerald-50 text-emerald-700 border border-emerald-100">
               <div className="w-1.5 h-1.5 rounded-full bg-emerald-600" />
               Present
            </span>
          </div>
        </div>
      </section>

      {/* Warning Box (Mockup detail) */}
      <div className="bg-blue-50/50 border border-blue-100 rounded-3xl p-6 flex items-start gap-4">
        <AlertCircle className="text-blue-600 shrink-0 mt-0.5" size={20} />
        <p className="text-sm text-blue-900 leading-relaxed">
          <span className="font-bold block mb-0.5">Note:</span>
          Your location is verified automatically via GPS before scanning.
        </p>
      </div>
    </div>
  );
}
