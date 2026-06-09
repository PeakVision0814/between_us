import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type JsonBody = Record<string, unknown>;

function json(status: number, body: JsonBody): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function parseBody(request: Request): Promise<JsonBody> {
  const contentType = request.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) {
    return {};
  }

  try {
    const parsed = await request.json();
    return parsed && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed as JsonBody
      : {};
  } catch {
    return {};
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json(405, { code: "method_not_allowed" });
  }

  const body = await parseBody(request);
  if ("user_id" in body || "userId" in body) {
    return json(400, { code: "user_id_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("[delete-account] Missing Supabase environment");
    return json(500, { code: "server_not_configured" });
  }

  const authorization = request.headers.get("authorization") ?? "";
  const accessToken = authorization.replace(/^Bearer\s+/i, "").trim();
  if (!accessToken) {
    return json(401, { code: "missing_authorization" });
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser(
    accessToken,
  );
  const user = userData.user;
  if (userError || !user) {
    return json(401, { code: "invalid_authorization" });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let auditRequestId: string | null = null;

  try {
    const { data, error } = await adminClient.rpc("prepare_account_deletion", {
      p_user_id: user.id,
    });

    if (error) {
      if ((error.message ?? "").includes("active_couple_space_required_exit")) {
        return json(409, { code: "active_couple_space_required_exit" });
      }
      console.error("[delete-account] prepare failed", error.code);
      return json(500, { code: "delete_account_failed" });
    }

    auditRequestId = typeof data === "string" ? data : null;

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      user.id,
      true,
    );

    if (deleteError) {
      console.error("[delete-account] auth delete failed", deleteError.message);
      if (auditRequestId) {
        await adminClient
          .from("account_deletion_requests")
          .update({
            status: "failed",
            reason_code: "auth_delete_failed",
          })
          .eq("id", auditRequestId);
      }
      return json(500, { code: "delete_account_failed" });
    }

    if (auditRequestId) {
      await adminClient
        .from("account_deletion_requests")
        .update({
          status: "completed",
          completed_at: new Date().toISOString(),
        })
        .eq("id", auditRequestId);
    }

    return json(200, { ok: true });
  } catch (error) {
    console.error("[delete-account] unexpected failure", error);
    if (auditRequestId) {
      await adminClient
        .from("account_deletion_requests")
        .update({
          status: "failed",
          reason_code: "unexpected_failure",
        })
        .eq("id", auditRequestId);
    }
    return json(500, { code: "delete_account_failed" });
  }
});
