package mods.quick_dungeon_restart;

import brain.assetRepository.AssetLoadingComponent;
import brain.assetRepository.SwfAsset;
import brain.sceneGraph.SceneGraphManager;
import brain.uI.UIButton;
import brain.uI.UIObject;
import brain.utils.TextUtil;
import dBGlobals.DBGlobal;
import facade.DBFacade;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.text.TextField;

/** A fresh instance of the game's own score-report button, in the native summary layer. */
class SummaryControls {
    var facade:DBFacade;
    var summary:Dynamic;
    var assets:AssetLoadingComponent;
    var art:SwfAsset;
    var repeat:UIButton;
    var wrapper:MovieClip;
    var originalWrapper:MovieClip;
    var next:UIButton;
    var originalNext:Dynamic;
    var nextWrapper:Dynamic;
    var oldDown:UIObject;
    var onRepeat:Void->Void;
    var beforeNext:Void->Void;
    var dead:Bool = false;
    var enabled:Bool = false;

    public function new(facade:DBFacade, summary:Dynamic, onRepeat:Void->Void, beforeNext:Void->Void) {
        this.facade = facade;
        this.summary = summary;
        this.onRepeat = onRepeat;
        this.beforeNext = beforeNext;
        assets = new AssetLoadingComponent(facade);
        assets.getSwfAsset(DBFacade.buildFullDownloadPath("Resources/Art2D/UI/db_UI_score_report.swf"),
            function(value:SwfAsset) { if (!dead) art = value; });
    }

    public function update(available:Bool):Void {
        if (dead) return;
        var section:Dynamic = Reflect.field(summary, "mNextFloorSection");
        if (section == null) return;
        if (next == null) {
            next = cast Reflect.field(section, "mBattleButton");
            if (next == null || next.root == null) { next = null; return; }
            originalNext = next.releaseCallback;
            nextWrapper = function() {
                beforeNext();
                if (originalNext != null) Reflect.callMethod(next, originalNext, []);
            };
            next.releaseCallback = nextWrapper;
        }
        if (wrapper == null && art != null) build();
        if (wrapper == null || repeat == null || originalWrapper == null || originalWrapper.parent == null) return;
        var parent = originalWrapper.parent;
        wrapper.transform.matrix = originalWrapper.transform.matrix.clone();
        var nativeBounds = originalWrapper.getBounds(parent);
        var repeatBounds = wrapper.getBounds(parent);
        wrapper.x += nativeBounds.x + nativeBounds.width * 0.5 - repeatBounds.x - repeatBounds.width * 0.5;
        wrapper.y += nativeBounds.bottom + 6 - repeatBounds.top;
        wrapper.visible = originalWrapper.visible && Reflect.field(summary, "mLeaving") != true;
        if (available != enabled) {
            enabled = available;
            repeat.enabled = available;
            repeat.root.filters = available ? [] : [SceneGraphManager.getGrayScaleSaturationFilter(5)];
        }
        if (next.downNavigation != repeat) {
            oldDown = next.downNavigation;
            next.clearDownNavigation();
            next.downNavigation = repeat;
        }
    }

    function build():Void {
        var root:MovieClip = cast Reflect.field(summary, "mScoreReportRoot");
        var popup = child(root, "dungeon_popup");
        originalWrapper = cast child(popup, "button_center");
        if (originalWrapper == null || originalWrapper.parent == null) return;
        var fresh:MovieClip = cast art.instantiateRuntimeSymbol("DRfriends_UI_score_report", []);
        var copyPopup = child(fresh, "dungeon_popup");
        wrapper = cast child(copyPopup, "button_center");
        if (wrapper == null) throw "Native score report button was not found";
        wrapper.parent.removeChild(wrapper);
        wrapper.name = "quick_dungeon_restart_repeat";
        stopClips(wrapper);
        setLabels(wrapper);
        originalWrapper.parent.addChild(wrapper);
        repeat = new UIButton(facade, wrapper);
        repeat.rolloverFilter = DBGlobal.UI_ROLLOVER_FILTER;
        repeat.releaseCallback = function() { onRepeat(); };
        repeat.upNavigation = next;
        enabled = true; // Force the first update to apply the requested state.
    }

    static function child(root:DisplayObject, name:String):DisplayObject {
        if (!Std.isOfType(root, DisplayObjectContainer)) return null;
        return (cast root:DisplayObjectContainer).getChildByName(name);
    }

    static function stopClips(root:DisplayObject):Void {
        if (Std.isOfType(root, MovieClip)) (cast root:MovieClip).stop();
        if (Std.isOfType(root, DisplayObjectContainer)) {
            var container:DisplayObjectContainer = cast root;
            for (i in 0...container.numChildren) stopClips(container.getChildAt(i));
        }
    }

    static function setLabels(root:DisplayObject):Void {
        if (Std.isOfType(root, TextField)) {
            var label:TextField = cast root;
            label.selectable = false;
            label.mouseEnabled = false;
            TextUtil.setText(label, "REPEAT");
            // Six letters must fit inside the same native face as the four-letter NEXT.
            // Retain the authored font, color, outline and centered alignment.
            var height = label.textHeight;
            var format = label.getTextFormat();
            var size:Float = cast format.size;
            format.size = size * 0.72;
            label.defaultTextFormat = format;
            label.setTextFormat(format);
            label.y += (height - label.textHeight) * 0.5;
        }
        if (Std.isOfType(root, DisplayObjectContainer)) {
            var container:DisplayObjectContainer = cast root;
            for (i in 0...container.numChildren) setLabels(container.getChildAt(i));
        }
    }

    public function destroy():Void {
        if (dead) return;
        dead = true;
        if (next != null && next.root != null) {
            if (Reflect.compareMethods(next.releaseCallback, nextWrapper)) next.releaseCallback = originalNext;
            if (next.downNavigation == repeat) {
                next.clearDownNavigation();
                if (oldDown != null && oldDown.root != null) next.downNavigation = oldDown;
            }
            if (repeat != null && repeat.isFocused()) facade.menuNavigationController.setFocusedUiObject(next);
        }
        if (wrapper != null && wrapper.parent != null) wrapper.parent.removeChild(wrapper);
        if (repeat != null) repeat.destroy();
        if (assets != null) assets.destroy();
        repeat = null;
        wrapper = null;
        next = null;
        summary = null;
        art = null;
        facade = null;
    }
}
