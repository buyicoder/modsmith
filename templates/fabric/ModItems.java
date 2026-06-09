package {{PACKAGE}};

import java.util.function.Function;
import net.minecraft.item.Item;
import net.minecraft.item.Items;
import net.minecraft.registry.RegistryKey;
import net.minecraft.registry.RegistryKeys;
import net.minecraft.util.Identifier;

public class ModItems {
    {{ITEMS}}

    public static Item register(String path, Function<Item.Settings, Item> factory, Item.Settings settings) {
        RegistryKey<Item> key = RegistryKey.of(RegistryKeys.ITEM, Identifier.of({{MOD_ID_CONSTANT}}, path));
        return Items.register(key, factory, settings);
    }

    public static void initialize() {}
}
