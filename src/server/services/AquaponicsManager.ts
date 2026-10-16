// services/AquaponicsManager.ts
import { min, max, positiveAmount } from '../../shared/Numbers';
import { EcologyState, SystemStatus, EngineerAudit } from '../../shared/types/aquaponics';

export class AquaponicsManager {
  private state: EcologyState;

  // Constants governing the biological loop
  private readonly MAX_BIOMASS = 10000; // kg
  private readonly IDEAL_PH_MIN = 6.5;
  private readonly IDEAL_PH_MAX = 7.2;
  private readonly NITROGEN_UPTAKE_RATE = 2.5; // ppm consumed by crops per tick

  constructor(initialState?: Partial<EcologyState>) {
    this.state = {
      fishBiomass: 5000,
      nitrogenPPM: 40,
      waterPH: 7.0,
      cropYield: 50,
      cityMorale: 80,
      ...initialState
    };
  }

  /** Return a snapshot so terminal consumers cannot mutate the simulation. */
  public getState(): EcologyState {
    return { ...this.state };
  }

  /**
   * The Global Server Tick. Runs every 60 seconds.
   * Simulates the bio-chemical cycle of the Sky City powerhouse.
   */
  public executeGlobalTick(): void {
    // 1. Hatchery Loop: Fish produce waste (Nitrogen load increases)
    // 1000kg of fish produces roughly 0.5 ppm of nitrates per tick
    const wasteProduced = (this.state.fishBiomass / 1000) * 0.5;
    this.state.nitrogenPPM += wasteProduced;

    // 2. Greenhouse Loop: Plants consume nitrogen and grow
    if (this.state.nitrogenPPM > this.NITROGEN_UPTAKE_RATE) {
      this.state.nitrogenPPM -= this.NITROGEN_UPTAKE_RATE;
      // Growth is bottlenecked if pH is out of bounds
      const phPenalty = this.calculatePHPenalty();
      this.state.cropYield = min(100, this.state.cropYield + (2 * phPenalty));
    }

    // 3. Chemical Loop: High nitrogen and biological activity drops pH (acidification)
    // Nitrification naturally consumes alkalinity.
    if (this.state.nitrogenPPM > 60) {
      this.state.waterPH = max(4.0, this.state.waterPH - 0.05);
    }

    // 4. Catastrophic Failures & Morale
    this.evaluateSystemHealth();
  }

  /**
   * Returns a multiplier between 0 (dead) and 1 (optimal) based on pH.
   */
  private calculatePHPenalty(): number {
    if (this.state.waterPH >= this.IDEAL_PH_MIN && this.state.waterPH <= this.IDEAL_PH_MAX) {
      return 1.0;
    } else if (this.state.waterPH < 5.5 || this.state.waterPH > 8.0) {
      return 0.1; // Severe nutrient lockout
    }
    return 0.5; // Stressed
  }

  private evaluateSystemHealth(): void {
    // Acid crash destroys the biofilter and kills the fish
    if (this.state.waterPH <= 5.0) {
      this.state.fishBiomass = max(0, this.state.fishBiomass - 500);
    }

    // Morale calculation
    if (this.state.cropYield > 80 && this.state.fishBiomass > 6000) {
      this.state.cityMorale = min(100, this.state.cityMorale + 1);
    } else if (this.state.cropYield < 20 || this.state.fishBiomass < 2000) {
      this.state.cityMorale = max(0, this.state.cityMorale - 5);
    }
  }

  // --- PLAYER JOB ENDPOINTS ---

  /**
   * Hatchery Worker Action: Feeds the system, boosting biomass but spiking nitrogen.
   */
  public feedHatchery(feedAmountKg: number): boolean {
    if (!positiveAmount(feedAmountKg, 100)) return false;
    const growth = feedAmountKg * 0.8; // FCR (Feed Conversion Ratio)
    this.state.fishBiomass = min(this.MAX_BIOMASS, this.state.fishBiomass + growth);
    this.state.nitrogenPPM += (feedAmountKg * 0.2);
    return true;
  }

  /**
   * Engineer Action: Doses the system with crushed limestone/buffer to raise pH.
   */
  public doseAlkalinity(bufferUnits: number): boolean {
    if (!positiveAmount(bufferUnits, 10)) return false;
    // Engineers must carefully calculate this. Overdosing spikes pH too high.
    this.state.waterPH = min(14.0, this.state.waterPH + (bufferUnits * 0.2));
    return true;
  }

  /**
   * Engineer Action: Purges toxic water, reducing nitrogen but wasting water volume.
   */
  public flushSystem(): void {
    this.state.nitrogenPPM = max(0, this.state.nitrogenPPM - 30);
    // Requires physical Transient Workers to haul fresh mountain runoff to refill
  }

  /**
   * Read-only endpoint for the client UI terminals.
   */
  public getSystemDiagnostics(): EngineerAudit {
    const warnings: string[] = [];
    let status: SystemStatus = 'OPTIMAL';

    if (this.state.waterPH < 6.0) {
      warnings.push("ACIDIFICATION DETECTED: Dose alkalinity immediately to prevent biofilter crash.");
      status = 'CRITICAL';
    }
    if (this.state.nitrogenPPM > 80) {
      warnings.push("TOXIC NITRATE LOAD: Flush system required.");
      status = status === 'OPTIMAL' ? 'STRESSED' : status;
    }

    return { status, warnings };
  }
}
