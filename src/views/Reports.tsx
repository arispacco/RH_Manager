import React from 'react';
import { motion } from 'motion/react';
import { 
  Calendar, 
  Download, 
  Clock, 
  ChevronDown,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  FileText,
  Filter
} from 'lucide-react';
import { cn } from '@/src/lib/utils';

const logs = [
  { id: '1', date: 'Monday, Oct 23', timeRange: '08:55 AM - 05:05 PM', status: 'present', hours: '8h 10m' },
  { id: '2', date: 'Tuesday, Oct 24', timeRange: '09:15 AM - 05:30 PM', status: 'late', hours: '8h 15m' },
  { id: '3', date: 'Wednesday, Oct 25', timeRange: '08:58 AM - 05:02 PM', status: 'present', hours: '8h 04m' },
];

export default function Reports() {
  return (
    <div className="p-6 lg:p-10 max-w-7xl mx-auto space-y-10">
      <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h2 className="text-4xl font-bold text-primary tracking-tight">Attendance Reports</h2>
          <p className="text-on-surface-variant mt-1 font-medium">Detailed historical logs and trend analysis.</p>
        </div>
        <div className="flex gap-4">
          <button className="bg-white border border-outline-variant/30 px-6 py-3 rounded-2xl text-sm font-bold text-primary shadow-sm flex items-center gap-2 hover:bg-surface-container transition-colors">
            <Filter size={18} />
            Filters
          </button>
          <button className="bg-primary text-white px-6 py-3 rounded-2xl text-sm font-bold shadow-xl shadow-primary/10 flex items-center gap-2 hover:bg-primary-container transition-all">
            <Download size={18} />
            Export Report
          </button>
        </div>
      </header>

      {/* Filter Tabs */}
      <div className="flex gap-4 overflow-x-auto pb-4 -mx-6 px-6 lg:mx-0 lg:px-0 scrollbar-hide">
        <button className="bg-primary text-white px-6 py-2.5 rounded-full text-xs font-black uppercase tracking-widest whitespace-nowrap shadow-lg shadow-primary/10 border border-primary">Last 7 Days</button>
        <button className="bg-white text-on-surface-variant px-6 py-2.5 rounded-full text-xs font-bold uppercase tracking-widest whitespace-nowrap border border-outline-variant/30 hover:border-primary transition-colors">October</button>
        <div className="w-px h-6 bg-outline-variant/30 self-center" />
        <button className="bg-white text-on-surface-variant px-6 py-2.5 rounded-full text-xs font-bold uppercase tracking-widest whitespace-nowrap border border-outline-variant/30 flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-emerald-500" />
          Present
        </button>
        <button className="bg-white text-on-surface-variant px-6 py-2.5 rounded-full text-xs font-bold uppercase tracking-widest whitespace-nowrap border border-outline-variant/30 flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-amber-500" />
          Late
        </button>
      </div>

      {/* Summary Stat Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {[
          { label: 'Total Days', value: '7', color: 'bg-blue-50', text: 'text-blue-700' },
          { label: 'Present', value: '5', color: 'bg-emerald-50', text: 'text-emerald-700', active: true },
          { label: 'Late', value: '2', color: 'bg-amber-50', text: 'text-amber-700' },
          { label: 'Absent', value: '0', color: 'bg-slate-50', text: 'text-slate-700' },
        ].map((stat, i) => (
          <div key={i} className="bg-white p-8 rounded-[32px] border border-outline-variant/30 shadow-sm flex flex-col justify-between h-40 relative group overflow-hidden">
             <div className={cn("absolute -right-6 -top-6 w-20 h-20 rounded-full opacity-40 blur-2xl transition-transform duration-500 group-hover:scale-150", stat.color)} />
             <span className="text-xs font-black text-on-surface-variant uppercase tracking-widest relative z-10">{stat.label}</span>
             <span className="text-4xl font-black text-primary relative z-10">{stat.value}</span>
          </div>
        ))}
      </div>

      {/* Log Details Section */}
      <section className="bg-white rounded-[32px] border border-outline-variant/30 shadow-sm overflow-hidden">
        <div className="px-10 py-8 border-b border-outline-variant/10 bg-surface-container-low/20">
          <h3 className="text-xl font-bold text-primary">Log Details</h3>
        </div>
        <div className="divide-y divide-outline-variant/10">
          {logs.map((log) => (
            <div key={log.id} className="p-8 hover:bg-surface-container-low/10 transition-colors flex flex-col md:flex-row md:items-center justify-between gap-6">
              <div className="flex items-center gap-6">
                <div className="h-16 w-16 bg-surface-container rounded-2xl flex items-center justify-center text-primary shadow-sm">
                  <Calendar size={28} />
                </div>
                <div>
                  <h4 className="text-xl font-bold text-primary">{log.date}</h4>
                  <div className="flex items-center gap-3 text-on-surface-variant font-medium mt-1">
                    <Clock size={16} />
                    <span className="font-mono">{log.timeRange}</span>
                    <span className="mx-2 opacity-30">•</span>
                    <span className="text-primary font-bold">{log.hours}</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-4">
                 <span className={cn(
                   "inline-flex items-center px-6 py-2.5 rounded-2xl font-bold text-[10px] uppercase tracking-widest gap-2 border shadow-sm",
                   log.status === 'present' ? "bg-emerald-50 text-emerald-700 border-emerald-100" :
                   log.status === 'late' ? "bg-amber-50 text-amber-700 border-amber-100" :
                   "bg-slate-50 text-slate-500 border-slate-100"
                 )}>
                   {log.status === 'present' ? <CheckCircle2 size={14} /> : log.status === 'late' ? <AlertTriangle size={14} /> : <XCircle size={14} />}
                   {log.status}
                 </span>
                 <button className="p-3 text-on-surface-variant hover:bg-surface-container rounded-xl transition-colors">
                   <ChevronDown size={20} />
                 </button>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
