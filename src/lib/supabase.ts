/**
 * Supabase Client for RH_Manager Frontend
 * Provides all backend interactions with proper typing
 */

import { createClient, SupabaseClient } from "@supabase/supabase-js";

export type AppRole = "super_admin" | "owner" | "admin" | "hr" | "employee" | "kiosk";
export type AttendanceStatus = "on_time" | "late" | "absent" | "excused" | "half_day";
export type EmployeeStatus = "active" | "inactive" | "on_leave" | "terminated";

export interface Profile {
  id: string;
  email?: string;
  full_name: string;
  role: AppRole;
  company_id: string;
  department?: string;
  phone?: string;
  employee_status: EmployeeStatus;
  is_active: boolean;
  avatar_url?: string;
  created_at: string;
  updated_at: string;
}

export interface Company {
  id: string;
  name: string;
  domain?: string;
  owner_id?: string;
  created_at: string;
  updated_at: string;
}

export interface QRConfig {
  id: string;
  company_id: string;
  rotation_seconds: number;
  office_lat?: number;
  office_lng?: number;
  radius_meters: number;
  is_geofencing_enabled: boolean;
  is_totp_enabled: boolean;
  updated_at: string;
}

export interface AttendanceLog {
  id: string;
  user_id: string;
  company_id: string;
  date: string;
  clock_in: string;
  clock_out?: string;
  clock_in_lat?: number;
  clock_in_lng?: number;
  clock_out_lat?: number;
  clock_out_lng?: number;
  status: AttendanceStatus;
  qr_token?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
  duration_hours?: number;
}

export interface ClockInRequest {
  latitude: number;
  longitude: number;
}

export interface ClockOutRequest {
  latitude: number;
  longitude: number;
}

export interface CreateUserRequest {
  email: string;
  password: string;
  full_name: string;
  role: AppRole;
}

export class SupabaseBackend {
  private client: SupabaseClient;
  private functionsUrl: string;

  constructor() {
    const url = import.meta.env.VITE_SUPABASE_URL ||
      process.env.REACT_APP_SUPABASE_URL ||
      "http://localhost:54331";
    const key = import.meta.env.VITE_SUPABASE_ANON_KEY ||
      process.env.REACT_APP_SUPABASE_ANON_KEY ||
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMzAzMDMzMywiZXhwIjoyMDAwMDAwMDAwfQ.your_test_key";

    this.client = createClient(url, key);
    this.functionsUrl = url;
  }

  /**
   * AUTH FUNCTIONS
   */

  async register(
    email: string,
    password: string,
    full_name: string,
    company_id: string,
    role: AppRole = "employee"
  ) {
    try {
      const { data, error } = await this.client.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name,
            company_id,
            role,
          },
        },
      });

      if (error) throw error;
      return { success: true, user: data.user };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async login(email: string, password: string) {
    try {
      const { data, error } = await this.client.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;
      return { success: true, user: data.user, session: data.session };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async logout() {
    try {
      const { error } = await this.client.auth.signOut();
      if (error) throw error;
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async getCurrentUser() {
    try {
      const { data: { user }, error } = await this.client.auth.getUser();
      if (error) throw error;
      return { success: true, user };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * PROFILE FUNCTIONS
   */

  async getProfile(): Promise<{
    success: boolean;
    profile?: Profile;
    error?: string;
  }> {
    try {
      const { data: { user }, error: userError } =
        await this.client.auth.getUser();

      if (userError || !user) throw new Error("Not authenticated");

      const { data, error } = await this.client
        .from("profiles")
        .select("*")
        .eq("id", user.id)
        .single();

      if (error) throw error;
      return { success: true, profile: data };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async updateProfile(updates: Partial<Profile>) {
    try {
      const { data: { user }, error: userError } =
        await this.client.auth.getUser();

      if (userError || !user) throw new Error("Not authenticated");

      const { data, error } = await this.client
        .from("profiles")
        .update(updates)
        .eq("id", user.id)
        .select()
        .single();

      if (error) throw error;
      return { success: true, profile: data };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * ATTENDANCE FUNCTIONS
   */

  async clockIn(latitude: number, longitude: number): Promise<{
    success: boolean;
    log_id?: string;
    message?: string;
    error?: string;
    distance?: number;
  }> {
    try {
      const { data: { session }, error: sessionError } =
        await this.client.auth.getSession();

      if (sessionError || !session) throw new Error("Not authenticated");

      const response = await fetch(
        `${this.functionsUrl}/functions/v1/auth/clock-in`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ latitude, longitude }),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Clock in failed");
      }

      return data;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async clockOut(latitude: number, longitude: number): Promise<{
    success: boolean;
    log_id?: string;
    message?: string;
    error?: string;
  }> {
    try {
      const { data: { session }, error: sessionError } =
        await this.client.auth.getSession();

      if (sessionError || !session) throw new Error("Not authenticated");

      const response = await fetch(
        `${this.functionsUrl}/functions/v1/auth/clock-out`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ latitude, longitude }),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Clock out failed");
      }

      return data;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async getAttendanceHistory(
    days: number = 30
  ): Promise<{ success: boolean; attendance?: AttendanceLog[]; error?: string }> {
    try {
      const { data: { session }, error: sessionError } =
        await this.client.auth.getSession();

      if (sessionError || !session) throw new Error("Not authenticated");

      const response = await fetch(
        `${this.functionsUrl}/functions/v1/auth/get-attendance?days=${days}`,
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${session.access_token}`,
          },
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Failed to fetch attendance");
      }

      return data;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * ADMIN FUNCTIONS
   */

  async createUser(request: CreateUserRequest): Promise<{
    success: boolean;
    user?: { id: string; email: string };
    error?: string;
  }> {
    try {
      const { data: { session }, error: sessionError } =
        await this.client.auth.getSession();

      if (sessionError || !session) throw new Error("Not authenticated");

      const response = await fetch(
        `${this.functionsUrl}/functions/v1/auth/create-user`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${session.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(request),
        }
      );

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Failed to create user");
      }

      return data;
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async getCompanyEmployees(companyId: string): Promise<{
    success: boolean;
    employees?: Profile[];
    error?: string;
  }> {
    try {
      const { data, error } = await this.client
        .from("profiles")
        .select("*")
        .eq("company_id", companyId)
        .order("full_name");

      if (error) throw error;
      return { success: true, employees: data };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * COMPANY FUNCTIONS
   */

  async getCompany(companyId: string): Promise<{
    success: boolean;
    company?: Company;
    error?: string;
  }> {
    try {
      const { data, error } = await this.client
        .from("companies")
        .select("*")
        .eq("id", companyId)
        .single();

      if (error) throw error;
      return { success: true, company: data };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  /**
   * QR CONFIG FUNCTIONS
   */

  async getQRConfig(companyId: string): Promise<{
    success: boolean;
    config?: QRConfig;
    error?: string;
  }> {
    try {
      const { data, error } = await this.client
        .from("qr_configs")
        .select("*")
        .eq("company_id", companyId)
        .single();

      if (error) throw error;
      return { success: true, config: data };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }
}

// Singleton instance
export const supabaseBackend = new SupabaseBackend();
