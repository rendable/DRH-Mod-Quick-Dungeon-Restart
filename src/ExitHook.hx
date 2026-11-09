package mods.quick_restart;

import brain.event.EventComponent;

/** Temporarily replaces only RunState's own exit handler, preserving other listeners. */
class ExitHook {
    var eventName:String;
    var component:EventComponent;
    var original:Dynamic;

    public function new(eventName:String = "CLIENT_EXIT_COMPLETE") { this.eventName = eventName; }

    public function arm(component:EventComponent, callback:Dynamic):Bool {
        if (this.component != null || component == null) return false;
        var listeners:Dynamic = Reflect.field(component, "mRegisteredListeners");
        if (listeners == null) return false;
        var previous:Dynamic = listeners.itemFor(eventName);
        if (!Reflect.isFunction(previous)) return false;
        this.component = component;
        original = previous;
        component.removeListener(eventName);
        try {
            if (component.addListener(eventName, callback) == null) throw "exit listener could not be installed";
        } catch (error:Dynamic) {
            restore();
            throw error;
        }
        return true;
    }

    public function restore():Void {
        var previousComponent = component;
        var previous = original;
        component = null;
        original = null;
        if (previousComponent == null) return;
        var listeners:Dynamic = Reflect.field(previousComponent, "mRegisteredListeners");
        if (listeners == null) return;
        previousComponent.removeListener(eventName);
        if (previous != null) previousComponent.addListener(eventName, previous);
    }
}
