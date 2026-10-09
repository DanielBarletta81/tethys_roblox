-- Native Edit-mode fixture. Two empty 32-stud boxes are restored on every exit.
-- Prepared archives/guides are tested without claiming plugin-owned Undo.
return function(sourceModules)
	assert(game:GetService("RunService"):IsEdit(), "Run this fixture in Edit mode")
	local Selection = game:GetService("Selection")
	local priorSelection = Selection:Get()
	local fixture = Instance.new("Folder")
	fixture.Name = "StratumFixture_" .. game:GetService("HttpService"):GenerateGUID(false)
	fixture.Parent = game.ServerStorage
	local modules = sourceModules:Clone()
	modules.Parent = fixture
	local Codec, Matrix = require(modules.VoxelCodec), require(modules.VoxelMatrix)
	local Storage, Session = require(modules.ArchiveStorage), require(modules.Session)
	local Backend, Guides = require(modules.RobloxBackend), require(modules.R1BGuides)
	local Plan, Grid = require(modules.R1BPlan), require(modules.ChunkGrid)
	local backend = Backend.new(fixture)
	local a = { X = 12152, Y = 4000, Z = 12000, Width = 32, Height = 32, Length = 32 }
	local b = table.clone(a)
	b.X += 128
	local function region(bounds)
		local low = Vector3.new(bounds.X, bounds.Y, bounds.Z)
		return Region3.new(low, low + Vector3.new(bounds.Width, bounds.Height, bounds.Length))
	end
	local function read(bounds)
		return workspace.Terrain:ReadVoxelChannels(region(bounds), 4,
			{ "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" })
	end
	local function write(bounds, channels)
		-- ReadVoxelChannels adds Size; WriteVoxelChannels accepts channel keys only.
		workspace.Terrain:WriteVoxelChannels(region(bounds), 4, {
			SolidMaterial = channels.SolidMaterial,
			SolidOccupancy = channels.SolidOccupancy,
			LiquidOccupancy = channels.LiquidOccupancy,
		})
	end
	local function equal(left, right)
		return buffer.tostring(Codec.Encode(left)) == buffer.tostring(Codec.Encode(right))
	end
	local function empty(chunk)
		for index, solid in ipairs(chunk.Solid) do
			if solid > 0 or chunk.Liquid[index] > 0 then return false end
		end
		return true
	end
	local function rejected(callback, fragment)
		local ok, err = pcall(callback)
		assert(not ok and tostring(err):find(fragment, 1, true), tostring(err))
	end
	local originalA, originalB
	local modifiedA, modifiedB = false, false
	local result = { Groups = {}, PluginUndoTested = false, LiveGuidesCreated = false }
	local function check(name, callback)
		callback()
		table.insert(result.Groups, name)
	end
	local ok, failure = pcall(function()
		originalA, originalB = read(a), read(b)
		assert(empty(Matrix.Flatten(originalA, a)) and empty(Matrix.Flatten(originalB, b)),
			"Fixture requires empty Terrain; no writes")
		local chunk = { SizeX = 8, SizeY = 8, SizeZ = 8, Materials = {}, Solid = {}, Liquid = {} }
		local materialSet = { Enum.Material.Rock, Enum.Material.Slate, Enum.Material.Grass, Enum.Material.Sand }
		for index = 1, 512 do
			local slot = index % 7
			chunk.Materials[index] = if slot == 0 then Enum.Material.Air.Value else materialSet[index % 4 + 1].Value
			chunk.Solid[index] = if slot == 0 then 0 else (index % 4 + 1) / 4
			chunk.Liquid[index] = if slot == 0 then 0.75 elseif slot == 1 then 0.25 else 0
		end
		modifiedA = true
		write(a, Matrix.Expand(chunk))
		local actual = backend.Read(a)
		local capture
		check("native solid/liquid channels and full material IDs", function()
			local solid, liquid, highIds = 0, 0, 0
			for index, value in ipairs(actual.Solid) do
				if value > 0 then solid += 1 end
				if actual.Liquid[index] > 0 then liquid += 1 end
				if actual.Materials[index] > 255 then highIds += 1 end
			end
			assert(solid > 0 and liquid > 0 and highIds > 0)
			result.SolidCells, result.WaterCells, result.HighMaterialIdCells = solid, liquid, highIds
		end)
		check("native read-only preview across global chunk edges", function()
			local session = Session.new(backend)
			capture = session:Preview(a)
			assert(#capture.Chunks == 2 and capture.Stats.Voxels == 512)
			assert(equal(actual, backend.Read(a)), "Preview changed Terrain")
			result.CaptureSeconds = capture.Stats.CaptureSeconds
			result.EncodedBytes, result.StoredTextBytes = capture.Stats.EncodedBytes, capture.Stats.StoredTextBytes
		end)
		check("native archive StringValues clone and read", function()
			local archive = Storage.Prepare(capture, "engine-fixture")
			assert(archive.Parent == nil and #archive:GetChildren() == 2)
			archive.Parent = fixture
			local clone = archive:Clone()
			clone.Parent = fixture
			local restored = Storage.Read(clone)
			for index, record in ipairs(restored.Chunks) do
				assert(buffer.tostring(record.Data) == buffer.tostring(capture.Chunks[index].Data))
				assert(equal(Codec.Decode(record.Data), backend.Read(record.Bounds)))
			end
			clone:Destroy()
		end)
		check("native Terrain reconstruction preserves actual quantized channels", function()
			modifiedB = true
			for _, record in ipairs(capture.Chunks) do
				local destination = table.clone(record.Bounds)
				destination.X += 128
				write(destination, Matrix.Expand(Codec.Decode(record.Data)))
			end
			assert(equal(actual, backend.Read(b)), "Native reconstruction differs")
		end)
		check("archive rejects changed identity, bounds and payload", function()
			local archive = Storage.Prepare(capture, "tamper")
			archive.Parent = fixture
			archive.Name = "ManualTrees"
			rejected(function() Storage.Read(archive) end, "identity mismatch")
			archive.Name = "Archive_tamper"
			archive:SetAttribute("VoxelCount", 1)
			rejected(function() Storage.Read(archive) end, "summary differs")
			archive:SetAttribute("VoxelCount", 512)
			local node = archive:GetChildren()[1]
			local value = node.Value
			node.Value = "!" .. value:sub(2)
			rejected(function() Storage.Read(archive) end, "Base64")
			node.Value = value
			node:SetAttribute("BoundsMin", Vector3.zero)
			rejected(function() Storage.Read(archive) end, "misplaced chunk")
			archive:Destroy()
		end)
		check("unknown or Water solid IDs fail native expansion", function()
			local invalid = Codec.Decode(Codec.Encode(actual))
			invalid.Materials[1] = 65535
			rejected(function() Matrix.Expand(invalid) end, "Unknown solid material")
			invalid.Materials[1] = Enum.Material.Water.Value
			rejected(function() Matrix.Expand(invalid) end, "Unknown solid material")
		end)
		check("native source edit blocks stale archive save", function()
			local session = Session.new(backend)
			session:Preview(a)
			local sculpt = backend.Read(a)
			sculpt.Solid[1], sculpt.Materials[1] = 0, Enum.Material.Air.Value
			sculpt.Liquid[1] = if sculpt.Liquid[1] == 1 then 0 else 1
			write(a, Matrix.Expand(sculpt))
			rejected(function() session:Publish() end, "Terrain changed")
			write(a, Matrix.Expand(actual))
			assert(equal(actual, backend.Read(a)))
		end)
		check("selected bounds snap outward without modifying the Part", function()
			local part = Instance.new("Part")
			part.Size, part.Position = Vector3.new(11, 13, 15), Vector3.new(12155, 4003, 12003)
			part.Parent = fixture
			local beforeSize, beforeCFrame = part.Size, part.CFrame
			Selection:Set({ part })
			local snapped = backend.SelectionBounds()
			Grid.Plan(snapped)
			assert(part.Size == beforeSize and part.CFrame == beforeCFrame)
			part.CFrame *= CFrame.Angles(0, 0.3, 0)
			rejected(backend.SelectionBounds, "zero rotation")
			part:Destroy()
		end)
		check("native R1B guides are owned noninteractive planning geometry", function()
			local bounds = { X = 12000, Y = 4000, Z = 12000, Width = 1024, Height = 256, Length = 1024 }
			local pass = Guides.Prepare(bounds, "fixture")
			assert(pass.Parent == nil)
			pass.Parent = fixture
			Guides.Validate(pass)
			assert(#pass:GetChildren() == 22 and #pass:GetDescendants() == 44)
			local reserved = 0
			for _, part in ipairs(pass:GetChildren()) do
				assert(part:IsA("Part") and part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
				assert(part.Transparency == 1 and part:GetAttribute("PlanningOnly") == true)
				assert(part.Outline.Adornee == part)
				if part:GetAttribute("Reserved") then reserved += 1 end
			end
			assert(reserved == 3)
			result.GuideParts, result.ReservedMarkers = 22, reserved
			local manual = Instance.new("Folder")
			manual.Name, manual.Parent = "ManualContent", pass
			rejected(function() Guides.Validate(pass) end, "Unowned content")
			manual:Destroy()
			pass.Name = "DifferentPass"
			rejected(function() Guides.Validate(pass) end, "identity mismatch")
			pass:Destroy()
			assert(equal(actual, backend.Read(a)), "Guides changed Terrain")
		end)
		check("maximum R1B tile avoids native Part size clamping", function()
			local bounds = { X = 12000, Y = 4000, Z = 12000, Width = 2048, Height = 2048, Length = 2048 }
			local plan = Plan.Create(bounds)
			local pass = Guides.Prepare(bounds, "max-tile")
			pass.Parent = fixture
			for _, zone in ipairs(plan.Zones) do
				local part = pass:FindFirstChild(zone.Id)
				local expected = Vector3.new(zone.Bounds.Width, zone.Bounds.Height, zone.Bounds.Length)
				assert((part.Size - expected).Magnitude < 0.001, "Studio clamped guide geometry")
			end
			pass:Destroy()
		end)
		check("remove rejects unrelated selection before recording", function()
			Selection:Set({ fixture })
			rejected(backend.RemoveSelected, "not an owned")
			assert(fixture.Parent == game.ServerStorage)
		end)
		-- The connector has no installed-plugin identity. Check that its refusal
		-- leaves scene ownership unchanged; do not substitute a fake Undo service.
		local history = game:GetService("ChangeHistoryService")
		local began, recording = pcall(function() return history:TryBeginRecording("StratumFixtureProbe", "Stratum fixture probe") end)
		if began and recording then
			history:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
			result.RecordingRefusalTested = false
		else
			check("recording refusal leaves no archive or live guides", function()
				local archiveRoot = game.ServerStorage:FindFirstChild("StratumArchives")
				local generated = workspace:FindFirstChild("Generated")
				local guideRoot = generated and generated:FindFirstChild("StratumR1B")
				local archives = archiveRoot and #archiveRoot:GetChildren() or 0
				local passes = guideRoot and #guideRoot:GetChildren() or 0
				rejected(function() backend.Publish(capture) end, "declined an Undo recording")
				rejected(function() backend.CreateGuides(Plan.Create({ X = 12000, Y = 4000, Z = 12000, Width = 1024, Height = 256, Length = 1024 })) end,
					"declined an Undo recording")
				assert(game.ServerStorage:FindFirstChild("StratumArchives") == archiveRoot)
				assert(workspace:FindFirstChild("Generated") == generated)
				assert(not archiveRoot or #archiveRoot:GetChildren() == archives)
				assert(not guideRoot or #guideRoot:GetChildren() == passes)
			end)
			result.RecordingRefusalTested = true
		end
	end)
	-- Attempt both restorations independently even if one engine call fails.
	local restoredA, errorA = pcall(function() if modifiedA then write(a, originalA) end end)
	local restoredB, errorB = pcall(function() if modifiedB then write(b, originalB) end end)
	Selection:Set(priorSelection)
	assert(restoredA and restoredB, "Terrain cleanup failed: " .. tostring(errorA) .. "; " .. tostring(errorB))
	result.Restored = (not modifiedA or equal(Matrix.Flatten(originalA, a), backend.Read(a)))
		and (not modifiedB or equal(Matrix.Flatten(originalB, b), backend.Read(b)))
	assert(result.Restored, "Fixture cleanup differs from original Terrain")
	fixture:Destroy()
	assert(ok, tostring(failure))
	result.Passed = #result.Groups
	return result
end
