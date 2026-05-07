import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface AttendanceRecord {
  id: string;
  date: string;
  clock_in: string;
  clock_out?: string;
  status: string;
  duration_hours?: number;
}

interface AttendanceResponse {
  success: boolean;
  attendance?: AttendanceRecord[];
  error?: string;
}

serve(async (req): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify authorization
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get current user
    const { data: { user }, error: userError } =
      await supabaseClient.auth.getUser();

    if (userError || !user) {
      throw new Error("Unauthorized");
    }

    // Parse query params
    const url = new URL(req.url);
    const days = parseInt(url.searchParams.get("days") ?? "30");
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // Get attendance logs
    const { data: logs, error: logsError } = await supabaseClient
      .from("attendance_logs")
      .select("id, date, clock_in, clock_out, status")
      .eq("user_id", user.id)
      .gte("date", startDate.toISOString().split("T")[0])
      .order("date", { ascending: false });

    if (logsError) {
      throw new Error(`Failed to fetch attendance: ${logsError.message}`);
    }

    // Calculate duration for each log
    const attendance = (logs ?? []).map((log) => {
      let duration_hours: number | undefined = undefined;

      if (log.clock_out) {
        const clockIn = new Date(log.clock_in);
        const clockOut = new Date(log.clock_out);
        const durationMs = clockOut.getTime() - clockIn.getTime();
        duration_hours = Math.round((durationMs / (1000 * 60 * 60)) * 100) / 100;
      }

      return {
        id: log.id,
        date: log.date,
        clock_in: log.clock_in,
        clock_out: log.clock_out,
        status: log.status,
        duration_hours,
      };
    });

    const response: AttendanceResponse = {
      success: true,
      attendance,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);

    const response: AttendanceResponse = {
      success: false,
      error: message,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
