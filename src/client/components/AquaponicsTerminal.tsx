import Roact from "@rbxts/roact";
import type { EcologyState, TerminalJob, TerminalAction } from "../../shared/types/aquaponics";
import { isEcologyState } from "../../shared/Guards";

interface TerminalProps {
    playerJob: TerminalJob;
    initialState: EcologyState;
    terminal: Model;
    actions: RemoteEvent;
    updates: RemoteEvent;
    onClose: () => void;
}

export class AquaponicsTerminal extends Roact.Component<TerminalProps, EcologyState> {
    private connection?: RBXScriptConnection;
    constructor(props: TerminalProps) {
        super(props);
        this.setState(props.initialState);
    }
    public didMount() {
        this.connection = this.props.updates.OnClientEvent.Connect((value: unknown) => {
            if (isEcologyState(value)) this.setState(value);
        });
    }
    public willUnmount() { this.connection?.Disconnect(); }
    private handleAction(action: TerminalAction) {
        this.props.actions.FireServer(action, this.props.terminal);
    }
    public render() {
        const ecology = this.state;
        const phStatusColor = (ecology.waterPH < 6.5 || ecology.waterPH > 7.5)
            ? Color3.fromRGB(255, 80, 80) : Color3.fromRGB(100, 255, 100);
        const nitrogenStatus = ecology.nitrogenPPM > 60 ? "HIGH" : "STABLE";

    return (
        <frame
            Size={new UDim2(0.6, 0, 0.7, 0)}
            Position={new UDim2(0.2, 0, 0.15, 0)}
            BackgroundColor3={Color3.fromRGB(15, 15, 20)}
            BorderSizePixel={2}
            BorderColor3={Color3.fromRGB(50, 150, 200)}
        >
            <textlabel
                Text="SKY CITY // AQUAPONICS TELEMETRY"
                Size={new UDim2(1, 0, 0.1, 0)}
                BackgroundColor3={Color3.fromRGB(10, 10, 15)}
                TextColor3={Color3.fromRGB(50, 200, 255)}
                Font={Enum.Font.Code}
                TextSize={24}
            />

            {/* Telemetry Readouts */}
            <frame Size={new UDim2(0.5, 0, 0.7, 0)} Position={new UDim2(0.05, 0, 0.15, 0)} BackgroundTransparency={1}>
                <textlabel Text={`Water pH: ${string.format("%.2f", ecology.waterPH)}`} TextColor3={phStatusColor} Size={new UDim2(1, 0, 0.2, 0)} Font={Enum.Font.Code} TextXAlignment={Enum.TextXAlignment.Left} BackgroundTransparency={1} TextSize={20} />
                <textlabel Text={`Nitrogen Load: ${string.format("%.1f", ecology.nitrogenPPM)} ppm - [${nitrogenStatus}]`} TextColor3={ecology.nitrogenPPM > 60 ? Color3.fromRGB(255, 100, 100) : Color3.fromRGB(200, 200, 200)} Size={new UDim2(1, 0, 0.2, 0)} Position={new UDim2(0, 0, 0.2, 0)} Font={Enum.Font.Code} TextXAlignment={Enum.TextXAlignment.Left} BackgroundTransparency={1} TextSize={20} />
                <textlabel Text={`Biomass: ${math.floor(ecology.fishBiomass)} kg`} TextColor3={Color3.fromRGB(200, 200, 200)} Size={new UDim2(1, 0, 0.2, 0)} Position={new UDim2(0, 0, 0.4, 0)} Font={Enum.Font.Code} TextXAlignment={Enum.TextXAlignment.Left} BackgroundTransparency={1} TextSize={20} />
                <textlabel Text={`Greenhouse Yield: ${math.floor(ecology.cropYield)}%`} TextColor3={Color3.fromRGB(200, 200, 200)} Size={new UDim2(1, 0, 0.2, 0)} Position={new UDim2(0, 0, 0.6, 0)} Font={Enum.Font.Code} TextXAlignment={Enum.TextXAlignment.Left} BackgroundTransparency={1} TextSize={20} />
            </frame>

            {/* Job-Specific Controls */}
            <frame Size={new UDim2(0.4, 0, 0.7, 0)} Position={new UDim2(0.55, 0, 0.15, 0)} BackgroundTransparency={1}>
                {this.props.playerJob === "Hatchery" && (
                    <textbutton
                        Text="FEED BIOMASS (Spikes Nitrogen)"
                        Size={new UDim2(1, 0, 0.2, 0)}
                        BackgroundColor3={Color3.fromRGB(30, 80, 50)}
                        TextColor3={Color3.fromRGB(255, 255, 255)}
                        Event={{ Activated: () => this.handleAction("FeedHatchery") }}
                    />
                )}
                {this.props.playerJob === "Engineer" && (
                    <>
                        <textbutton
                            Text="DOSE ALKALINITY (Raise pH)"
                            Size={new UDim2(1, 0, 0.2, 0)}
                            BackgroundColor3={Color3.fromRGB(80, 80, 150)}
                            TextColor3={Color3.fromRGB(255, 255, 255)}
                            Event={{ Activated: () => this.handleAction("DoseAlkalinity") }}
                        />
                        <textbutton
                            Text="INITIATE BIVALVE FLUSH (Drop Nitrogen)"
                            Size={new UDim2(1, 0, 0.2, 0)}
                            Position={new UDim2(0, 0, 0.3, 0)}
                            BackgroundColor3={Color3.fromRGB(150, 50, 50)}
                            TextColor3={Color3.fromRGB(255, 255, 255)}
                            Event={{ Activated: () => this.handleAction("FlushSystem") }}
                        />
                    </>
                )}
                {this.props.playerJob === "None" && (
                    <textlabel Text="UNAUTHORIZED. RESTRICTED CLEARANCE." TextColor3={Color3.fromRGB(255, 0, 0)} Size={new UDim2(1, 0, 0.2, 0)} BackgroundTransparency={1} />
                )}
            </frame>

            <textbutton Text="LOG OUT" Size={new UDim2(0.2, 0, 0.1, 0)} Position={new UDim2(0.4, 0, 0.85, 0)} BackgroundColor3={Color3.fromRGB(50, 15, 15)} TextColor3={Color3.fromRGB(255, 100, 100)} Event={{ Activated: this.props.onClose }} />
        </frame>
    );
    }
}
