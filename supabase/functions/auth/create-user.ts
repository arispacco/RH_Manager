import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CreateUserRequest {
  email: string;
  password: string;
  full_name: string;
  role: "employee" | "hr" | "admin" | "kiosk";
}

interface CreateUserResponse {
  success: boolean;
  user?: { id: string; email: string };
  error?: string;
}

serve(async (req): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    // Create Supabase client with user context
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get current user
    const { data: { user: caller }, error: callerError } =
      await supabaseClient.auth.getUser();

    if (callerError || !caller) {
      throw new Error("Unauthorized");
    }

    // Check if caller is admin
    const { data: callerProfile, error: profileError } = await supabaseClient
      .from("profiles")
      .select("role, company_id")
      .eq("id", caller.id)
      .single();

    if (profileError || !callerProfile) {
      throw new Error("Caller profile not found");
    }

    const isAdmin = ["admin", "super_admin"].includes(callerProfile.role);
    if (!isAdmin) {
      throw new Error("Forbidden: Only admins can create users");
    }

    // Parse request body
    const { email, password, full_name, role }: CreateUserRequest =
      await req.json();

    // Validate input
    if (!email || !password || !full_name || !role) {
      throw new Error("Missing required fields");
    }

    // Create admin client
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Create new user with admin API
    const { data: newAuthUser, error: createUserError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name,
          role,
          company_id: callerProfile.company_id,
        },
      });

    if (createUserError || !newAuthUser.user) {
      throw new Error(`Failed to create user: ${createUserError?.message}`);
    }

    const response: CreateUserResponse = {
      success: true,
      user: {
        id: newAuthUser.user.id,
        email: newAuthUser.user.email ?? "",
      },
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 201,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);

    const response: CreateUserResponse = {
      success: false,
      error: message,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
