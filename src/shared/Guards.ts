import type { EcologyState } from "./types/aquaponics";

export function isEcologyState(value: unknown): value is EcologyState {
  if (!typeIs(value, "table")) return false;
  const state = value as EcologyState;
  return typeIs(state.fishBiomass, "number") && state.fishBiomass >= 0 && state.fishBiomass <= 10000
    && typeIs(state.nitrogenPPM, "number") && state.nitrogenPPM >= 0 && state.nitrogenPPM < 1000000
    && typeIs(state.waterPH, "number") && state.waterPH >= 0 && state.waterPH <= 14
    && typeIs(state.cropYield, "number") && state.cropYield >= 0 && state.cropYield <= 100
    && typeIs(state.cityMorale, "number") && state.cityMorale >= 0 && state.cityMorale <= 100;
}
