import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ClockOutRequest {
  latitude: number;
  longitude: number;
}

interface ClockOutResponse {
  success: boolean;
  log_id?: string;
  message?: string;
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

    // Parse request
    const { latitude, longitude }: ClockOutRequest = await req.json();

    if (latitude === undefined || longitude === undefined) {
      throw new Error("Missing latitude or longitude");
    }

    // Call clock_out function
    const { data, error } = await supabaseClient
      .rpc("clock_out", {
        p_user_id: user.id,
        p_latitude: latitude,
        p_longitude: longitude,
      });

    if (error) {
      throw new Error(`Clock out failed: ${error.message}`);
    }

    const response: ClockOutResponse = data;

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: response.success ? 200 : 400,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);

    const response: ClockOutResponse = {
      success: false,
      error: message,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
