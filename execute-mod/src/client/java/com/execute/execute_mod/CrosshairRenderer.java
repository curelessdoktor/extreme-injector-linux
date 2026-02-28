package com.execute.execute_mod;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;

public class CrosshairRenderer {
    public static void render(GuiGraphics gui, int screenWidth, int screenHeight) {
        if (ModFeatures.CONFIG == null || !ModFeatures.CONFIG.customCrosshair) return;
        int cx = screenWidth / 2;
        int cy = screenHeight / 2;
        float size = ModFeatures.CONFIG.crosshairSize;
        float gap = ModFeatures.CONFIG.crosshairGap;
        int color = ModFeatures.CONFIG.crosshairColor;

        int s = (int) size;
        int g = (int) gap;
        // Cross (style 0)
        gui.fill(cx - s - g, cy - 1, cx - g, cy + 1, color);
        gui.fill(cx + g, cy - 1, cx + g + s, cy + 1, color);
        gui.fill(cx - 1, cy - s - g, cx + 1, cy - g, color);
        gui.fill(cx - 1, cy + g, cx + 1, cy + g + s, color);
    }
}
