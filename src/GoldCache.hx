package mods.quick_dungeon_restart;

/** Preserve authoritative player currency in the account cache used by new HUDs. */
class GoldCache {
    public static function sync(account:Dynamic, gold:UInt):Bool {
        if (account == null) return false;
        if (Reflect.field(account, "mBasicCurrency") == gold) return false;
        Reflect.setField(account, "mBasicCurrency", gold);
        return true;
    }
}
