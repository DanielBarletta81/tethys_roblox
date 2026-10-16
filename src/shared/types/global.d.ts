// src/shared/types/global.d.ts

export interface PlayerStats {
    Strength: number;
    Resilience: number;
    Level: number;
}

export interface PlayerLedger {
    Faction: string;
    CurrentJob: string;
    Scrip: number;
    IsMarked: boolean;
    Stats: PlayerStats;
    SpawnRouting: string;
}

// We must extend the internal _G interface, not a namespace
declare global {
    interface _G {
        GetPlayerData: (userId: number) => PlayerLedger | undefined;
        UpdatePlayerState: (userId: number, updates: Partial<PlayerLedger>) => void;
        // The "?" makes it optional, which fixes the "if (_G.ClearPlayerInventory)" check
        ClearPlayerInventory?: (userId: number) => void;
    }
}
