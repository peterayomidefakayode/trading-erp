import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
Deno.serve(async(req)=>{
 if(req.method!=="POST") return new Response("Method not allowed",{status:405});
 const url=Deno.env.get("SUPABASE_URL")!, key=Deno.env.get("SUPABASE_ANON_KEY")!;
 const client=createClient(url,key,{global:{headers:{Authorization:req.headers.get("Authorization")??""}}});
 const {data:{user}}=await client.auth.getUser(); if(!user) return Response.json({error:"Unauthorized"},{status:401});
 const body=await req.json(); const {data,error}=await client.rpc("evaluate_trade_preflight",{p_account_id:body.account_id,p_risk_amount:body.risk_amount,p_rr:body.rr??null});
 if(error) return Response.json({error:error.message},{status:400});
 return Response.json(data,{status:data?.allowed?200:409});
});