// Deletes the calling user's account (App Store rule 5.1.1(v)).
// The service-role key lives only on the server, never in the app.
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: { user }, error } = await admin.auth.getUser(jwt);
  if (error || !user) return new Response("Unauthorized", { status: 401 });
  const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
  return new Response(delErr ? delErr.message : "ok", { status: delErr ? 500 : 200 });
});
