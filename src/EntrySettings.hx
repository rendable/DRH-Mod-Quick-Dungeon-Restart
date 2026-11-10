package mods.quick_dungeon_restart;

/** An immutable copy of the loading state's six entry arguments. */
class EntrySettings {
    public var mapNodeID:UInt;
    public var nodeType:String;
    public var friendID:UInt;
    public var mapID:UInt;
    public var jumpToMap:Bool;
    public var friendsOnly:Bool;

    public function new(state:Dynamic) {
        mapNodeID = integer(state, "mMapNodeID");
        nodeType = Std.string(Reflect.field(state, "mNodeType") == null ? "" : Reflect.field(state, "mNodeType"));
        friendID = integer(state, "mFriendID");
        mapID = integer(state, "mMapID");
        jumpToMap = Reflect.field(state, "mJumpToMapState") == true;
        friendsOnly = Reflect.field(state, "mFriendOnly") == true;
    }

    static function integer(state:Dynamic, name:String):UInt {
        var value:Dynamic = Reflect.field(state, name);
        return value == null ? 0 : Std.int(value);
    }

    public function valid():Bool { return mapNodeID != 0 || friendID != 0 || mapID != 0; }

    public static function shortcut(key:UInt, shift:Bool, ctrl:Bool, alt:Bool):Bool {
        return key == 82 && shift && !ctrl && !alt;
    }
}
