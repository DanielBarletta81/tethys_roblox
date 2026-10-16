// Policy helpers shared by Node tests and compiled Luau.
export function min(a: number, b: number): number { return a < b ? a : b; }
export function max(a: number, b: number): number { return a > b ? a : b; }
export function whole(value: number): number { return value - value % 1; }
export function positiveAmount(value: number, maximum: number): boolean {
    return value > 0 && value <= maximum;
}
