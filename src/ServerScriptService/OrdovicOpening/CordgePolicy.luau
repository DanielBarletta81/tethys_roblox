local Policy = {}
function Policy.CanSpeak(state, id, definition, trigger, clues, now, present, alive)
	if not present or not alive or not definition then return false end
	if trigger.OneShot ~= false and definition.OneShot and state.Seen[id] then return false end
	if now - (state.LastPlayed[id] or -math.huge) < (trigger.Cooldown or 45) then return false end
	if trigger.RequiresClue and not clues[trigger.RequiresClue] then return false end
	if trigger.BlocksClue and clues[trigger.BlocksClue] then return false end
	local priority = trigger.Priority or definition.Priority or 1
	if state.Current and now < state.Current.Expires and priority <= state.Current.Priority then return false end
	return true
end
function Policy.Begin(state, id, definition, priority, now)
	state.Seen[id] = true; state.LastPlayed[id] = now
	state.Current = {Id = id, Priority = priority or definition.Priority or 1,
		Expires = now + math.clamp(2.5 + #definition.Text / 35, 3, 9)}
	return state.Current
end
return Policy
