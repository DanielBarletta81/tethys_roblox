import type { TerminalAction, TerminalJob } from "../shared/types/aquaponics";

export function permittedAction(job: TerminalJob, action: unknown): action is TerminalAction {
    return (job === "Hatchery" && action === "FeedHatchery")
        || (job === "Engineer" && (action === "DoseAlkalinity" || action === "FlushSystem"));
}
