package com.execute.execute_mod;

/**
 * Shared feature state. On client, ExecuteModClient sets CONFIG and we use it.
 * Fallback defaults if CONFIG is null (e.g. dedicated server).
 */
public class ModFeatures {
    public static ExecuteConfig CONFIG;

    public static boolean flyEnabled() { return CONFIG != null && CONFIG.flyEnabled; }
    public static boolean espEnabled() { return CONFIG != null && CONFIG.espEnabled; }
    public static float speedMultiplier() { return CONFIG != null ? CONFIG.speedMultiplier : 1f; }
}
