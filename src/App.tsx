/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from "react";
import { AnimatePresence, motion } from "motion/react";
import Shell from "./components/layout/Shell";
import Login from "./views/Login";
import Register from "./views/Register";
import EmployeeDashboard from "./views/EmployeeDashboard";
import HRDashboard from "./views/HRDashboard";
import AdminDashboard from "./views/AdminDashboard";
import Reports from "./views/Reports";
import { User, Role } from "./types";

export default function App() {
  const [user, setUser] = useState<User | null>(null);
  const [view, setView] = useState("dashboard");
  const [authScreen, setAuthScreen] = useState<"login" | "register">("login");
  const [registerType, setRegisterType] = useState<
    "employee" | "hr" | "company"
  >("employee");

  const handleLogin = (email: string, role: Role) => {
    let name = "Sarah Mitchell";
    if (role === "admin") name = "Alex Rivers";
    else if (role === "hr") name = "Sarah Jenkins";
    else if (role === "super_admin") name = "Super Admin";
    else if (role === "owner") name = "Company Owner";

    const mockUser: User = {
      id: "1",
      name,
      email,
      role,
      department: role === "hr" ? "HR" : "Engineering",
    };
    setUser(mockUser);
    setView("dashboard");
  };

  const handleLogout = () => {
    setUser(null);
    setAuthScreen("login");
    setView("dashboard");
  };

  const renderView = () => {
    if (!user) return null;

    switch (view) {
      case "dashboard":
        if (["admin", "super_admin", "owner"].includes(user.role))
          return <AdminDashboard />;
        if (user.role === "hr") return <HRDashboard />;
        return <EmployeeDashboard user={user} />;
      case "reports":
        return <Reports />;
      case "employees":
        return (
          <div className="p-10">
            <h2 className="text-3xl font-bold">Employee Directory</h2>
            <p>Coming soon...</p>
          </div>
        );
      case "records":
        return <Reports />;
      case "settings":
        return (
          <div className="p-10">
            <h2 className="text-3xl font-bold">Settings</h2>
            <p>Coming soon...</p>
          </div>
        );
      default:
        return <div>View not found</div>;
    }
  };

  if (!user) {
    return (
      <AnimatePresence mode="wait">
        {authScreen === "login" ? (
          <motion.div
            key="login"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <Login
              onLogin={handleLogin}
              onSwitch={() => {
                setAuthScreen("register");
                setRegisterType("employee");
              }}
              onRegisterCompany={() => {
                setAuthScreen("register");
                setRegisterType("company");
              }}
            />
          </motion.div>
        ) : (
          <motion.div
            key="register"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <Register
              onSwitch={() => setAuthScreen("login")}
              onRegister={() => setAuthScreen("login")}
              initialAccountType={registerType}
            />
          </motion.div>
        )}
      </AnimatePresence>
    );
  }

  return (
    <Shell
      user={user}
      currentView={view}
      onNavigate={setView}
      onLogout={handleLogout}
    >
      <AnimatePresence mode="wait">
        <motion.div
          key={view}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.2 }}
        >
          {renderView()}
        </motion.div>
      </AnimatePresence>
    </Shell>
  );
}
