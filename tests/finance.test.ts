import { describe,it,expect } from "vitest";
import { actualR,alignmentScore,calculatePositionSize,expectancy,maxDrawdown,profitFactor,roundDownToStep } from "../src/lib/finance";
describe("financial calculations",()=>{
 it("rounds volume down to permitted step",()=>expect(roundDownToStep(0.129,0.01)).toBe(0.12));
 it("rejects a non-positive volume step",()=>expect(()=>roundDownToStep(1,0)).toThrow());
 it("returns zero volume when the minimum exceeds the calculated size",()=>{const r=calculatePositionSize({riskAmount:1,entry:2000,stop:1999,spec:{tick_size:1,tick_value:10,contract_size:1,volume_min:.1,volume_step:.1,volume_max:10,quote_to_account_rate:1}});expect(r.size).toBe(0);expect(r.estimatedRisk).toBe(0);});
 it("caps calculated volume at the configured maximum",()=>{const r=calculatePositionSize({riskAmount:10000,entry:2000,stop:1999,spec:{tick_size:1,tick_value:10,contract_size:1,volume_min:.1,volume_step:.1,volume_max:2,quote_to_account_rate:1}});expect(r.size).toBe(2);});
 it("calculates actual R from initial risk",()=>expect(actualR(6,3)).toBe(2));
 it("calculates expectancy",()=>expect(expectancy(.5,6,.5,3)).toBe(1.5));
 it("calculates profit factor",()=>expect(profitFactor(120,60)).toBe(2));
 it("calculates max drawdown",()=>expect(maxDrawdown([100,120,90,110])).toBe(.25));
 it("scores alignment",()=>expect(alignmentScore([true,true,false,true])).toBe(75));
 it("warns when minimum volume exceeds risk",()=>{const r=calculatePositionSize({riskAmount:1,entry:2000,stop:1999,spec:{tick_size:1,tick_value:10,contract_size:1,volume_min:.1,volume_step:.1,volume_max:10,quote_to_account_rate:1}});expect(r.minimumExceedsRisk).toBe(true);});
});