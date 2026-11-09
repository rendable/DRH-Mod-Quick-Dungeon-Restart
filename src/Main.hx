package mods.quick_restart;

import mods.api.Context;
import mods.api.Mod;
import brain.event.EventComponent;
import brain.stateMachine.State;
import brain.stateMachine.StateMachine;
import facade.DBFacade;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import stateMachine.mainStateMachine.LoadingScreenState;
import distributedObjects.PlayerGameObjectOwner;

class Main extends Mod {
    var context:Context;
    var facade:DBFacade;
    var saved:EntrySettings;
    var pendingEntry:EntrySettings;
    var exitHook:ExitHook = new ExitHook();
    var pending:Bool = false;
    var deadline:Float = 0;
    var shift:Bool = false;
    var ctrl:Bool = false;
    var alt:Bool = false;
    var player:PlayerGameObjectOwner;

    override public function init(context:Context):Void {
        this.context = context;
        context.core.onObjectReady(function(object) {
            if (Std.isOfType(object, PlayerGameObjectOwner)) {
                player = cast object;
                syncGold(player);
            }
        });
        context.core.onFieldReceived(function(object, field, name) {
            if (Std.isOfType(object, PlayerGameObjectOwner) && StringTools.endsWith(name, ".basicCurrency"))
                syncGold(cast object);
        });
        context.core.onObjectGone(function(object) {
            if (object == player) {
                syncGold(player);
                player = null;
            }
        });
        context.core.onStateEnter(stateEntered);
        context.core.onStateExit(function(machine, state) {
            if (facade != null && machine == facade.mainStateMachine && state.name == "RunState" && pending)
                cancel("restart cancelled by another state transition");
        });
        context.onKeyDown(function(key) {
            if (!EntrySettings.shortcut(key, shift, ctrl, alt)) return false;
            return requestRestart();
        });
        context.overlay.addEventListener(Event.ENTER_FRAME, update);
    }

    override public function ready(context:Context):Void {
        facade = context.core.facade;
        // Observe modifiers just before the core's priority-1000 key handler.
        // The core still handles chat focus, repeats and consuming the shortcut.
        facade.stageRef.addEventListener(KeyboardEvent.KEY_DOWN, observeKey, false, 1001);
        facade.stageRef.addEventListener(Event.DEACTIVATE, deactivated);
        if (facade.mainStateMachine.currentStateName == "RunState") captureRetainedEntry();
        context.log("loaded: Shift+R quick restart; Shift+E is unbound");
    }

    function observeKey(event:KeyboardEvent):Void {
        shift = event.shiftKey;
        ctrl = event.ctrlKey;
        alt = event.altKey;
    }

    function deactivated(event:Event):Void { shift = ctrl = alt = false; }

    function syncGold(owner:PlayerGameObjectOwner):Void {
        if (owner != null && facade != null && facade.dbAccountInfo != null)
            GoldCache.sync(facade.dbAccountInfo, owner.basicCurrency);
    }

    function stateEntered(machine:StateMachine, state:State):Void {
        if (facade == null || machine != facade.mainStateMachine) return;
        if (Std.isOfType(state, LoadingScreenState)) {
            var entry = new EntrySettings(state);
            saved = entry.valid() ? entry : null;
        }
    }

    function captureRetainedEntry():Void {
        var state = Reflect.field(facade.mainStateMachine, "mLoadingScreenState");
        if (state == null) return;
        var entry = new EntrySettings(state);
        if (entry.valid()) saved = entry;
    }

    function requestRestart():Bool {
        if (pending) return true;
        if (facade == null || !context.core.alive
            || facade.mainStateMachine.currentStateName != "RunState") return false;
        if (saved == null) captureRetainedEntry();
        if (saved == null || !saved.valid()) {
            context.log("restart unavailable: no valid dungeon entry settings");
            return true;
        }
        if (facade.mDistributedObjectManager == null || facade.mDistributedObjectManager.mMatchMaker == null) return true;
        var run = Reflect.field(facade.mainStateMachine, "mRunState");
        var events:EventComponent = cast Reflect.field(run, "mEventComponent");
        try {
            if (!exitHook.arm(events, exited)) {
                context.log("restart unavailable: normal dungeon exit handler was not found");
                return true;
            }
            pendingEntry = saved;
            syncGold(player);
            pending = true;
            deadline = Date.now().getTime() + 15000;
            context.log("restart requested; waiting for server exit confirmation");
            facade.mDistributedObjectManager.mMatchMaker.RequestExit();
        } catch (error:Dynamic) {
            cancel("restart request failed: " + Std.string(error));
        }
        return true;
    }

    function exited(event:Event):Void {
        if (!pending) return;
        var entry = pendingEntry;
        pending = false;
        pendingEntry = null;
        exitHook.restore();
        try {
            if (entry == null || !entry.valid()) throw "saved entry is unavailable";
            context.log("exit confirmed; re-entering dungeon");
            facade.mainStateMachine.enterLoadingScreenState(entry.mapNodeID, entry.nodeType,
                entry.friendID, entry.mapID, entry.jumpToMap, entry.friendsOnly);
        } catch (error:Dynamic) {
            context.log("restart failed; returning to town: " + Std.string(error));
            facade.mainStateMachine.enterReloadTownState();
        }
    }

    function update(event:Event):Void {
        if (pending && Date.now().getTime() > deadline) cancel("restart timed out; normal exit behavior restored");
    }

    function cancel(reason:String):Void {
        pending = false;
        pendingEntry = null;
        exitHook.restore();
        if (context != null) context.log(reason);
    }

    override public function dispose():Void {
        pending = false;
        pendingEntry = null;
        exitHook.restore();
        context.overlay.removeEventListener(Event.ENTER_FRAME, update);
        if (facade != null) {
            facade.stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, observeKey);
            facade.stageRef.removeEventListener(Event.DEACTIVATE, deactivated);
        }
        facade = null;
        player = null;
    }
}
