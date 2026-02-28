package com.execute.execute_mod;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.world.entity.EquipmentSlot;
import net.minecraft.world.item.ItemStack;

import java.util.ArrayList;
import java.util.List;

public class ExecuteHudRenderer {

    public static void render(GuiGraphics gui, float tickDelta) {
        if (ModFeatures.CONFIG == null) return;
        var client = Minecraft.getInstance();
        var player = client.player;
        if (player == null) return;

        int x = 2;
        int y = 2;
        int lineHeight = 10;
        var font = client.font;
        List<String> lines = new ArrayList<>();

        if (ModFeatures.CONFIG.coordinatesHud) {
            int ix = player.blockPosition().getX();
            int iy = player.blockPosition().getY();
            int iz = player.blockPosition().getZ();
            lines.add("§7XYZ §f" + ix + " §7/ §f" + iy + " §7/ §f" + iz);
        }
        if (ModFeatures.CONFIG.fpsPingHud) {
            int fps = client.getFps();
            int ping = 0;
            if (client.getConnection() != null && client.player != null) {
                var info = client.getConnection().getPlayerInfo(client.player.getUUID());
                if (info != null) ping = info.getLatency();
            }
            lines.add("§7FPS §f" + fps + (client.getConnection() != null ? " §7| §f" + ping + "ms" : ""));
        }
        if (ModFeatures.CONFIG.cpsCounter) {
            lines.add("§7CPS §fL: " + ClickTracker.getLeftCPS() + " §7R: " + ClickTracker.getRightCPS());
        }
        if (ModFeatures.CONFIG.reachDisplay) {
            float r = ModFeatures.CONFIG.reach;
            lines.add("§7Reach §f" + String.format("%.1f", r));
        }
        if (ModFeatures.CONFIG.comboTracker && ModFeatures.CONFIG.combo > 0) {
            lines.add("§cCombo §f" + ModFeatures.CONFIG.combo + " §7(max " + ModFeatures.CONFIG.maxCombo + ")");
        }
        if (ModFeatures.CONFIG.practiceStats) {
            lines.add("§7Hits §f" + ModFeatures.CONFIG.sessionHits + " §7Kills §f" + ModFeatures.CONFIG.sessionKills + " §7Deaths §f" + ModFeatures.CONFIG.sessionDeaths);
        }
        if (ModFeatures.CONFIG.armorDurabilityHud) {
            for (EquipmentSlot slot : new EquipmentSlot[]{EquipmentSlot.HEAD, EquipmentSlot.CHEST, EquipmentSlot.LEGS, EquipmentSlot.FEET}) {
                ItemStack stack = player.getItemBySlot(slot);
                if (!stack.isEmpty() && stack.getMaxDamage() > 0) {
                    int max = stack.getMaxDamage();
                    int dmg = stack.getDamageValue();
                    int pct = max > 0 ? (int)((1 - (double)dmg / max) * 100) : 100;
                    String name = slot.getName().substring(0, 1).toUpperCase() + slot.getName().substring(1);
                    if (ModFeatures.CONFIG.armorAlerts && pct <= ModFeatures.CONFIG.armorAlertPercent) {
                        lines.add("§c" + name + " §f" + pct + "%");
                    } else {
                        lines.add("§7" + name + " §f" + pct + "%");
                    }
                }
            }
        }

        for (int i = 0; i < lines.size(); i++) {
            gui.drawString(font, lines.get(i), x, y + i * lineHeight, 0xE0FFFFFF, false);
        }
    }
}
