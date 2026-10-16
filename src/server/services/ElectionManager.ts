// services/ElectionManager.ts
import type { TributePayload, CandidateScore, ResourceType, FactionId } from "../../shared/types/election";

export class ElectionManager {
  // Dynamic market weights: What the Triumvirate currently values
  private currentResourceWeights: Record<ResourceType, number> = {
    DEEP_SEA_CARRION: 1.5, // Food is currently scarce
    VOLCANIC_BASALT: 0.8,
    HATCHERY_YIELD: 2.0,
    STOLEN_INTEL: 3.5 // Kross highly values blackmail
  };

  // Faction alignment modifiers: Vane might hate intel, Kross loves it.
  private factionMultipliers: Record<FactionId, Record<ResourceType, number>> = {
    KROSS_LOYALISTS: { DEEP_SEA_CARRION: 1, VOLCANIC_BASALT: 1, HATCHERY_YIELD: 1, STOLEN_INTEL: 2.5 },
    VANE_SYNDICATE: { DEEP_SEA_CARRION: 0.5, VOLCANIC_BASALT: 2.0, HATCHERY_YIELD: 0.5, STOLEN_INTEL: 1 },
    MERCHANT_GUILD: { DEEP_SEA_CARRION: 2.0, VOLCANIC_BASALT: 1.5, HATCHERY_YIELD: 2.5, STOLEN_INTEL: 0 },
    LOWER_TIER_RABBLE: { DEEP_SEA_CARRION: 3.0, VOLCANIC_BASALT: 0, HATCHERY_YIELD: 3.0, STOLEN_INTEL: 0 }
  };

  private activeTributes: TributePayload[] = [];

  /**
   * Called when a player physically drops items into a faction's coffer in-game.
   */
  public registerTribute(payload: TributePayload): void {
    this.activeTributes.push(payload);
    print(`[CONCLAVE] Tribute registered by ${payload.aspirantId} to ${payload.factionId}`);
  }

  /**
   * Runs weekly (via Cron job). Calculates the next Triumvir.
   */
  public executePapalConclave(): CandidateScore | undefined {
    if (this.activeTributes.size() === 0) return undefined;

    const scores = new Map<string, CandidateScore>();

    // Process all tributes
    for (const tribute of this.activeTributes) {
      const baseValue = tribute.quantity * this.currentResourceWeights[tribute.resourceType];
      const factionModifier = this.factionMultipliers[tribute.factionId][tribute.resourceType];
      const finalInfluence = baseValue * factionModifier;

      if (!scores.has(tribute.aspirantId)) {
        scores.set(tribute.aspirantId, {
          aspirantId: tribute.aspirantId,
          totalInfluence: 0,
          factionApprovals: {
            KROSS_LOYALISTS: 0,
            VANE_SYNDICATE: 0,
            MERCHANT_GUILD: 0,
            LOWER_TIER_RABBLE: 0
          }
        });
      }

      const candidateData = scores.get(tribute.aspirantId)!;
      candidateData.totalInfluence += finalInfluence;
      candidateData.factionApprovals[tribute.factionId] += finalInfluence;
    }

    // Determine winner based on total aggregated influence
    let winner: CandidateScore | undefined;
    let highestScore = 0;

    scores.forEach((score) => {
      if (score.totalInfluence > highestScore) {
        highestScore = score.totalInfluence;
        winner = score;
      }
    });

    // Reset the conclave for the next cycle
    this.activeTributes = [];
    this.broadcastSmokeSignal(winner);

    return winner;
  }

  /**
   * Fires a WebSocket/Roblox HttpService event to change the environmental
   * smoke color coming from the Sky City Citadel stack.
   */
  private broadcastSmokeSignal(winner: CandidateScore | undefined): void {
    if (winner) {
      // White Smoke + The winner's faction color
      print(`[SERVER EVENT] Habemus Triumvir. Aspirant ${winner.aspirantId} ascends.`);
    } else {
      // Black Smoke: No consensus, the seat remains empty, chaos continues
      print(`[SERVER EVENT] Conclave failed. Black smoke deployed.`);
    }
  }
}
