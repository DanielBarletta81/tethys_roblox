
// services/TransientManager.ts
import type { CratePayload, DeliveryResult } from "../../shared/types/transient";

import { min, whole, positiveAmount } from "../../shared/Numbers";

export class TransientManager {
  constructor(private readonly markPlayer: (playerId: string) => void = () => {}) {}
  private readonly SKIM_TOLERANCE = 0.85; // City ignores up to 15% missing weight (spillage)
  private readonly BASE_PAYOUT = 50;

  /**
   * Called when a player skims a crate in a dark corner.
   * Returns the amount successfully stolen.
   */
  public skimCrate(crate: CratePayload, skimAmountKg: number): number {
    if (!positiveAmount(skimAmountKg, 1000000)) return 0;
    const availableToSkim = min(crate.currentWeightKg, skimAmountKg);
    crate.currentWeightKg -= availableToSkim;
    return availableToSkim;
  }

  /**
   * Called when the physical crate is placed on the delivery terminal scale.
   */
  public processDelivery(playerId: string, crate: CratePayload): DeliveryResult {
    if (!(crate.originalWeightKg > 0 && crate.originalWeightKg <= 1000000)
        || !(crate.currentWeightKg >= 0 && crate.currentWeightKg <= crate.originalWeightKg)) {
      return { payoutScrip: 0, isMarked: false, message: "Invalid delivery weight." };
    }
    const weightRatio = crate.currentWeightKg / crate.originalWeightKg;

    if (weightRatio >= 0.95) {
      // Perfect or near-perfect delivery
      return {
        payoutScrip: this.BASE_PAYOUT,
        isMarked: false,
        message: "Delivery accepted. Standard payout disbursed."
      };
    } else if (weightRatio >= this.SKIM_TOLERANCE) {
      // Suspiciously light, pay docked, but no execution
      const dockedPay = whole(this.BASE_PAYOUT * weightRatio);
      return {
        payoutScrip: dockedPay,
        isMarked: false,
        message: "Discrepancy detected. Payout docked for spillage."
      };
    } else {
      // Egregious theft. Trigger the biometric justice system.
      // Ping the GateScanner/Justice service to Mark the player
      this.markPlayerForExecution(playerId);

      return {
        payoutScrip: 0,
        isMarked: true,
        message: "BIOMETRIC ALARM: Severe payload discrepancy. Subject Marked."
      };
    }
  }

  private markPlayerForExecution(playerId: string): void {
    this.markPlayer(playerId);
    // Logic to update the player's global state to { isMarked: true }
  }

}
