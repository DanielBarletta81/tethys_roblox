// types/election.ts
export type FactionId = 'KROSS_LOYALISTS' | 'VANE_SYNDICATE' | 'MERCHANT_GUILD' | 'LOWER_TIER_RABBLE';
export type ResourceType = 'DEEP_SEA_CARRION' | 'VOLCANIC_BASALT' | 'HATCHERY_YIELD' | 'STOLEN_INTEL';

export interface TributePayload {
  aspirantId: string;
  factionId: FactionId;
  resourceType: ResourceType;
  quantity: number;
  timestamp: number;
}

export interface CandidateScore {
  aspirantId: string;
  totalInfluence: number;
  factionApprovals: Record<FactionId, number>;
}