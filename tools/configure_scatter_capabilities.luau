-- Approved scope: only the newly installed scatter code, with explicit API sets.
-- Existing scripts, ancestor folders and source models are not reconfigured.
local Capability = Enum.SecurityCapability
local geometryCapabilities = SecurityCapabilities.new(
	Capability.RunServerScript,
	Capability.Basic,
	Capability.CreateInstances,
	Capability.AccessOutsideWrite,
	Capability.Physics,
	Capability.CSG -- Existing UnionOperation nature assets require this geometry API.
)
local scatter = game.ReplicatedStorage.Tethys.WorldModules.Scatter
local driver = game.ServerStorage.TethysTools.NatureScatterDriver
assert(scatter:IsA("Folder") and driver:IsA("ModuleScript"), "Install the scatter code first")
scatter.Capabilities = geometryCapabilities
scatter.Sandboxed = true
-- Undo APIs use the Command Bar/connector's existing Studio identity; no Plugin
-- or LocalUser capability is added to these modules.
driver.Capabilities = geometryCapabilities
driver.Sandboxed = true
return "Configured only Nature Scatter's new folder and driver with explicit capabilities"
