-- One-time Studio Command Bar preparation for the two inspected source packs.
-- Originals stay in their existing location, with no attribute or geometry edits.
local storage = game:GetService("ServerStorage").TethysAssets
local nature = storage.Nature
local arena = workspace:FindFirstChild("Development Arena")
local placement = require(game.ReplicatedStorage.Tethys.WorldModules.Scatter.AssetPlacement)
local primary = arena and arena:FindFirstChild("Nature_1")
local secondary = arena and arena:FindFirstChild("Nature_")
assert(primary and secondary, "Expected both original nature packs in Development Arena")
assert(not game:GetService("RunService"):IsRunning(), "Use Studio edit mode")
for _, category in ipairs({ "Trees", "Rocks", "Understory", "GroundCover" }) do
	assert(#nature[category]:GetChildren() == 0, "Library is already populated; do not import twice")
end

local function classify(name)
	name = string.lower(name)
	if name:find("tree") or name:find("spruce") then
		return "Trees"
	elseif (name:find("rock") and not name:find("splash")) or name == "granite" or name == "limestone" or name == "slate" or name == "quartzite" or name:find("stone") then
		return "Rocks"
	elseif name:find("grass") or name:find("flower") or name:find("mushroom") or name == "clover" or name == "wheat" then
		return "GroundCover"
	elseif name:find("fern") or name:find("bush") or name:find("hedge") or (name:find("plant") and not name:find("underwater")) then
		return "Understory"
	end
	return nil
end

local staged = Instance.new("Folder")
local counts = { Trees = 0, Rocks = 0, Understory = 0, GroundCover = 0, Unclassified = 0, RebuiltContainers = 0, RestrictedSkipped = 0 }
local skipped = {}
local history = game:GetService("ChangeHistoryService")
local recording
if not history:IsRecordingInProgress() then
	recording = history:TryBeginRecording("TethysNatureLibrary", "Prepare nature source library")
	assert(recording, "Finish the active Studio undo recording and retry")
end
local ok, err = pcall(function()
	for index, original in ipairs(primary["01_Nature_Assets"]:GetChildren()) do
		local category = classify(original.Name)
		if category then
			local copied, clone = pcall(function() return placement.CloneStatic(original) end)
			if not copied or not clone then
				counts.RestrictedSkipped += 1
				table.insert(skipped, { Name = original.Name, Category = category, SourceIndex = index, Reason = "Saved source capabilities cannot be copied within the approved scope" })
				continue
			end
			if clone:GetAttribute("ScatterRebuiltContainer") then counts.RebuiltContainers += 1 end
			clone:SetAttribute("ScatterId", string.format("NAT_%04d", index))
			clone:SetAttribute("ScatterCategory", category)
			clone:SetAttribute("ScatterOriginalPath", original:GetFullName())
			clone.Parent = staged
			counts[category] += 1
		else
			counts.Unclassified += 1
		end
	end
	for _, clone in ipairs(staged:GetChildren()) do
		clone.Parent = nature[clone:GetAttribute("ScatterCategory")]
	end
end)
staged:Destroy()
if recording then
	history:FinishRecording(recording, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
end
if not ok then error(err, 0) end
return game:GetService("HttpService"):JSONEncode({ Counts = counts, Skipped = skipped })
