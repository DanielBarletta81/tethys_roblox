local modules = game.ServerScriptService.OrdovicOpening
local Policy, Dialogue = require(modules.CordgePolicy), require(modules.CordgeDialogue)
local results = {}
local function check(name, fn)
	local ok, err = pcall(fn)
	table.insert(results, {name = name, passed = ok, error = not ok and tostring(err) or nil})
end
local function state() return {Seen = {}, LastPlayed = {}, Clues = {}} end
check("absent, dead and unknown dialogue stay silent", function()
	local s, d = state(), Dialogue.CAVE_ENTRY_01
	assert(not Policy.CanSpeak(s, "CAVE_ENTRY_01", d, {}, {}, 10, false, true))
	assert(not Policy.CanSpeak(s, "CAVE_ENTRY_01", d, {}, {}, 10, true, false))
	assert(not Policy.CanSpeak(s, "missing", nil, {}, {}, 10, true, true))
end)
check("one-shot survives expiry and re-entry", function()
	local s, d = state(), Dialogue.CAVE_ENTRY_01
	assert(Policy.CanSpeak(s, "CAVE_ENTRY_01", d, {}, {}, 10, true, true))
	Policy.Begin(s, "CAVE_ENTRY_01", d, 1, 10); s.Current = nil
	assert(not Policy.CanSpeak(s, "CAVE_ENTRY_01", d, {}, {}, 100, true, true))
end)
check("repeatable triggers respect cooldown", function()
	local s, d, t = state(), Dialogue.CAVE_ENTRY_01, {OneShot = false, Cooldown = 12}
	Policy.Begin(s, "CAVE_ENTRY_01", d, 1, 10); s.Current = nil
	assert(not Policy.CanSpeak(s, "CAVE_ENTRY_01", d, t, {}, 21.9, true, true))
	assert(Policy.CanSpeak(s, "CAVE_ENTRY_01", d, t, {}, 22, true, true))
end)
check("clue prerequisites and blocking knowledge", function()
	local s, d, t = state(), Dialogue.CAVE_SALT_01, {RequiresClue = "salt", BlocksClue = "solved"}
	assert(not Policy.CanSpeak(s, "CAVE_SALT_01", d, t, {}, 10, true, true))
	assert(Policy.CanSpeak(s, "CAVE_SALT_01", d, t, {salt = true}, 10, true, true))
	assert(not Policy.CanSpeak(s, "CAVE_SALT_01", d, t, {salt = true, solved = true}, 10, true, true))
end)
check("higher priority interrupts; equal and lower wait", function()
	local s = state(); Policy.Begin(s, "CAVE_ENTRY_01", Dialogue.CAVE_ENTRY_01, 2, 10)
	assert(not Policy.CanSpeak(s, "CAVE_MASONRY_01", Dialogue.CAVE_MASONRY_01, {Priority = 2}, {}, 11, true, true))
	assert(not Policy.CanSpeak(s, "CAVE_BLOCKED_01", Dialogue.CAVE_BLOCKED_01, {Priority = 1}, {}, 11, true, true))
	assert(Policy.CanSpeak(s, "CAVE_SALT_01", Dialogue.CAVE_SALT_01, {Priority = 3}, {}, 11, true, true))
	assert(Policy.CanSpeak(s, "CAVE_MASONRY_01", Dialogue.CAVE_MASONRY_01, {Priority = 2}, {}, 20, true, true))
end)
check("players do not share line or clue state", function()
	local a, b = state(), state()
	Policy.Begin(a, "CAVE_ENTRY_01", Dialogue.CAVE_ENTRY_01, 1, 10); a.Clues.salt = true
	assert(not b.Seen.CAVE_ENTRY_01 and not b.Clues.salt and not b.Current)
end)
return results
