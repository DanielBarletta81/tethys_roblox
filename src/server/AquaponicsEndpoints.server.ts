import { CollectionService, Players, ReplicatedStorage, Workspace } from "@rbxts/services";
import { AquaponicsManager } from "./services/AquaponicsManager";
import { getProfile } from "./ProfileAccess";
import { permittedAction } from "./TerminalPolicy";
import type { TerminalJob } from "../shared/types/aquaponics";

const systems = ReplicatedStorage.WaitForChild("TethysSystems") as Folder;

function start() {
    const events = systems.WaitForChild("Events") as Folder;
    const actions = events.WaitForChild("TerminalAction") as RemoteEvent;
    const fetch = events.WaitForChild("FetchTerminalData") as RemoteFunction;
    const updates = events.WaitForChild("UpdateCityEcology") as RemoteEvent;
    const cityEcology = new AquaponicsManager();
    const lastAction = new Map<Player, number>();

    function validTerminal(player: Player, target: unknown): target is Model {
        if (!typeIs(target, "Instance") || !target.IsA("Model") || !target.IsDescendantOf(Workspace)
            || !CollectionService.HasTag(target, "TethysAquaponicsTerminal")) return false;
        const screen = target.FindFirstChild("Screen");
        const root = player.Character?.FindFirstChild("HumanoidRootPart");
        const human = player.Character?.FindFirstChildOfClass("Humanoid");
        return screen !== undefined && screen.IsA("BasePart") && root !== undefined && root.IsA("BasePart")
            && human !== undefined && human.Health > 0 && root.Position.sub(screen.Position).Magnitude <= 10;
    }
    function jobFor(player: Player): TerminalJob {
        const job = getProfile(player)?.CurrentJob;
        return job === "Hatchery" || job === "Engineer" ? job : "None";
    }
    fetch.OnServerInvoke = (player: Player, terminal: unknown) => {
        if (!validTerminal(player, terminal)) return undefined;
        return { job: jobFor(player), state: cityEcology.getState() };
    };
    actions.OnServerEvent.Connect((player: Player, action: unknown, terminal: unknown) => {
        if (!validTerminal(player, terminal) || !permittedAction(jobFor(player), action)) return;
        const now = os.clock();
        if (now - (lastAction.get(player) ?? -2) < 2) return;
        lastAction.set(player, now);
        if (action === "FeedHatchery") cityEcology.feedHatchery(50);
        else if (action === "DoseAlkalinity") cityEcology.doseAlkalinity(10);
        else cityEcology.flushSystem();
        updates.FireAllClients(cityEcology.getState());
    });
    Players.PlayerRemoving.Connect((player) => lastAction.delete(player));
    task.spawn(() => {
        while (systems.Parent && systems.GetAttribute("AquaponicsEnabled") === true) {
            task.wait(60);
            if (systems.GetAttribute("AquaponicsEnabled") !== true) break;
            cityEcology.executeGlobalTick();
            updates.FireAllClients(cityEcology.getState());
        }
    });
}

// Author terminals and connect the existing profile owner before enabling this slice.
if (systems.GetAttribute("AquaponicsEnabled") === true) start();
