// src/server/JusticeSystem.server.ts
import { Workspace, Players, ReplicatedStorage } from "@rbxts/services";

const systems = ReplicatedStorage.WaitForChild("TethysSystems") as Folder;
function startJustice() {
const Events = systems.WaitForChild("Events") as Folder;
const ExecutionUI = Events.WaitForChild("ExecutionUI") as RemoteEvent;
const VarekConscription = Events.WaitForChild("VarekConscription") as RemoteEvent;

// Biometric Thresholds for Varek's Vanguard
const VANGUARD_STRENGTH_MIN = 85;
const VANGUARD_RESILIENCE_MIN = 80;
const EXECUTION_TIME_SECONDS = 180;

function triggerPublicExecution(player: Player, character: Model) {
    const plaza = Workspace.WaitForChild("ExecutionPlaza") as Folder;
    const stakes = plaza.WaitForChild("Stakes").GetChildren() as Part[];
    let openStake: Part | undefined;

    // Locate an unoccupied stake
    for (const stake of stakes) {
        if (!stake.FindFirstChild("OccupiedWeld")) {
            openStake = stake;
            break;
        }
    }

    const humanoid = character.FindFirstChildOfClass("Humanoid");
    if (!openStake || !humanoid) {
        if (humanoid) humanoid.Health = 0; // Overflow handling
        return;
    }

    // Mount player to the basalt stake
    const rootPart = character.PrimaryPart;
    if (rootPart) {
        character.PivotTo(openStake.CFrame.mul(new CFrame(0, 0, -1.5)));

        const weld = new Instance("WeldConstraint");
        weld.Name = "OccupiedWeld";
        weld.Part0 = rootPart;
        weld.Part1 = openStake;
        weld.Parent = openStake;
    }

    // Wipe inventory via global Lua function
    if (_G.ClearPlayerInventory) {
        _G.ClearPlayerInventory(player.UserId);
    }

    // Deploy UI isolation
    ExecutionUI.FireClient(player, "START", EXECUTION_TIME_SECONDS);
    print(`[JUSTICE] ${player.Name} mounted to the Weep's stakes.`);

    // Server-side biological expiration timer
    task.delay(EXECUTION_TIME_SECONDS, () => {
        if (character && humanoid && humanoid.Health > 0) {
            const weld = openStake?.FindFirstChild("OccupiedWeld");
            if (weld) weld.Destroy();
            humanoid.Health = 0; // The Weep claims them

            // Post-mortem: wipe the mark so they can re-enter society as a blank slate
            _G.UpdatePlayerState(player.UserId, { IsMarked: false, SpawnRouting: "Basin" });
        }
    });
}

function triggerVarekBypass(player: Player, character: Model) {
    print(`[JUSTICE] Biometric override. ${player.Name} claimed by Vanguard.`);

    const barracks = Workspace.WaitForChild("VarekBarracks") as Folder;
    const interrogationRoom = barracks.WaitForChild("InterrogationRoom") as Part;

    character.PivotTo(interrogationRoom.CFrame);

    const humanoid = character.FindFirstChildOfClass("Humanoid");
    if (humanoid) {
        humanoid.WalkSpeed = 16;
        humanoid.JumpPower = 50;
    }

    // Overwrite the ledger
    _G.UpdatePlayerState(player.UserId, {
        IsMarked: false,
        Faction: "Vanguard_Conscript",
        SpawnRouting: "HoldingCell" // Re-routing their next spawn
    });

    VarekConscription.FireClient(player);
}

function processArrest(player: Player) {
    const character = player.Character;
    const humanoid = character?.FindFirstChildOfClass("Humanoid");
    if (!character || !humanoid) return;

    // 1. Strip physical agency
    humanoid.WalkSpeed = 0;
    humanoid.JumpPower = 0;

    const holdingCell = (Workspace.WaitForChild("CityGate") as Folder).WaitForChild("HoldingCell") as Part;
    character.PivotTo(holdingCell.CFrame);

    // 2. Read the ledger
    const ledger = _G.GetPlayerData(player.UserId);
    if (!ledger) return;

    // 3. The Biometric Calculus
    if (ledger.Stats.Strength >= VANGUARD_STRENGTH_MIN && ledger.Stats.Resilience >= VANGUARD_RESILIENCE_MIN) {
        task.wait(2);
        triggerVarekBypass(player, character);
    } else {
        task.wait(2);
        triggerPublicExecution(player, character);
    }
}

// Attach scanner listener
const gateScanner = (Workspace.WaitForChild("CityGate") as Folder).WaitForChild("MainGateScanner") as Part;
gateScanner.Touched.Connect((hit: BasePart) => {
    const character = hit.Parent as Model;
    const player = Players.GetPlayerFromCharacter(character);

    if (player) {
        const ledger = _G.GetPlayerData(player.UserId);
        if (ledger && ledger.IsMarked) {
            processArrest(player);
        }
    }
});
}
if (systems.GetAttribute("JusticeEnabled") === true) startJustice();
