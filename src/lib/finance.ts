export type InstrumentSpec = { tick_size:number; tick_value:number; contract_size:number; volume_min:number; volume_step:number; volume_max:number; quote_to_account_rate:number };
export function roundDownToStep(value:number, step:number):number { if (!(step>0)) throw new Error("Volume step must be positive"); const precision=Math.max(0, Math.ceil(-Math.log10(step))+4); return Number((Math.floor((value+1e-12)/step)*step).toFixed(precision)); }
export function calculatePositionSize(input:{riskAmount:number;entry:number;stop:number;spec:InstrumentSpec}):{size:number;distance:number;estimatedRisk:number;minimumExceedsRisk:boolean} {
 const {riskAmount,entry,stop,spec}=input;
 if (riskAmount<=0 || entry===stop || spec.tick_size<=0 || spec.tick_value<=0 || spec.quote_to_account_rate<=0) throw new Error("Invalid risk, prices, or instrument specification");
 const distance=Math.abs(entry-stop);
 const ticks=distance/spec.tick_size;
 const riskPerUnit=ticks*spec.tick_value*spec.quote_to_account_rate;
 const raw=riskAmount/riskPerUnit;
 const size=Math.min(spec.volume_max,roundDownToStep(raw,spec.volume_step));
 const valid=size>=spec.volume_min;
 const finalSize=valid?size:0;
 return {size:finalSize,distance,estimatedRisk:finalSize*riskPerUnit,minimumExceedsRisk:!valid && raw<spec.volume_min};
}
export function actualR(netPnl:number,initialRisk:number):number { if(initialRisk<=0) throw new Error("Initial risk must be positive"); return netPnl/initialRisk; }
export function expectancy(winRate:number,averageWin:number,lossRate:number,averageLoss:number):number { return winRate*averageWin-lossRate*averageLoss; }
export function profitFactor(grossProfit:number,grossLoss:number):number { if(grossLoss===0) return grossProfit>0?Infinity:0; return grossProfit/Math.abs(grossLoss); }
export function maxDrawdown(equity:number[]):number { let peak=-Infinity, max=0; for(const v of equity){peak=Math.max(peak,v); if(peak>0) max=Math.max(max,(peak-v)/peak);} return max; }
export function alignmentScore(values:boolean[]):number|null { return values.length ? values.filter(Boolean).length/values.length*100 : null; }
