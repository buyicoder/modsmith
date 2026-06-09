package {{PACKAGE}}.common.registry;

import java.util.function.Function;
import net.minecraft.item.Item;
import net.minecraft.item.Items;
import net.minecraft.registry.RegistryKey;
import net.minecraft.registry.RegistryKeys;
import net.minecraft.util.Identifier;
import {{PACKAGE}}.{{MOD_CLASS}};

/**
 * Centralized item registration — Farmer's Delight pattern.
 * All items registered here. Custom item classes go in common/item/.
 */
public class ModItems {
    {{ITEMS}}

    public static Item register(String path, Function<Item.Settings, Item> factory, Item.Settings settings) {
        RegistryKey<Item> key = RegistryKey.of(RegistryKeys.ITEM, Identifier.of({{MOD_CLASS}}.MOD_ID, path));
        return Items.register(key, factory, settings);
    }

    public static void initialize() {}
}
