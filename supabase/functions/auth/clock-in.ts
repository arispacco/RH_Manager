import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ClockInRequest {
  latitude: number;
  longitude: number;
}

interface ClockInResponse {
  success: boolean;
  log_id?: string;
  message?: string;
  error?: string;
  distance?: number;
  allowed_radius?: number;
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
    const { latitude, longitude }: ClockInRequest = await req.json();

    if (latitude === undefined || longitude === undefined) {
      throw new Error("Missing latitude or longitude");
    }

    // Call clock_in function
    const { data, error } = await supabaseClient
      .rpc("clock_in", {
        p_user_id: user.id,
        p_latitude: latitude,
        p_longitude: longitude,
      });

    if (error) {
      throw new Error(`Clock in failed: ${error.message}`);
    }

    const response: ClockInResponse = data;

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: response.success ? 200 : 400,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);

    const response: ClockInResponse = {
      success: false,
      error: message,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
