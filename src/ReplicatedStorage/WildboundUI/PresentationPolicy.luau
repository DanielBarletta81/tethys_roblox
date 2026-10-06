-- Presentation only. Region visits, title discovery and rewards remain server-owned.
local Policy = {
	RevealFadeIn = 0.65, RevealHold = 1.5, RevealFadeOut = 0.85,
	RevealQueueLifetime = 8, ToastQueueLifetime = 10, DuplicateWindow = 12,
	MaxPendingToasts = 4, MaxVisibleToasts = 2, ToastDuration = 3.2,
}
local regions = {
	SKY_CITY = {Title = "SKY CITY", Context = "Inside the Machine", Icon = "SkyCity"},
	THE_WEEP = {Title = "THE WEEP", Icon = "TheWeep"},
	THE_STAKES = {Title = "THE STAKES", Icon = "TheStakes"},
	DANIAN_DELTA = {Title = "DANIAN DELTA", Icon = "DanianDelta"},
	ARCHYDA = {Title = "ARCHYDA", Icon = "Archyda"},
	PERMIAN_DESERT = {Title = "PERMIAN DESERT", Icon = "PermianDesert"},
	WATCHER_VOLCANO = {Title = "WATCHER VOLCANO", Icon = "WatcherVolcano"},
	CAMBRIA_ROAD = {Title = "CAMBRIA ROAD", Icon = "CambriaRoad"},
}
function Policy.ResolveTitle(cue)
	if type(cue) ~= "table" or cue.Type ~= "TITLE" then return nil end
	local region = regions[cue.TitleId]
	if not region then return nil end
	local context = cue.Subtitle or cue.ContextLabel or cue.ContextId or region.Context
	if type(context) ~= "string" then context = region.Context or "" end
	return {Id = cue.TitleId, Title = region.Title, Context = context:sub(1, 160), Icon = region.Icon, Authored = true}
end
function Policy.VisibleLimit(profile) return profile == "Game1" and 1 or Policy.MaxVisibleToasts end
function Policy.ToastAllowed(profile, kind) return profile ~= "Game1" or kind == "Item" end
function Policy.LocationAllowed(profile, authored) return profile ~= "Game1" or authored == true end
return Policy
