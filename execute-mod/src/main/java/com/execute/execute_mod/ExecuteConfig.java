package com.execute.execute_mod;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import net.fabricmc.loader.api.FabricLoader;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/**
 * All mod options. Saved to config/execute_mod.json.
 */
public class ExecuteConfig {
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static Path configPath() {
        return FabricLoader.getInstance().getConfigDir().resolve("execute_mod.json");
    }

    // Movement
    public float speedMultiplier = 1.0f;
    public boolean flyEnabled = false;
    public boolean stepAssist = false;
    public boolean noFallDamage = false;
    public boolean autoSprint = false;
    public boolean noSlowdown = false;

    // Visual
    public boolean fullbright = false;
    public float zoomFov = 30f;
    public boolean zoomHold = true;
    public boolean espEnabled = false;
    public boolean coordinatesHud = true;
    public boolean fpsPingHud = true;
    public boolean reachDisplay = true;
    public boolean armorDurabilityHud = true;
    public boolean armorAlerts = true;
    public float armorAlertPercent = 20f;
    public boolean customCrosshair = true;
    public int crosshairStyle = 0; // 0=cross, 1=dot, 2=square, 3=circle
    public int crosshairColor = 0xFFFFFFFF;
    public float crosshairSize = 2f;
    public float crosshairGap = 2f;

    // Combat
    public boolean killAura = false;
    public float killAuraRange = 3.5f;
    public int killAuraDelayMs = 250;
    public float reach = 3.0f; // visual + client attack range
    public boolean comboTracker = true;
    public boolean hitSound = true;
    public String hitSoundId = "entity.player.attack.strong";
    public float hitSoundVolume = 0.5f;
    public boolean cpsCounter = true;
    public boolean practiceStats = true;

    // FPS / misc
    public boolean fpsBoost = false; // reduces particles etc when on
    public boolean frostedGlassUi = true;
    public boolean microAnimations = true;

    // Practice stats (runtime)
    public transient int sessionHits = 0;
    public transient int sessionDeaths = 0;
    public transient int sessionKills = 0;
    public transient int combo = 0;
    public transient int maxCombo = 0;

    public static ExecuteConfig load() {
        Path path = configPath();
        if (Files.exists(path)) {
            try {
                ExecuteConfig c = GSON.fromJson(Files.readString(path), ExecuteConfig.class);
                if (c != null) return c;
            } catch (Exception e) {
                ExecuteMod.LOGGER.warn("Failed to load config", e);
            }
        }
        ExecuteConfig c = new ExecuteConfig();
        c.save();
        return c;
    }

    public void save() {
        try {
            Files.createDirectories(configPath().getParent());
            Files.writeString(configPath(), GSON.toJson(this));
        } catch (IOException e) {
            ExecuteMod.LOGGER.warn("Failed to save config", e);
        }
    }

    public static final float MIN_SPEED = 0.25f;
    public static final float MAX_SPEED = 10f;
    public static final float MIN_REACH = 3f;
    public static final float MAX_REACH = 6f;
}
