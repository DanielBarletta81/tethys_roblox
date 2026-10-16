import type { PlayerLedger } from "../shared/types/global";

// Adapt the existing profile owner. This package never creates a second save store.
export function getProfile(player: Player): PlayerLedger | undefined {
    return typeIs(_G.GetPlayerData, "function") ? _G.GetPlayerData(player.UserId) : undefined;
}
