--!strict
-- Pure reward policy. Its input is a server-owned life ledger, never a client payload.
local Config = if script then require(script.Parent.Config) else require("./Config")
local Policy = {}
export type Life = {
	Started: number, Active: number, Distance: number, Cells: number,
	NewCells: number, Observations: number, Areas: number, Interactions: number, Hazards: number,
}
export type Location = {X: number, Z: number}
export type Death = {At: number, Signature: string, Award: number, Location: Location?}

function Policy.Level(xp: number): number
	return 1 + math.floor(math.sqrt(math.max(0, xp) / 100))
end

function Policy.Award(life: Life, history: {Death}, now: number, signature: string, location: Location?): (number, string)
	if life.Active < Config.MinActiveSeconds or life.Distance < Config.MinDistance or life.Cells < Config.MinCells then
		return 0, "InsufficientExploration"
	end
	local spent, repeats, lastDeath = 0, 0, -math.huge
	for _, death in ipairs(history) do
		lastDeath = math.max(lastDeath, death.At)
		if now - death.At < Config.BudgetWindow then spent += death.Award end
		local nearby = not location or not death.Location
			or (location.X - death.Location.X)^2 + (location.Z - death.Location.Z)^2 <= 80^2
		if now - death.At < Config.RepeatWindow and death.Signature == signature and nearby then repeats += 1 end
	end
	if now - lastDeath < Config.DeathCooldown then return 0, "RecentDeath" end
	local novelty = life.NewCells >= 4 or life.Observations > 0 or life.Areas > 0 or life.Hazards > 0
	local multiplier = ({1, 0.35, 0.1, 0})[math.min(repeats + 1, 4)]
	-- A genuinely changed attempt can earn some credit even at a difficult crossing.
	if repeats > 0 and novelty then multiplier = math.max(multiplier, 0.65) end
	local raw = math.min(8, math.floor(life.Distance / 48))
		+ math.min(4, math.floor(life.Active / 30))
		+ math.min(4, life.Observations * 2) + math.min(4, life.Areas * 2)
		+ math.min(2, life.Interactions) + math.min(2, life.Hazards * 2)
	local award = math.min(math.floor(math.min(raw, Config.LifeCap) * multiplier), math.max(0, Config.WindowBudget - spent))
	return award, if award > 0 then "Exploration" elseif spent >= Config.WindowBudget then "WindowBudget" else "RepeatedCircumstances"
end
return Policy
