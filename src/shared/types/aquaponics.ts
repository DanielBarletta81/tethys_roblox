// types/aquaponics.ts

export type SystemStatus = 'OPTIMAL' | 'STRESSED' | 'CRITICAL' | 'COLLAPSED';

export interface EcologyState {
  /** Fish biomass in kilograms. Drives nitrogen production. */
  fishBiomass: number;
  /** Current nitrogen/nitrate load in ppm (parts per million). */
  nitrogenPPM: number;
  /** Water acidity. Optimal is 6.5 - 7.2. Below 6.0 crashes the biofilter. */
  waterPH: number;
  /** Greenhouse harvest readiness (0 to 100%). */
  cropYield: number;
  /** Overall health metric determining NPC guard hostility and rationing. */
  cityMorale: number;
}

export interface EngineerAudit {
  status: SystemStatus;
  warnings: string[];
}

export type TerminalJob = "Hatchery" | "Engineer" | "None";
export type TerminalAction = "FeedHatchery" | "DoseAlkalinity" | "FlushSystem";
export interface TerminalData { job: TerminalJob; state: EcologyState; }
