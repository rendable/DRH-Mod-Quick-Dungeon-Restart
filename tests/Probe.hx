package mods.quick_restart;

import mods.api.Mod;
import mods.api.Context;
import brain.assetRepository.AssetLoadingComponent;
import brain.event.EventComponent;
import openfl.events.Event;

class Probe extends Mod {
    function check(value:Bool, message:String):Void { if (!value) throw message; }
    function findFacade(node:openfl.display.DisplayObject, depth:Int):Dynamic {
        if (node == null) return null;
        var value = Reflect.field(node,"mDBFacade");
        if (value != null) return value;
        if (depth > 0 && Std.isOfType(node,openfl.display.DisplayObjectContainer)) {
            var container:openfl.display.DisplayObjectContainer = cast node;
            for (i in 0...container.numChildren) {
                var found = findFacade(container.getChildAt(i),depth-1);
                if (found != null) return found;
            }
        }
        return null;
    }

    override public function init(context:Context):Void {
        var source:Dynamic = {mMapNodeID:50026,mNodeType:"BOSS",mFriendID:123,mMapID:456,mJumpToMapState:true,mFriendOnly:true};
        var entry = new EntrySettings(source);
        source.mMapNodeID = 0;
        source.mFriendOnly = false;
        check(entry.valid() && entry.mapNodeID == 50026 && entry.nodeType == "BOSS" && entry.friendID == 123
            && entry.mapID == 456 && entry.jumpToMap && entry.friendsOnly,"six-argument snapshot changed");
        check(!new EntrySettings({}).valid(),"empty entry accepted");
        check(new EntrySettings({mFriendID:123}).valid(),"friend entry lost");
        check(new EntrySettings({mMapID:456}).valid(),"map entry lost");
        check(EntrySettings.shortcut(82,true,false,false),"Shift+R missing");
        check(!EntrySettings.shortcut(69,true,false,false),"Shift+E bound");
        check(!EntrySettings.shortcut(82,false,false,false),"R alone bound");
        check(!EntrySettings.shortcut(82,true,true,false),"Ctrl chord bound");
        check(!EntrySettings.shortcut(82,true,false,true),"Alt chord bound");
        var account:Dynamic = {mBasicCurrency:100};
        check(GoldCache.sync(account,125) && account.mBasicCurrency == 125,"earned gold not copied to HUD cache");
        check(!GoldCache.sync(account,125),"unchanged currency rewritten");
        check(GoldCache.sync(account,110) && account.mBasicCurrency == 110,"authoritative decrease ignored");
        check(GoldCache.sync(account,0) && account.mBasicCurrency == 0,"zero gold ignored");
        check(!GoldCache.sync(null,125),"missing account not handled");
        context.log("restart probe: authoritative gold cache synchronization, unchanged values, spending and zero balance passed");
        context.log("restart probe: immutable six settings, entry validation and Shift+R-only chord passed");
        var frames = 0;
        context.overlay.addEventListener(Event.ENTER_FRAME,function(event:Event) {
            if (++frames != 120) return;
            var facade:facade.DBFacade = cast findFacade(context.overlay.stage,5);
            var realAccount = facade.dbAccountInfo;
            // Offline startup stops before the normal account is created.
            if (realAccount == null) realAccount = new account.DBAccountInfo(facade);
            var originalGold = realAccount.basicCurrency;
            GoldCache.sync(realAccount,originalGold + 1);
            check(realAccount.basicCurrency == originalGold + 1,"native gold cache field was not updated");
            GoldCache.sync(realAccount,originalGold);
            check(realAccount.basicCurrency == originalGold,"native gold cache was not restored");
            context.log("restart probe: native account currency getter follows synchronized cache and restoration passed");
            var component = new EventComponent(facade);
            var name = "QUICK_RESTART_SELF_TEST";
            var normal = 0;
            var restarted = 0;
            var other = 0;
            var original = function(event:Event) { normal++; };
            var unrelated = function(event:Event) { other++; };
            component.addListener(name,original);
            facade.eventManager.addEventListener(name,unrelated);
            facade.eventManager.dispatchEvent(new Event(name));
            check(normal == 1 && other == 1,"baseline event failed");
            var hook = new ExitHook(name);
            var replacement = function(event:Event) { restarted++; hook.restore(); };
            check(hook.arm(component,replacement),"exit hook failed");
            check(!hook.arm(component,replacement),"duplicate exit hook allowed");
            facade.eventManager.dispatchEvent(new Event(name));
            check(normal == 1 && restarted == 1 && other == 2,"restart intercepted unrelated listeners or called town");
            facade.eventManager.dispatchEvent(new Event(name));
            check(normal == 2 && restarted == 1 && other == 3,"normal handler not restored");
            check(hook.arm(component,replacement),"second hook failed");
            hook.restore();
            hook.restore();
            facade.eventManager.dispatchEvent(new Event(name));
            check(normal == 3 && restarted == 1 && other == 4,"cancellation did not restore normal handler");
            component.removeListener(name);
            check(!hook.arm(component,replacement),"missing native handler was accepted");
            component.destroy();
            facade.eventManager.removeEventListener(name,unrelated);
            context.log("restart probe: native exit-listener replacement, acknowledgement, duplicate guard, unrelated listeners and cancellation restoration passed");
        });
    }
}
