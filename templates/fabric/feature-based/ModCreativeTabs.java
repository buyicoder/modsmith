package {{PACKAGE}}.common.registry;

import net.fabricmc.fabric.api.itemgroup.v1.ItemGroupEvents;
import net.minecraft.item.ItemGroups;
import {{PACKAGE}}.common.registry.ModItems;
import {{PACKAGE}}.common.registry.ModBlocks;

/**
 * Centralized creative tab population — Farmer's Delight pattern.
 * Extracted from main mod class to keep registration clean.
 */
public class ModCreativeTabs {

    public static void register() {
        // {{CREATIVE_TAB_ENTRIES}}
        // ItemGroupEvents.modifyEntriesEvent(ItemGroups.INGREDIENTS).register(entries -> {
        //     entries.add(ModItems.RUBY);
        // });
    }
}
