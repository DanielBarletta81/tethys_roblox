import Roact from "@rbxts/roact";
import { CollectionService, Players, ReplicatedStorage, RunService } from "@rbxts/services";
import { AquaponicsTerminal } from "./components/AquaponicsTerminal";
import { isEcologyState } from "../shared/Guards";
import type { TerminalData } from "../shared/types/aquaponics";

const systems = ReplicatedStorage.WaitForChild("TethysSystems") as Folder;

function start() {
    const player = Players.LocalPlayer;
    const playerGui = player.WaitForChild("PlayerGui") as PlayerGui;
    const events = systems.WaitForChild("Events");
    const fetch = events.WaitForChild("FetchTerminalData") as RemoteFunction;
    const actions = events.WaitForChild("TerminalAction") as RemoteEvent;
    const updates = events.WaitForChild("UpdateCityEcology") as RemoteEvent;
    const bound = new Map<Instance, RBXScriptConnection>();
    let handle: Roact.Tree | undefined;
    let selected: Model | undefined;
    let opening = false;

    function close() {
        if (handle) Roact.unmount(handle);
        handle = undefined; selected = undefined;
    }
    function bind(terminal: Instance) {
        if (!terminal.IsA("Model") || bound.has(terminal)) return;
        const screen = terminal.FindFirstChild("Screen");
        const prompt = screen?.FindFirstChildOfClass("ProximityPrompt");
        if (!screen?.IsA("BasePart") || !prompt) return;
        bound.set(terminal, prompt.Triggered.Connect(() => {
            if (handle || opening) return;
            opening = true;
            const [ok, result] = pcall(() => fetch.InvokeServer(terminal) as unknown);
            opening = false;
            if (!ok || !typeIs(result, "table")) return;
            const data = result as TerminalData;
            if (!isEcologyState(data.state) || (data.job !== "Hatchery" && data.job !== "Engineer" && data.job !== "None")) return;
            selected = terminal;
            handle = Roact.mount(
                <screengui ResetOnSpawn={false}>
                    <AquaponicsTerminal playerJob={data.job} initialState={data.state} terminal={terminal}
                        actions={actions} updates={updates} onClose={close} />
                </screengui>, playerGui, "AquaponicsInterface",
            );
        }));
    }
    for (const terminal of CollectionService.GetTagged("TethysAquaponicsTerminal")) bind(terminal);
    CollectionService.GetInstanceAddedSignal("TethysAquaponicsTerminal").Connect(bind);
    CollectionService.GetInstanceRemovedSignal("TethysAquaponicsTerminal").Connect((terminal) => {
        bound.get(terminal)?.Disconnect(); bound.delete(terminal);
        if (selected === terminal) close();
    });
    player.CharacterRemoving.Connect(close);
    RunService.Heartbeat.Connect(() => {
        if (!selected) return;
        const screen = selected.FindFirstChild("Screen");
        const root = player.Character?.FindFirstChild("HumanoidRootPart");
        if (!screen?.IsA("BasePart") || !root?.IsA("BasePart") || root.Position.sub(screen.Position).Magnitude > 12) close();
    });
}

if (systems.GetAttribute("AquaponicsEnabled") === true) start();
