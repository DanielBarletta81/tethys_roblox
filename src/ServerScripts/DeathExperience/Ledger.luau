--!strict
local Config = if script then require(script.Parent.Config) else require("./Config")
local Policy = if script then require(script.Parent.Policy) else require("./Policy")
local Ledger = {}
Ledger.__index = Ledger

function Ledger.new()
	return setmetatable({XP = 0, EarnedXP = 0, DeathXP = 0, Serial = 0, Life = nil, History = {}, Visited = {}, VisitedCount = 0,
		Evidence = {}, EvidenceCount = 0}, Ledger)
end
function Ledger:SetEarnedXP(value: number)
	if value ~= value or value < 0 or value == math.huge then return false end
	self.EarnedXP = math.floor(value)
	self.XP = self.EarnedXP + self.DeathXP
	return true
end
function Ledger:Begin(now: number, token: any)
	self.Serial += 1
	self.Life = {Token = token, Id = self.Serial, Started = now, Active = 0, Distance = 0, Cells = 0,
		NewCells = 0, Observations = 0, Areas = 0, Interactions = 0, Hazards = 0, Visited = {}}
	return self.Life
end
function Ledger:Sample(token: any, dt: number, distance: number, cell: string, safe: boolean, active: boolean)
	local life = self.Life
	if not life or life.Token ~= token or safe or not active then return false end
	if dt ~= dt or distance ~= distance or dt <= 0 or dt > Config.MaxSampleSeconds
		or distance < 0 or distance > Config.MaxSpeed * dt + 4 then return false end
	life.Active += dt
	life.Distance += distance
	if distance >= 0.25 and not life.Visited[cell] and life.Cells < Config.MaxVisitedCells then
		life.Visited[cell] = true; life.Cells += 1
		if not self.Visited[cell] and self.VisitedCount < Config.MaxVisitedCells then
			self.Visited[cell] = true; self.VisitedCount += 1; life.NewCells += 1
		end
	end
	return true
end
function Ledger:Record(token: any, kind: string, id: string)
	local life = self.Life
	if not life or life.Token ~= token or not ({Observations = true, Areas = true, Interactions = true, Hazards = true})[kind]
		or #id == 0 or #id > 96 or self.EvidenceCount >= Config.MaxEvidence then return false end
	local key = kind .. ":" .. id
	if self.Evidence[key] then return false end
	self.Evidence[key] = true; self.EvidenceCount += 1; life[kind] += 1
	return true
end
function Ledger:Finish(token: any, now: number, signature: string, location: Policy.Location?)
	local life = self.Life
	if not life or life.Token ~= token then return nil end
	self.Life = nil -- Consume before publishing; duplicate Died callbacks cannot award twice.
	local award, reason = Policy.Award(life, self.History, now, signature, location)
	self.DeathXP += award
	self.XP = self.EarnedXP + self.DeathXP
	for index = #self.History, 1, -1 do
		if now - self.History[index].At >= math.max(Config.RepeatWindow, Config.BudgetWindow) then table.remove(self.History, index) end
	end
	table.insert(self.History, {At = now, Signature = signature, Award = award, Location = location})
	-- Never evict paid awards still in the rolling budget when spawn spam adds zero awards.
	while #self.History > Config.MaxHistory do
		local discard
		for index, death in ipairs(self.History) do if death.Award == 0 then discard = index; break end end
		table.remove(self.History, discard or 1)
	end
	return {Amount = award, Reason = reason, XP = self.XP, Level = Policy.Level(self.XP), LifeId = life.Id}
end
function Ledger:Discard(token: any)
	if self.Life and self.Life.Token == token then self.Life = nil end
end
return Ledger
