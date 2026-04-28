import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Building2, ArrowRight, LayoutGrid, Info, User, Mail, Lock } from 'lucide-react';
import { cn } from '@/src/lib/utils';

interface RegisterProps {
  onSwitch: () => void;
  onRegister: () => void;
}

export default function Register({ onSwitch, onRegister }: RegisterProps) {
  const [accountType, setAccountType] = useState<'employee' | 'hr'>('hr');

  return (
    <div className="min-h-screen bg-surface flex flex-col md:flex-row antialiased overflow-hidden">
      <div className="w-full md:w-1/2 bg-primary relative flex flex-col justify-between p-12 lg:p-24 overflow-hidden min-h-[400px]">
        <div className="absolute inset-0 z-0 opacity-10 bg-cover bg-center grayscale" style={{ backgroundImage: "url('https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=2000')" }} />
        <div className="absolute inset-0 z-0 bg-gradient-to-t from-primary via-primary/80 to-transparent" />
        <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} className="relative z-10 flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-white/10 backdrop-blur-md flex items-center justify-center text-white font-bold border border-white/20"><LayoutGrid size={24} /></div>
          <span className="text-2xl font-black text-white tracking-tighter">AttendanceOS</span>
        </motion.div>
        <div className="relative z-10">
          <motion.h1 initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="text-5xl lg:text-7xl font-black text-white leading-[1.1] tracking-tight mb-8">Precision workforce management.</motion.h1>
          <motion.p initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="text-xl text-white/70 leading-relaxed font-medium">Streamline your attendance tracking, analyze workforce trends, and maintain perfect operational oversight from a single, unified dashboard.</motion.p>
        </div>
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.4 }} className="relative z-10 hidden md:flex items-center gap-6 text-white/50 text-[10px] font-black uppercase tracking-[0.2em]">
          <span>Secure Enterprise Platform</span><div className="w-1.5 h-1.5 rounded-full bg-white/30" /><span>SOC2 Compliant</span>
        </motion.div>
      </div>
      <div className="w-full md:w-1/2 bg-white flex items-center justify-center p-12 lg:p-24 overflow-y-auto">
        <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="w-full max-w-[440px] space-y-12">
          <header>
            <h2 className="text-4xl font-black text-primary tracking-tight mb-3">Create an Account</h2>
            <p className="text-on-surface-variant font-medium">Enter your details to request access to the system.</p>
          </header>
          <form className="space-y-8" onSubmit={(e) => { e.preventDefault(); onRegister(); }}>
            <div className="space-y-4">
              <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-widest pl-1">Account Type</label>
              <div className="flex p-1.5 bg-surface-container rounded-2xl border border-outline-variant/20 shadow-inner">
                {['employee', 'hr'].map((type) => (
                  <button key={type} type="button" onClick={() => setAccountType(type as any)} className={cn("flex-1 py-3 text-center text-xs font-black uppercase tracking-widest rounded-xl transition-all duration-300", accountType === type ? "bg-white text-primary shadow-lg" : "text-on-surface-variant hover:text-primary")}>
                    {type === 'hr' ? 'HR / Admin' : 'Employee'}
                  </button>
                ))}
              </div>
            </div>
            <AnimatePresence>
              {accountType === 'hr' && (
                <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-surface-container-low border border-outline-variant/30 p-6 rounded-3xl flex items-start gap-4 shadow-sm overflow-hidden">
                  <div className="bg-primary/5 p-2 rounded-xl text-primary shrink-0"><Info size={20} /></div>
                  <div className="text-sm text-on-surface-variant leading-relaxed">
                    <strong className="text-primary font-black block mb-1 uppercase tracking-widest text-[10px]">Approval Required</strong>
                    HR accounts require Super Admin approval before activation.
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
            <div className="space-y-6">
              {[ { id: 'fullName', label: 'Full Name', icon: User, placeholder: 'e.g. Alex Rivers' }, { id: 'workEmail', label: 'Work Email', icon: Mail, placeholder: 'name@company.com' }, { id: 'password', label: 'Create Password', icon: Lock, placeholder: '••••••••', type: 'password' } ].map((field) => (
                <div key={field.id} className="space-y-2">
                  <label className="text-[11px] font-black text-on-surface-variant uppercase tracking-widest pl-1" htmlFor={field.id}>{field.label}</label>
                  <div className="relative">
                    <field.icon className="absolute left-5 top-1/2 -translate-y-1/2 text-on-surface-variant/40" size={18} />
                    <input id={field.id} type={field.type || 'text'} className="w-full bg-slate-50 border border-outline-variant/30 rounded-2xl pl-12 pr-6 py-4 font-medium text-primary focus:ring-2 focus:ring-primary outline-none transition-all placeholder:text-on-surface-variant/40" placeholder={field.placeholder} />
                  </div>
                </div>
              ))}
            </div>
            <button type="submit" className="w-full bg-primary text-white font-black uppercase tracking-widest text-sm py-5 rounded-[2rem] shadow-2xl shadow-primary/20 hover:bg-primary-container active:scale-[0.98] transition-all flex items-center justify-center gap-3">
              Request Account <ArrowRight size={20} />
            </button>
          </form>
          <p className="text-center text-on-surface-variant font-medium">Already have an account? <button onClick={onSwitch} className="font-black text-primary uppercase text-[11px] tracking-widest hover:underline underline-offset-4">Log in here</button></p>
        </motion.div>
      </div>
    </div>
  );
}
