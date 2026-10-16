// types/transient.ts
export interface CratePayload {
  crateId: string;
  originalWeightKg: number;
  currentWeightKg: number;
  resourceType: 'LIMESTONE_BUFFER' | 'CROP_YIELD' | 'FISH_FEED';
}

export interface DeliveryResult {
  payoutScrip: number;
  isMarked: boolean;
  message: string;
}
