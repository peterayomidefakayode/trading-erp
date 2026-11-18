import { z } from "zod";
export const tradeSchema=z.object({
 account_id:z.string().uuid(), instrument_id:z.string().uuid(), direction:z.enum(["long","short"]),
 order_type:z.enum(["market","limit","stop"]), entry:z.number().positive(), stop_loss:z.number().positive().optional(),
 take_profit:z.number().positive().optional(), volume:z.number().positive(), opened_at:z.string().datetime(),
 status:z.enum(["planned","pending","open","closed","cancelled","missed","skipped"]).default("planned")
}).refine(v=>v.direction==="long" ? (!v.stop_loss || v.stop_loss<v.entry) : (!v.stop_loss || v.stop_loss>v.entry), {message:"Stop loss must be on the loss side of entry",path:["stop_loss"]});
