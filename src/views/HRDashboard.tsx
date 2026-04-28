import React from 'react';
import { motion } from 'motion/react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  Cell
} from 'recharts';
import { 
  ArrowRight, 
  Clock, 
  CheckCircle2, 
  Users, 
  MoreVertical,
  QrCode,
  Camera
} from 'lucide-react';

const attendanceData = [
  { name: 'Mon', present: 85, absent: 15 },
  { name: 'Tue', present: 92, absent: 8 },
  { name: 'Wed', present: 88, absent: 12 },
  { name: 'Thu', present: 95, absent: 5 },
  { name: 'Fri', present: 0, absent: 0 },
];

const teamPresence = [
  { id: '1', name: 'Sarah Mitchell', department: 'Engineering', timeIn: '08:45 AM', status: 'present', initials: 'SM' },
  { id: '2', name: 'James Davis', department: 'Marketing', timeIn: '09:12 AM', status: 'late', initials: 'JD' },
  { id: '3', name: 'Emily Wong', department: 'Sales', timeIn: '--:-- --', status: 'absent', initials: 'EW' },
  { id: '4', name: 'Michael Chang', department: 'Operations', timeIn: '08:55 AM', status: 'present', initials: 'MC' },
];

export default function HRDashboard() {
  return (
    <div className="p-6 lg:p-10 max-w-7xl mx-auto space-y-10">
      <header>
        <h2 className="text-4xl font-bold text-primary tracking-tight">Overview</h2>
        <p className="text-on-surface-variant mt-1">Real-time workforce insights for October 24</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Weekly Attendance Chart */}
        <div className="lg:col-span-2 bg-white rounded-3xl border border-outline-variant/30 shadow-sm p-8 flex flex-col">
          <div className="flex items-center justify-between mb-10">
            <h3 className="text-xl font-bold text-primary">Weekly Attendance Trends</h3>
            <div className="flex items-center gap-6">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-secondary" />
                <span className="text-sm font-medium text-on-surface-variant">Present</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-surface-container-high" />
                <span className="text-sm font-medium text-on-surface-variant">Absent</span>
              </div>
            </div>
          </div>
          
          <div className="h-64 mt-auto">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={attendanceData} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{ fill: '#64748b', fontSize: 12, fontWeight: 500 }}
                  dy={10}
                />
                <YAxis hide />
                <Tooltip 
                  cursor={{ fill: 'transparent' }}
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                />
                <Bar dataKey="present" stackId="a" fill="#006c49" radius={[4, 4, 0, 0]} barSize={40} />
                <Bar dataKey="absent" stackId="a" fill="#dce9ff" radius={[4, 4, 0, 0]} barSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Check-in Station Card */}
        <motion.div 
          whileHover={{ y: -5 }}
          className="bg-primary-container rounded-3xl shadow-xl shadow-primary/20 p-8 flex flex-col justify-between text-white relative overflow-hidden group"
        >
          <div className="absolute -right-12 -top-12 w-48 h-48 bg-primary rounded-full opacity-30 blur-3xl pointer-events-none" />
          
          <div>
            <div className="w-14 h-14 bg-white/10 rounded-2xl flex items-center justify-center mb-8 backdrop-blur-md">
              <QrCode size={32} className="text-secondary-container" />
            </div>
            <h2 className="text-3xl font-bold mb-3">Check-in Station</h2>
            <p className="text-white/70 mb-10 leading-relaxed">Deploy QR scanner for immediate employee localized check-in processing.</p>
          </div>

          <button className="w-full bg-secondary text-white font-bold py-5 rounded-2xl flex items-center justify-center gap-3 hover:bg-secondary/90 active:scale-[0.98] transition-all shadow-lg shadow-black/10">
            <Camera size={20} />
            Launch Scanner UI
          </button>
        </motion.div>

        {/* Real-time Presence Table */}
        <div className="lg:col-span-3 bg-white rounded-3xl border border-outline-variant/30 shadow-sm overflow-hidden">
          <div className="p-8 border-b border-outline-variant/10 flex items-center justify-between">
            <h3 className="text-xl font-bold text-primary">Real-time Presence</h3>
            <button className="text-secondary font-bold text-sm flex items-center gap-1 hover:underline underline-offset-4">
              View Full Log
              <ArrowRight size={16} />
            </button>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-surface-container-low/30 border-b border-outline-variant/10">
                  <th className="py-5 px-8 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest">Employee</th>
                  <th className="py-5 px-8 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest">Department</th>
                  <th className="py-5 px-8 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest">Time In</th>
                  <th className="py-5 px-8 text-[11px] font-bold text-on-surface-variant uppercase tracking-widest text-right">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/10">
                {teamPresence.map((employee) => (
                  <tr key={employee.id} className="hover:bg-surface-container-low/20 transition-colors group">
                    <td className="py-5 px-8 flex items-center gap-4">
                      <div className={cn(
                        "w-10 h-10 rounded-full flex items-center justify-center font-bold text-xs shadow-sm",
                        employee.id === '1' ? "bg-blue-100 text-blue-600" :
                        employee.id === '2' ? "bg-purple-100 text-purple-600" :
                        employee.id === '4' ? "bg-indigo-100 text-indigo-600" : "bg-slate-100 text-slate-600"
                      )}>
                        {employee.initials}
                      </div>
                      <span className="font-semibold text-primary">{employee.name}</span>
                    </td>
                    <td className="py-5 px-8 text-on-surface-variant font-medium">{employee.department}</td>
                    <td className="py-5 px-8 text-on-surface-variant font-mono font-medium">{employee.timeIn}</td>
                    <td className="py-5 px-8 text-right">
                      <span className={cn(
                        "inline-flex items-center px-4 py-1.5 rounded-full font-bold text-[10px] uppercase tracking-wider gap-2 border",
                        employee.status === 'present' ? "bg-emerald-50 text-emerald-700 border-emerald-100" :
                        employee.status === 'late' ? "bg-amber-50 text-amber-700 border-amber-100" :
                        "bg-slate-50 text-slate-500 border-slate-100"
                      )}>
                        <div className={cn(
                          "w-1.5 h-1.5 rounded-full",
                          employee.status === 'present' ? "bg-emerald-600" :
                          employee.status === 'late' ? "bg-amber-600" : "bg-slate-400"
                        )} />
                        {employee.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
