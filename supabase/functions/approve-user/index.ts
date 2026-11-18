import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
Deno.serve(async (req) => {
 if(req.method!=="POST") return new Response("Method not allowed",{status:405});
 const url=Deno.env.get("SUPABASE_URL")!, anon=Deno.env.get("SUPABASE_ANON_KEY")!, service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
 const auth=req.headers.get("Authorization")??"";
 const caller=createClient(url,anon,{global:{headers:{Authorization:auth}}});
 const {data:{user},error}=await caller.auth.getUser();
 if(error||!user) return Response.json({error:"Unauthorized"},{status:401});
 const admin=createClient(url,service);
 const {data:role}=await admin.from("user_roles").select("role").eq("user_id",user.id).eq("role","admin").maybeSingle();
 if(!role) return Response.json({error:"Admin role required"},{status:403});
 const body=await req.json(); const target=String(body.user_id??""); const status=body.status;
 if(!target||!["approved","rejected","suspended"].includes(status)) return Response.json({error:"Invalid user_id or status"},{status:400});
 const {error:updateError}=await admin.from("profiles").update({approval_status:status}).eq("id",target);
 if(updateError) return Response.json({error:updateError.message},{status:400});
 await admin.from("audit_log").insert({actor_id:user.id,subject_user_id:target,table_name:"profiles",record_id:target,operation:"approval_status_change",new_data:{approval_status:status}});
 return Response.json({ok:true,status});
});