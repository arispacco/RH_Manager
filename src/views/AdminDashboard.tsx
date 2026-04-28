import React from 'react';
import { motion } from 'motion/react';
import { 
  Building2, 
  MoreVertical, 
  UserPlus, 
  Search,
  CheckCircle2,
  XCircle,
  Mail,
  User,
  Globe
} from 'lucide-react';
import { cn } from '@/src/lib/utils';
import { Company } from '@/src/types';

const pendingApprovals: Company[] = [
  { id: '1', name: 'Nexus Technologies', domain: 'nexus-tech.com', employees: 325, plan: 'Enterprise', status: 'Pending', appliedAt: '2h ago', contactName: 'Sarah Jenkins', contactEmail: 'sarah@nexus-tech.com' },
  { id: '2', name: 'Aura Logistics', domain: 'auralogistics.co.uk', employees: 120, plan: 'Premium', status: 'Pending', appliedAt: '5h ago', contactName: 'David Chen', contactEmail: 'd.chen@auralogistics.co.uk' },
  { id: '3', name: 'Vanguard Retail', domain: 'vanguard-retail.com', employees: 550, plan: 'Enterprise', status: 'Pending', appliedAt: '1d ago', contactName: 'Marcus Thorne', contactEmail: 'admin@vanguard-retail.com' },
];

const activeWorkspaces: Company[] = [
  { id: 'a1', name: 'Omni Corp', domain: 'omnicorp.inc', employees: 1245, plan: 'Enterprise', status: 'Active' },
  { id: 'a2', name: 'Stark Industries', domain: 'stark.com', employees: 432, plan: 'Premium', status: 'Active' },
  { id: 'a3', name: 'Wayne Enterprises', domain: 'wayne.corp', employees: 48, plan: 'Starter', status: 'Paused' },
];

export default function AdminDashboard() {
  return (
    <div className="p-6 lg:p-10 max-w-7xl mx-auto space-y-12">
      <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
        <div>
          <h2 className="text-4xl font-bold text-primary tracking-tight">Platform Overview</h2>
          <p className="text-on-surface-variant mt-1 font-medium">Manage global company accounts and pending workspace approvals.</p>
        </div>
        <div className="relative w-full md:w-96">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant" size={20} />
          <input 
            className="w-full bg-white border border-outline-variant/30 rounded-2xl pl-12 pr-4 py-3.5 text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary shadow-sm transition-all"
            placeholder="Search companies or domains..."
          />
        </div>
      </header>

      {/* Pending Approvals */}
      <section>
        <div className="flex items-center justify-between mb-8">
          <h3 className="text-xl font-bold text-primary flex items-center gap-3">
            Pending Approvals
            <span className="bg-red-50 text-red-600 text-[10px] font-black uppercase tracking-widest px-3 py-1 rounded-full border border-red-100">3 New</span>
          </h3>
          <button className="text-sm font-bold text-secondary hover:underline underline-offset-4">View All</button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
          {pendingApprovals.map((company) => (
            <motion.div 
              key={company.id}
              whileHover={{ scale: 1.01 }}
              className="bg-white rounded-3xl p-8 border border-outline-variant/30 shadow-sm flex flex-col justify-between hover:shadow-xl hover:shadow-primary/5 transition-all"
            >
              <div>
                <div className="flex justify-between items-start mb-6">
                  <div className="h-14 w-14 rounded-2xl bg-surface-container flex items-center justify-center text-primary font-bold text-2xl shadow-sm">
                    {company.name.charAt(0)}
                  </div>
                  <span className="text-[11px] font-bold text-on-surface-variant uppercase tracking-wider">{company.appliedAt}</span>
                </div>
                
                <h4 className="text-2xl font-bold text-primary mb-1 tracking-tight">{company.name}</h4>
                <p className="text-sm text-on-surface-variant font-medium mb-6 flex items-center gap-2">
                   <Globe size={14} />
                   {company.domain} • {company.employees} employees
                </p>

                <div className="space-y-3 mb-8">
                  <div className="flex items-center text-sm font-medium text-on-surface gap-3">
                    <User size={18} className="text-on-surface-variant" />
                    {company.contactName}
                  </div>
                  <div className="flex items-center text-sm font-medium text-on-surface gap-3">
                    <Mail size={18} className="text-on-surface-variant" />
                    {company.contactEmail}
                  </div>
                </div>
              </div>

              <div className="flex gap-4">
                <button className="flex-1 bg-secondary text-white font-bold py-3.5 rounded-2xl hover:bg-secondary/90 transition-all flex items-center justify-center gap-2">
                  <CheckCircle2 size={18} />
                  Approve
                </button>
                <button className="flex-1 bg-surface-container text-primary font-bold py-3.5 rounded-2xl hover:bg-red-50 hover:text-red-600 hover:border-red-100 transition-all border border-outline-variant/10 flex items-center justify-center gap-2">
                  <XCircle size={18} />
                  Reject
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Active Workspaces Table */}
      <section>
        <h3 className="text-xl font-bold text-primary mb-8">Active Workspaces</h3>
        <div className="bg-white border border-outline-variant/30 rounded-3xl shadow-sm overflow-hidden">
          <div className="grid grid-cols-12 gap-4 px-8 py-5 bg-surface-container-low/30 border-b border-outline-variant/10 font-bold text-[11px] text-on-surface-variant uppercase tracking-widest">
            <div className="col-span-5 md:col-span-4">Company</div>
            <div className="col-span-3 hidden md:block">Plan Tier</div>
            <div className="col-span-4 md:col-span-3">Users</div>
            <div className="col-span-3 md:col-span-2 text-right">Status</div>
          </div>

          <div className="divide-y divide-outline-variant/10">
            {activeWorkspaces.map((company) => (
              <div key={company.id} className="grid grid-cols-12 gap-4 px-8 py-6 items-center hover:bg-surface-container-low/20 transition-colors group">
                <div className="col-span-5 md:col-span-4 flex items-center">
                  <div className="h-10 w-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold text-sm mr-4 shadow-sm">
                    {company.name.charAt(0)}
                  </div>
                  <div className="truncate">
                    <p className="font-bold text-primary">{company.name}</p>
                    <p className="text-xs text-on-surface-variant font-medium">{company.domain}</p>
                  </div>
                </div>
                
                <div className="col-span-3 hidden md:flex items-center">
                  <span className={cn(
                    "px-3 py-1 rounded-lg font-bold text-[10px] uppercase tracking-wider",
                    company.plan === 'Enterprise' ? "bg-primary text-white" :
                    company.plan === 'Premium' ? "bg-indigo-50 text-indigo-700" : "bg-slate-100 text-slate-700"
                  )}>
                    {company.plan}
                  </span>
                </div>

                <div className="col-span-4 md:col-span-3 font-semibold text-sm text-primary">
                  {Math.floor(company.employees * 0.8)} / {company.employees}
                </div>

                <div className="col-span-3 md:col-span-2 flex justify-end items-center gap-4">
                  <span className={cn(
                    "px-3 py-1.5 rounded-full font-bold text-[10px] uppercase tracking-wider flex items-center gap-1.5",
                    company.status === 'Active' ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-500"
                  )}>
                    <div className={cn("w-1.5 h-1.5 rounded-full", company.status === 'Active' ? "bg-emerald-600" : "bg-slate-400")} />
                    {company.status}
                  </span>
                  <button className="text-on-surface-variant hover:text-primary transition-opacity opacity-0 group-hover:opacity-100 p-1">
                    <MoreVertical size={20} />
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="p-6 border-t border-outline-variant/10 flex justify-center">
             <button className="text-sm font-bold text-secondary hover:underline underline-offset-4">Load More Companies</button>
          </div>
        </div>
      </section>
    </div>
  );
}
