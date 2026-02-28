package com.execute.execute_mod;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraft.util.Mth;

public class ExecuteMenuScreen extends Screen {
    private static final int PANEL_WIDTH = 280;
    private static final int PANEL_HEIGHT = 260;
    private static final float ANIM_MS = 160f;
    private static final float EASE = 1.6f;
    private final Screen parent;
    private int tab = 0; // 0=Combat, 1=Defense, 2=Targeting, 3=Config
    private float openProgress = 0f;
    private long openTime = -1;

    public ExecuteMenuScreen(Screen parent) {
        super(Component.literal("Execute"));
        this.parent = parent;
    }

    private static float easeOutBack(float t) {
        if (t >= 1f) return 1f;
        return 1f + (EASE + 1) * (float) Math.pow(t - 1, 3) + EASE * (float) Math.pow(t - 1, 2);
    }

    @Override
    protected void init() {
        super.init();
        openTime = System.currentTimeMillis();
        int cx = width / 2;
        int top = height / 2 - PANEL_HEIGHT / 2;
        int y = top + 28;
        int btnW = 200;
        int btnH = 22;
        int spacing = 26;
        clearWidgets();

        int tabW = PANEL_WIDTH / 4;
        int left = cx - PANEL_WIDTH / 2;
        for (int i = 0; i < 4; i++) {
            final int ti = i;
            addRenderableWidget(Button.builder(Component.empty(), b -> { tab = ti; init(); }).bounds(left + i * tabW + 2, top + 2, tabW - 4, 20).build());
        }

        if (tab == 0) {
            addRenderableWidget(toggle("Kill Aura", () -> ModFeatures.CONFIG.killAura, () -> { ModFeatures.CONFIG.killAura = !ModFeatures.CONFIG.killAura; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Reach (display)", () -> ModFeatures.CONFIG.reachDisplay, () -> { ModFeatures.CONFIG.reachDisplay = !ModFeatures.CONFIG.reachDisplay; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(cycle("Reach: %.1f", () -> ModFeatures.CONFIG.reach, 3f, 6f, 0.5f, v -> { ModFeatures.CONFIG.reach = v; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Combo Tracker", () -> ModFeatures.CONFIG.comboTracker, () -> { ModFeatures.CONFIG.comboTracker = !ModFeatures.CONFIG.comboTracker; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Hit Sound", () -> ModFeatures.CONFIG.hitSound, () -> { ModFeatures.CONFIG.hitSound = !ModFeatures.CONFIG.hitSound; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("CPS Counter", () -> ModFeatures.CONFIG.cpsCounter, () -> { ModFeatures.CONFIG.cpsCounter = !ModFeatures.CONFIG.cpsCounter; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Custom Crosshair", () -> ModFeatures.CONFIG.customCrosshair, () -> { ModFeatures.CONFIG.customCrosshair = !ModFeatures.CONFIG.customCrosshair; ModFeatures.CONFIG.save(); }, cx - btnW/2, y));
        } else if (tab == 1) {
            addRenderableWidget(toggle("Step Assist", () -> ModFeatures.CONFIG.stepAssist, () -> { ModFeatures.CONFIG.stepAssist = !ModFeatures.CONFIG.stepAssist; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("No Fall Damage", () -> ModFeatures.CONFIG.noFallDamage, () -> { ModFeatures.CONFIG.noFallDamage = !ModFeatures.CONFIG.noFallDamage; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("No Slowdown", () -> ModFeatures.CONFIG.noSlowdown, () -> { ModFeatures.CONFIG.noSlowdown = !ModFeatures.CONFIG.noSlowdown; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Armor Alerts", () -> ModFeatures.CONFIG.armorAlerts, () -> { ModFeatures.CONFIG.armorAlerts = !ModFeatures.CONFIG.armorAlerts; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Armor HUD", () -> ModFeatures.CONFIG.armorDurabilityHud, () -> { ModFeatures.CONFIG.armorDurabilityHud = !ModFeatures.CONFIG.armorDurabilityHud; ModFeatures.CONFIG.save(); }, cx - btnW/2, y));
        } else if (tab == 2) {
            addRenderableWidget(toggle("Kill Aura", () -> ModFeatures.CONFIG.killAura, () -> { ModFeatures.CONFIG.killAura = !ModFeatures.CONFIG.killAura; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(cycle("Kill Aura Range: %.1f", () -> ModFeatures.CONFIG.killAuraRange, 2f, 6f, 0.5f, v -> { ModFeatures.CONFIG.killAuraRange = v; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(cycleInt("Delay (ms): %d", () -> ModFeatures.CONFIG.killAuraDelayMs, 50, 500, 50, v -> { ModFeatures.CONFIG.killAuraDelayMs = v; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("ESP", () -> ModFeatures.CONFIG.espEnabled, () -> { ModFeatures.CONFIG.espEnabled = !ModFeatures.CONFIG.espEnabled; ModFeatures.CONFIG.save(); }, cx - btnW/2, y));
        } else {
            addRenderableWidget(toggle("Fly", () -> ModFeatures.CONFIG.flyEnabled, () -> { ModFeatures.CONFIG.flyEnabled = !ModFeatures.CONFIG.flyEnabled; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(cycle("Speed: %.1fx", () -> ModFeatures.CONFIG.speedMultiplier, ExecuteConfig.MIN_SPEED, ExecuteConfig.MAX_SPEED, 0.5f, v -> { ModFeatures.CONFIG.speedMultiplier = v; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Fullbright", () -> ModFeatures.CONFIG.fullbright, () -> { ModFeatures.CONFIG.fullbright = !ModFeatures.CONFIG.fullbright; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Auto Sprint", () -> ModFeatures.CONFIG.autoSprint, () -> { ModFeatures.CONFIG.autoSprint = !ModFeatures.CONFIG.autoSprint; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Coordinates", () -> ModFeatures.CONFIG.coordinatesHud, () -> { ModFeatures.CONFIG.coordinatesHud = !ModFeatures.CONFIG.coordinatesHud; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("FPS/Ping", () -> ModFeatures.CONFIG.fpsPingHud, () -> { ModFeatures.CONFIG.fpsPingHud = !ModFeatures.CONFIG.fpsPingHud; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(toggle("Practice Stats", () -> ModFeatures.CONFIG.practiceStats, () -> { ModFeatures.CONFIG.practiceStats = !ModFeatures.CONFIG.practiceStats; ModFeatures.CONFIG.save(); }, cx - btnW/2, y)); y += spacing;
            addRenderableWidget(Button.builder(Component.literal("Reset session stats"), b -> {
                ModFeatures.CONFIG.sessionHits = 0; ModFeatures.CONFIG.sessionKills = 0; ModFeatures.CONFIG.sessionDeaths = 0;
                ModFeatures.CONFIG.combo = 0; ModFeatures.CONFIG.maxCombo = 0; ModFeatures.CONFIG.save();
            }).bounds(cx - btnW/2, y, btnW, btnH).build());
        }
    }

    private Button toggle(String label, java.util.function.BooleanSupplier state, Runnable action, int x, int y) {
        return Button.builder(Component.literal(label + ": " + (state.getAsBoolean() ? "ON" : "OFF")), b -> {
            action.run();
            b.setMessage(Component.literal(label + ": " + (state.getAsBoolean() ? "ON" : "OFF")));
        }).bounds(x, y, 200, 22).build();
    }

    private Button cycle(String fmt, java.util.function.DoubleSupplier current, double min, double max, double step, java.util.function.Consumer<Float> setter, int x, int y) {
        float cur = (float) current.getAsDouble();
        return Button.builder(Component.literal(String.format(fmt, cur)), b -> {
            double next = current.getAsDouble() + step;
            if (next > max) next = min;
            setter.accept((float) next);
            b.setMessage(Component.literal(String.format(fmt, next)));
        }).bounds(x, y, 200, 22).build();
    }

    private Button cycleInt(String fmt, java.util.function.IntSupplier current, int min, int max, int step, java.util.function.Consumer<Integer> setter, int x, int y) {
        int cur = current.getAsInt();
        return Button.builder(Component.literal(String.format(fmt, cur)), b -> {
            int next = current.getAsInt() + step;
            if (next > max) next = min;
            setter.accept(next);
            b.setMessage(Component.literal(String.format(fmt, next)));
        }).bounds(x, y, 200, 22).build();
    }

    @Override
    public void render(GuiGraphics gui, int mouseX, int mouseY, float partialTick) {
        long now = System.currentTimeMillis();
        if (openTime > 0) {
            float elapsed = (now - openTime) / 1000f;
            openProgress = Mth.clamp(elapsed / (ANIM_MS / 1000f), 0f, 1f);
            openProgress = easeOutBack(openProgress);
        }
        int cx = width / 2;
        int cy = height / 2;
        int w = (int)(PANEL_WIDTH * openProgress);
        int h = (int)(PANEL_HEIGHT * openProgress);
        int left = cx - w/2;
        int top = cy - h/2;

        gui.fill(0, 0, width, height, 0x40000000);
        gui.fill(left - 1, top - 1, left + w + 1, top + h + 1, 0xFF505070);
        gui.fill(left, top, left + w, top + h, 0xE0181828);

        String[] tabs = new String[]{"Combat", "Defense", "Targeting", "Config"};
        int tabW = w / 4;
        for (int i = 0; i < 4; i++) {
            int tx = left + i * tabW;
            int c = (tab == i) ? 0xFF6080B0 : 0xFF404060;
            gui.fill(tx + 2, top + 2, tx + tabW - 2, top + 22, c);
            gui.drawCenteredString(font, tabs[i], tx + tabW/2, top + 7, 0xFFFFFF);
        }
        gui.drawCenteredString(font, "Execute", cx, top + 4, 0xE0FFFFFF);

        super.render(gui, mouseX, mouseY, partialTick);
    }

    @Override
    public void onClose() {
        if (minecraft != null) minecraft.setScreen(parent);
    }
}
