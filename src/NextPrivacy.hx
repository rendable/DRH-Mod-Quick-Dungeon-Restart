package mods.quick_dungeon_restart;

/** The native Next callback omits makePrivate; apply it before LoadingScreenState enters. */
class NextPrivacy {
    var armed:Bool = false;
    var mapNodeID:UInt = 0;
    var friendsOnly:Bool = false;

    public function new() {}

    public function arm(mapNodeID:UInt, friendsOnly:Bool):Void {
        this.mapNodeID = mapNodeID;
        this.friendsOnly = friendsOnly;
        armed = mapNodeID != 0;
    }

    public function apply(loading:Dynamic):Bool {
        if (!armed) return false;
        armed = false;
        if (loading == null || Reflect.field(loading, "mMapNodeID") != mapNodeID) return false;
        Reflect.setField(loading, "mFriendOnly", friendsOnly);
        return true;
    }

    public function clear():Void { armed = false; }
}
