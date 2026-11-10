package mods.quick_dungeon_restart;

import mods.api.Mod;
import mods.api.Context;
import brain.assetRepository.AssetLoadingComponent;
import brain.assetRepository.SwfAsset;
import brain.uI.UIButton;
import brain.utils.TextUtil;
import facade.DBFacade;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.PNGEncoderOptions;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.text.TextField;

/** Offline fixture: no dungeon exit, reward transaction or entry request is sent. */
class SummaryProbe extends Mod {
    var context:Context;
    var assets:AssetLoadingComponent;
    var art:SwfAsset;
    var controls:SummaryControls;
    var root:MovieClip;
    var popup:MovieClip;
    var next:UIButton;
    var summary:Dynamic;
    var frames:Int = 0;
    var repeated:Int = 0;
    var nativeNext:Int = 0;
    var carried:Int = 0;
    var facade:DBFacade;
    var phase:String = "starting";

    function check(value:Bool, message:String):Void { if (!value) throw message; }

    override public function init(context:Context):Void {
        this.context = context;
        var data:Dynamic = {mRevealState:12, mTownHeader:{}, mItemCount:0, mLeaving:false};
        check(SummaryRules.blocked(data) == null, "settled summary was blocked");
        data.mItemCount = 1;
        check(SummaryRules.blocked(data) != null, "unclaimed crate was allowed");
        data.mItemCount = 0;
        data.mInfoPopup = {};
        check(SummaryRules.blocked(data) != null, "pending inventory refresh was allowed");
        data.mInfoPopup = null;
        data.mRevealState = 11;
        check(SummaryRules.blocked(data) != null, "unfinished reward reveal was allowed");
        data.mRevealState = 12;
        data.mLeaving = true;
        check(SummaryRules.blocked(data) != null, "duplicate exit was allowed");
        var privacy = new NextPrivacy();
        var loading:Dynamic = {mMapNodeID:222, mFriendOnly:false};
        privacy.arm(222, true);
        check(privacy.apply(loading) && loading.mFriendOnly == true, "Friends Only ON was lost");
        check(!privacy.apply(loading), "privacy callback ran twice");
        privacy.arm(222, false);
        check(privacy.apply(loading) && loading.mFriendOnly == false, "Friends Only OFF was lost");
        privacy.arm(333, true);
        check(!privacy.apply(loading) && loading.mFriendOnly == false, "unrelated dungeon was changed");
        context.log("summary probe: crate/reveal/transaction guards and Friends Only ON/OFF passed");
        context.overlay.addEventListener(Event.ENTER_FRAME, frame);
    }

    override public function ready(context:Context):Void {
        facade = context.core.facade;
    }

    function loadArt():Void {
        var loading = Reflect.field(facade.mainStateMachine, "mLoadingScreenState");
        check(loading != null, "native loading state missing");
        var oldNode = Reflect.field(loading, "mMapNodeID");
        var oldPrivacy = Reflect.field(loading, "mFriendOnly");
        Reflect.setField(loading, "mMapNodeID", 222);
        var privacy = new NextPrivacy();
        privacy.arm(222, true);
        check(privacy.apply(loading) && Reflect.field(loading, "mFriendOnly") == true, "native Friends Only ON failed");
        privacy.arm(222, false);
        check(privacy.apply(loading) && Reflect.field(loading, "mFriendOnly") == false, "native Friends Only OFF failed");
        Reflect.setField(loading, "mMapNodeID", oldNode);
        Reflect.setField(loading, "mFriendOnly", oldPrivacy);
        context.log("summary probe: native loading-state Friends Only ON/OFF and restoration passed");
        var reload = Reflect.field(facade.mainStateMachine, "mReloadTownState");
        var originalFinished = Reflect.field(reload, "mFinishedCallback");
        var refreshed = 0;
        facade.mainStateMachine.setOneShotReloadTownCallback(function() { refreshed++; });
        var finished = Reflect.field(reload, "mFinishedCallback");
        check(Reflect.isFunction(finished), "native one-shot account-refresh callback missing");
        Reflect.callMethod(reload, finished, []);
        check(refreshed == 1, "native one-shot account-refresh callback did not run");
        check(!Reflect.compareMethods(Reflect.field(reload, "mFinishedCallback"), finished), "one-shot callback did not reset");
        Reflect.setField(reload, "mFinishedCallback", originalFinished);
        context.log("summary probe: native one-shot account-refresh callback and restoration passed");
        assets = new AssetLoadingComponent(facade);
        assets.getSwfAsset(DBFacade.buildFullDownloadPath("Resources/Art2D/UI/db_UI_score_report.swf"),
            function(value:SwfAsset) { art = value; });
    }

    function frame(event:Event):Void {
        try { tick(event); } catch (error:Dynamic) {
            context.log("summary probe failed at " + phase + ": " + Std.string(error));
            context.overlay.removeEventListener(Event.ENTER_FRAME, frame);
            Sys.exit(2);
        }
    }

    function tick(event:Event):Void {
        frames++;
        if (frames > 1200) {
            context.log("summary art fixture timed out");
            Sys.exit(1);
            return;
        }
        if (frames < 120) return;
        phase = "find facade";
        if (facade == null) facade = cast findFacade(context.overlay.stage, 5);
        if (facade == null) return;
        phase = "load native art";
        if (assets == null) { loadArt(); return; }
        if (art == null) return;
        if (controls == null) {
            phase = "instantiate native score report";
            root = cast art.instantiateRuntimeSymbol("DRfriends_UI_score_report", []);
            phase = "stop score report";
            root.stop();
            popup = cast root.getChildByName("dungeon_popup");
            check(popup != null, "native dungeon popup missing");
            var button:MovieClip = cast popup.getChildByName("button_center");
            check(button != null, "native Next button missing");
            phase = "label Next";
            labels(button, "NEXT");
            phase = "construct native Next";
            next = new UIButton(facade, button);
            next.releaseCallback = function() { nativeNext++; };
            summary = {mRevealState:12, mTownHeader:{}, mItemCount:0, mLeaving:false,
                mScoreReportRoot:root, mNextFloorSection:{mBattleButton:next, mNextDungeon:{Id:222}}};
            phase = "construct Repeat controls";
            controls = new SummaryControls(facade, summary,
                function() { repeated++; }, function() { carried++; });
            context.overlay.addChild(root);
        }
        phase = "update Repeat controls";
        controls.update(true);
        var wrapper:MovieClip = cast popup.getChildByName("quick_dungeon_restart_repeat");
        if (wrapper == null) return;
        var repeat:UIButton = cast Reflect.field(controls, "repeat");
        check(repeat != null && repeat.enabled, "repeat button did not enable");
        var source:MovieClip = cast popup.getChildByName("button_center");
        var a = source.getBounds(popup);
        var b = wrapper.getBounds(popup);
        check(b.top >= a.bottom + 5, "Repeat overlaps Next");
        check(Math.abs(a.x + a.width / 2 - b.x - b.width / 2) < 1, "Repeat is not centered under Next");
        phase = "Repeat callback";
        Reflect.callMethod(repeat, Reflect.field(repeat, "mReleaseCallback"), []);
        phase = "Next callback";
        Reflect.callMethod(next, Reflect.field(next, "mReleaseCallback"), []);
        check(repeated == 1 && nativeNext == 1 && carried == 1, "button callbacks lost native Next or Repeat");
        phase = "disable Repeat";
        controls.update(false);
        check(!repeat.enabled, "pending reward state did not disable Repeat");
        phase = "enable Repeat";
        controls.update(true);
        check(repeat.enabled, "Repeat did not re-enable after rewards settled");
        phase = "render preview";
        var bounds = popup.getBounds(popup);
        var bitmap = new BitmapData(Std.int(Math.ceil(bounds.width * 2 + 20)),
            Std.int(Math.ceil(bounds.height * 2 + 20)), true, 0xFFFFA900);
        bitmap.draw(popup, new Matrix(2, 0, 0, 2, 10 - bounds.x * 2, 10 - bounds.y * 2));
        sys.io.File.saveBytes("C:/Users/DannyS/Documents/Codex/2026-11-09/new-chat/work/repeat-button-preview.png",
            bitmap.encode(bitmap.rect, new PNGEncoderOptions()));
        bitmap.dispose();
        phase = "destroy controls";
        controls.destroy();
        Reflect.callMethod(next, Reflect.field(next, "mReleaseCallback"), []);
        check(nativeNext == 2 && carried == 1, "native Next callback was not restored on cleanup");
        check(popup.getChildByName("quick_dungeon_restart_repeat") == null, "Repeat art leaked on cleanup");
        context.log("summary probe: native artwork, centered layout, enabled states, callbacks and cleanup passed");
        context.overlay.removeEventListener(Event.ENTER_FRAME, frame);
        Sys.exit(0);
    }

    function labels(node:DisplayObject, text:String):Void {
        if (Std.isOfType(node, TextField)) TextUtil.setText(cast node, text);
        if (Std.isOfType(node, DisplayObjectContainer)) {
            var container:DisplayObjectContainer = cast node;
            for (i in 0...container.numChildren) labels(container.getChildAt(i), text);
        }
    }

    function findFacade(node:DisplayObject, depth:Int):Dynamic {
        if (node == null) return null;
        var value = Reflect.field(node, "mDBFacade");
        if (value != null) return value;
        if (depth > 0 && Std.isOfType(node, DisplayObjectContainer)) {
            var container:DisplayObjectContainer = cast node;
            for (i in 0...container.numChildren) {
                var found = findFacade(container.getChildAt(i), depth - 1);
                if (found != null) return found;
            }
        }
        return null;
    }
}
