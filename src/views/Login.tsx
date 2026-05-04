import React, { useState } from "react";
import { motion } from "motion/react";
import {
  Building2,
  ArrowRight,
  Mail,
  Lock,
  CheckSquare,
  Globe,
  LayoutGrid,
} from "lucide-react";
import { cn } from "@/src/lib/utils";
import { Role } from "../types";

interface LoginProps {
  onLogin: (email: string, role: Role) => void;
  onSwitch: () => void;
  onRegisterCompany?: () => void;
}

export default function Login({
  onLogin,
  onSwitch,
  onRegisterCompany,
}: LoginProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    // Simulate role based on email for demo
    let role: Role = "employee";
    if (email.includes("super_admin")) role = "super_admin";
    else if (email.includes("owner")) role = "owner";
    else if (email.includes("admin")) role = "admin";
    else if (email.includes("hr")) role = "hr";
    onLogin(email, role);
  };

  return (
    <div className="min-h-screen bg-surface flex flex-col justify-center py-12 px-6 lg:px-8">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="sm:mx-auto sm:w-full sm:max-w-md text-center"
      >
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-primary-container text-white mb-6 shadow-2xl shadow-primary/20">
          <LayoutGrid size={32} />
        </div>
        <h2 className="text-4xl font-black text-primary tracking-tight">
          AttendanceOS
        </h2>
        <p className="mt-3 text-on-surface-variant font-medium">
          Sign in to your workspace
        </p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.1 }}
        className="mt-10 sm:mx-auto sm:w-full sm:max-w-md"
      >
        <div className="bg-white py-12 px-10 shadow-2xl shadow-primary/5 border border-outline-variant/20 rounded-[32px]">
          <form className="space-y-8" onSubmit={handleLogin}>
            <div className="space-y-2">
              <label
                className="text-[11px] font-black text-primary uppercase tracking-widest"
                htmlFor="email"
              >
                Work Email
              </label>
              <div className="relative">
                <input
                  id="email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-5 py-4 border border-outline-variant/30 rounded-2xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all placeholder:text-on-surface-variant/40 font-medium"
                  placeholder="name@company.com"
                />
              </div>
              <p className="text-[10px] text-on-surface-variant/60 italic font-medium">
                Hint: Use 'admin@test.com', 'owner@test.com',
                'super_admin@test.com' or 'hr@test.com' to see different roles.
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <label
                  className="text-[11px] font-black text-primary uppercase tracking-widest"
                  htmlFor="password"
                >
                  Password
                </label>
                <button
                  type="button"
                  className="text-[11px] font-bold text-on-surface-variant hover:text-primary transition-colors hover:underline underline-offset-4"
                >
                  Forgot?
                </button>
              </div>
              <input
                id="password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-5 py-4 border border-outline-variant/30 rounded-2xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all placeholder:text-on-surface-variant/40 font-medium"
                placeholder="••••••••"
              />
            </div>

            <div className="flex items-center">
              <input
                id="remember-me"
                type="checkbox"
                className="h-5 w-5 rounded-lg border-outline-variant/30 text-primary focus:ring-primary"
              />
              <label
                htmlFor="remember-me"
                className="ml-3 block text-sm font-bold text-on-surface-variant"
              >
                Remember my workspace
              </label>
            </div>

            <button
              type="submit"
              className="w-full py-5 bg-primary text-white font-black uppercase tracking-widest text-sm rounded-2xl shadow-xl shadow-primary/10 hover:bg-primary-container active:scale-[0.98] transition-all flex items-center justify-center gap-3"
            >
              Sign In
              <ArrowRight size={20} />
            </button>
          </form>

          <div className="mt-10">
            <div className="relative flex items-center justify-center">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-outline-variant/10"></div>
              </div>
              <span className="relative px-6 bg-white text-[11px] font-black text-on-surface-variant uppercase tracking-widest">
                Or continue with
              </span>
            </div>

            <div className="mt-8 grid grid-cols-2 gap-4">
              <button className="flex items-center justify-center gap-3 py-4 border border-outline-variant/30 rounded-2xl font-bold text-sm text-primary hover:bg-surface-container transition-colors">
                <Globe size={18} />
                Google
              </button>
              <button className="flex items-center justify-center gap-3 py-4 border border-outline-variant/30 rounded-2xl font-bold text-sm text-primary hover:bg-surface-container transition-colors">
                <Lock size={18} />
                Microsoft
              </button>
            </div>
          </div>
        </div>

        <div className="mt-10 text-center space-y-4">
          <p className="text-on-surface-variant font-medium">
            Don't have an account?{" "}
            <button
              onClick={onSwitch}
              className="font-black text-primary uppercase text-[11px] tracking-widest hover:underline underline-offset-4"
            >
              Request Access
            </button>
          </p>
          <div className="pt-4 border-t border-outline-variant/10">
            <button
              onClick={onRegisterCompany || onSwitch}
              className="flex items-center justify-center gap-2 mx-auto font-black text-primary uppercase text-[11px] tracking-widest hover:underline underline-offset-4"
            >
              <Building2 size={14} />
              Register a Company
            </button>
          </div>
        </div>
      </motion.div>
    </div>
  );
}
