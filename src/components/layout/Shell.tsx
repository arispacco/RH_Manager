import React, { useState } from "react";
import {
  LayoutGrid,
  Users,
  History,
  Building2,
  Settings,
  Bell,
  Menu,
  X,
  LogOut,
  ChevronRight,
  TrendingUp,
  FileText,
} from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { cn } from "@/src/lib/utils";
import { Role, User } from "@/src/types";

interface ShellProps {
  children: React.ReactNode;
  user: User | null;
  currentView: string;
  onNavigate: (view: string) => void;
  onLogout: () => void;
}

export default function Shell({
  children,
  user,
  currentView,
  onNavigate,
  onLogout,
}: ShellProps) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  if (!user) return <div className="min-h-screen bg-surface">{children}</div>;

  const navItems = [
    {
      id: "dashboard",
      label: "Dashboard",
      icon: LayoutGrid,
      roles: ["employee", "hr", "admin", "super_admin", "owner"],
    },
    {
      id: "employees",
      label: "Employees",
      icon: Users,
      roles: ["hr", "admin", "super_admin", "owner"],
    },
    {
      id: "records",
      label: "Attendance",
      icon: History,
      roles: ["employee", "hr"],
    },
    {
      id: "reports",
      label: "Team Reports",
      icon: FileText,
      roles: ["hr", "admin", "super_admin", "owner"],
    },
    {
      id: "analytics",
      label: "Analytics",
      icon: TrendingUp,
      roles: ["admin", "super_admin", "owner"],
    },
    {
      id: "company",
      label: "Company",
      icon: Building2,
      roles: ["hr", "admin", "super_admin", "owner"],
    },
    {
      id: "settings",
      label: "Settings",
      icon: Settings,
      roles: ["employee", "hr", "admin", "super_admin", "owner"],
    },
  ];

  const filteredNavItems = navItems.filter((item) =>
    item.roles.includes(user.role),
  );

  return (
    <div className="flex h-screen overflow-hidden bg-surface">
      {/* Mobile Sidebar Overlay */}
      <AnimatePresence>
        {isSidebarOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsSidebarOpen(false)}
            className="fixed inset-0 z-40 bg-primary/20 backdrop-blur-sm lg:hidden"
          />
        )}
      </AnimatePresence>

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-outline-variant/30 transition-transform duration-300 lg:relative lg:translate-x-0 flex flex-col",
          !isSidebarOpen && "-translate-x-full",
        )}
      >
        <div className="p-6 flex items-center gap-3 border-b border-outline-variant/10">
          <div className="h-10 w-10 rounded-xl bg-primary flex items-center justify-center text-white font-bold shadow-lg shadow-primary/20">
            {user.name.charAt(0)}
          </div>
          <div className="flex flex-col">
            <span className="font-bold text-primary truncate w-32">
              {user.name}
            </span>
            <span className="text-xs text-on-surface-variant font-medium uppercase tracking-wider">
              {user.role === "super_admin"
                ? "Super Admin"
                : user.role === "owner"
                  ? "Owner"
                  : user.role === "admin"
                    ? "Admin"
                    : user.role === "hr"
                      ? "HR Manager"
                      : "Employee"}
            </span>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto p-4 space-y-1">
          {filteredNavItems.map((item) => (
            <button
              key={item.id}
              onClick={() => {
                onNavigate(item.id);
                setIsSidebarOpen(false);
              }}
              className={cn(
                "w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group text-sm font-medium",
                currentView === item.id
                  ? "bg-primary text-white shadow-md shadow-primary/10"
                  : "text-on-surface-variant hover:bg-surface-container hover:text-primary",
              )}
            >
              <item.icon
                size={20}
                className={cn(
                  currentView === item.id
                    ? "text-white"
                    : "text-on-surface-variant group-hover:text-primary",
                )}
              />
              {item.label}
              {currentView === item.id && (
                <motion.div layoutId="activeNav" className="ml-auto">
                  <ChevronRight size={14} />
                </motion.div>
              )}
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-outline-variant/10">
          <button
            onClick={onLogout}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-on-surface-variant hover:bg-red-50 hover:text-red-600 transition-colors text-sm font-medium"
          >
            <LogOut size={20} />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="h-16 bg-white/80 backdrop-blur-md border-b border-outline-variant/20 flex items-center justify-between px-6 z-30">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setIsSidebarOpen(true)}
              className="lg:hidden p-2 hover:bg-surface-container rounded-lg"
            >
              <Menu size={24} />
            </button>
            <h1 className="text-xl font-bold tracking-tighter text-primary">
              AttendanceOS
            </h1>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2 text-on-surface-variant hover:bg-surface-container rounded-full relative">
              <Bell size={20} />
              <span className="absolute top-2 right-2.5 w-2 h-2 bg-red-500 rounded-full border-2 border-white" />
            </button>
          </div>
        </header>

        {/* Scrollable Area */}
        <main className="flex-1 overflow-y-auto pb-20 lg:pb-0">{children}</main>

        {/* Mobile Navigation Bar */}
        <nav className="lg:hidden fixed bottom-0 left-0 right-0 h-16 bg-white/90 backdrop-blur-md border-t border-outline-variant/20 flex justify-around items-center px-4 z-40">
          {filteredNavItems.slice(0, 4).map((item) => (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={cn(
                "flex flex-col items-center gap-1 transition-all",
                currentView === item.id
                  ? "text-primary px-4 py-1 bg-primary/5 rounded-xl"
                  : "text-on-surface-variant",
              )}
            >
              <item.icon size={20} />
              <span className="text-[10px] font-bold uppercase tracking-wider">
                {item.label}
              </span>
            </button>
          ))}
        </nav>
      </div>
    </div>
  );
}
