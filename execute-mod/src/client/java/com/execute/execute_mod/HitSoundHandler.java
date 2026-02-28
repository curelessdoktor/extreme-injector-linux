package com.execute.execute_mod;

import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.minecraft.client.Minecraft;
import net.minecraft.client.resources.sounds.SimpleSoundInstance;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.Entity;

public class HitSoundHandler {
    private static long lastComboTime = 0;
    private static final long COMBO_TIMEOUT_MS = 1500;

    public static void onAttack(Entity target) {
        if (ModFeatures.CONFIG == null) return;
        if (ModFeatures.CONFIG.comboTracker) {
            ModFeatures.CONFIG.combo++;
            if (ModFeatures.CONFIG.combo > ModFeatures.CONFIG.maxCombo) {
                ModFeatures.CONFIG.maxCombo = ModFeatures.CONFIG.combo;
            }
            lastComboTime = System.currentTimeMillis();
        }
        if (ModFeatures.CONFIG.practiceStats) {
            ModFeatures.CONFIG.sessionHits++;
            if (target instanceof net.minecraft.world.entity.LivingEntity le && !le.isAlive()) {
                ModFeatures.CONFIG.sessionKills++;
            }
        }
        if (ModFeatures.CONFIG.hitSound && Minecraft.getInstance().getSoundManager() != null) {
            try {
                var id = net.minecraft.resources.Identifier.fromNamespaceAndPath("minecraft", ModFeatures.CONFIG.hitSoundId.replace(".", "_"));
                SoundEvent event = SoundEvent.createVariableRangeEvent(id);
                Minecraft.getInstance().getSoundManager().play(SimpleSoundInstance.forUI(event, 1f, ModFeatures.CONFIG.hitSoundVolume));
            } catch (Exception ignored) {}
        }
    }

    public static void tick() {
        if (ModFeatures.CONFIG == null) return;
        if (ModFeatures.CONFIG.comboTracker && System.currentTimeMillis() - lastComboTime > COMBO_TIMEOUT_MS) {
            ModFeatures.CONFIG.combo = 0;
        }
    }
}
