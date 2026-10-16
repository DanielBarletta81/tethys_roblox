import { AquaponicsManager } from '../src/server/services/AquaponicsManager';
import { permittedAction } from '../src/server/TerminalPolicy';
import { TransientManager } from '../src/server/services/TransientManager';

it('returns independent snapshots without exposing the simulation state', () => {
    const manager = new AquaponicsManager();
    const snapshot = manager.getState(); snapshot.fishBiomass=0;
    expect(manager.getState().fishBiomass).toBe(5000);
});
it.each([NaN, Infinity, -1, 0, 101])('rejects invalid feed amount %p', (amount) => {
    const manager = new AquaponicsManager(); const before=manager.getState();
    expect(manager.feedHatchery(amount)).toBe(false); expect(manager.getState()).toEqual(before);
});
it.each([NaN, Infinity, -1, 0, 11])('rejects invalid buffer amount %p', (amount) => {
    const manager = new AquaponicsManager(); const before=manager.getState();
    expect(manager.doseAlkalinity(amount)).toBe(false); expect(manager.getState()).toEqual(before);
});
it('feeds the city using server-selected quantities', () => {
    const manager=new AquaponicsManager(); expect(manager.feedHatchery(50)).toBe(true);
    expect(manager.getState()).toMatchObject({fishBiomass:5040,nitrogenPPM:50});
});
it('keeps flush nitrogen nonnegative', () => {
    const manager=new AquaponicsManager({nitrogenPPM:5});manager.flushSystem();expect(manager.getState().nitrogenPPM).toBe(0);
});
it('caps fish biomass and reports the acid crash', () => {
    const manager=new AquaponicsManager({fishBiomass:9999,waterPH:4.5});manager.feedHatchery(50);
    expect(manager.getState().fishBiomass).toBe(10000);manager.executeGlobalTick();
    expect(manager.getState().fishBiomass).toBe(9500);expect(manager.getSystemDiagnostics().status).toBe('CRITICAL');
});
it('authorizes actions by authoritative job instead of button visibility', () => {
    expect(permittedAction('None','FeedHatchery')).toBe(false);
    expect(permittedAction('Hatchery','FlushSystem')).toBe(false);
    expect(permittedAction('Engineer','FlushSystem')).toBe(true);
    expect(permittedAction('Engineer',{action:'FlushSystem'})).toBe(false);
});
it('does not let negative skimming increase crate inventory', () => {
    const manager=new TransientManager();const crate={crateId:'fixture',originalWeightKg:100,currentWeightKg:100,resourceType:'FISH_FEED' as const};
    expect(manager.skimCrate(crate,-25)).toBe(0);expect(crate.currentWeightKg).toBe(100);
});
it('routes a severe shortage through the supplied server mark owner', () => {
    const mark=jest.fn();const manager=new TransientManager(mark);
    expect(manager.processDelivery('42',{crateId:'fixture',originalWeightKg:100,currentWeightKg:50,resourceType:'FISH_FEED'}).isMarked).toBe(true);
    expect(mark).toHaveBeenCalledWith('42');
});
it('rejects malformed weights without creating rewards or marking a player', () => {
    const mark=jest.fn();const manager=new TransientManager(mark);
    expect(manager.processDelivery('42',{crateId:'fixture',originalWeightKg:0,currentWeightKg:100,resourceType:'FISH_FEED'})).toMatchObject({isMarked:false,payoutScrip:0});
    expect(mark).not.toHaveBeenCalled();
});
