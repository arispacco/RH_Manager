export type Role =
  | "employee"
  | "hr"
  | "admin"
  | "guest"
  | "super_admin"
  | "owner";

export interface User {
  id: string;
  name: string;
  role: Role;
  email: string;
  avatar?: string;
  department?: string;
}

export interface AttendanceRecord {
  id: string;
  userId: string;
  date: string;
  clockIn: string;
  clockOut?: string;
  status: "present" | "late" | "absent";
}

export interface Company {
  id: string;
  name: string;
  domain: string;
  employees: number;
  plan: "Starter" | "Premium" | "Enterprise";
  status: "Active" | "Paused" | "Pending";
  appliedAt?: string;
  contactName?: string;
  contactEmail?: string;
}
