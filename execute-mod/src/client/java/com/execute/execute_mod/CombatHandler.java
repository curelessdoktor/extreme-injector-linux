package com.execute.execute_mod;

import net.minecraft.client.Minecraft;
import net.minecraft.client.player.LocalPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;

import java.util.Comparator;

public class CombatHandler {
    private static long lastKillAuraTime = 0;

    public static void tick(Minecraft client) {
        if (ModFeatures.CONFIG == null) return;
        Player player = client.player;
        if (player == null) return;

        // Step assist (1.21.11: set via reflection; Entity has maxUpStep() getter)
        if (ModFeatures.CONFIG.stepAssist) {
            setMaxUpStep(player, 1f);
        } else {
            setMaxUpStep(player, 0.6f);
        }

        // Auto sprint
        if (ModFeatures.CONFIG.autoSprint && client.options.keySprint != null) {
            boolean moving = player.getAbilities().mayfly ? player.getDeltaMovement().horizontalDistanceSqr() > 1e-6 : (player instanceof LocalPlayer lp && lp.input != null && lp.input.hasForwardImpulse());
            if (moving) player.setSprinting(true);
        }

        // No fall damage (client-side)
        if (ModFeatures.CONFIG.noFallDamage) {
            player.fallDistance = 0f;
        }

        // No slowdown: client can't fully remove block slowdown without mixin
        if (ModFeatures.CONFIG.noSlowdown) {
            player.setNoActionTime(0);
        }

        // Kill aura
        if (ModFeatures.CONFIG.killAura && client.gameMode != null && client.gameMode.getPlayerMode().isCreative() == false) {
            long now = System.currentTimeMillis();
            if (now - lastKillAuraTime >= ModFeatures.CONFIG.killAuraDelayMs) {
                LivingEntity target = findKillAuraTarget(player);
                if (target != null) {
                    client.gameMode.attack(player, target);
                    HitSoundHandler.onAttack(target);
                    lastKillAuraTime = now;
                }
            }
        }
    }

    private static void setMaxUpStep(Entity entity, float value) {
        try {
            var setter = Entity.class.getMethod("setMaxUpStep", float.class);
            setter.invoke(entity, value);
        } catch (NoSuchMethodException e) {
            try {
                var field = Entity.class.getDeclaredField("maxUpStep");
                field.setAccessible(true);
                field.setFloat(entity, value);
            } catch (Exception ignored) {}
        } catch (Exception ignored) {}
    }

    private static LivingEntity findKillAuraTarget(Player player) {
        double range = ModFeatures.CONFIG.killAuraRange;
        Vec3 eye = player.getEyePosition(1f);
        AABB box = new AABB(eye.x - range, eye.y - range, eye.z - range, eye.x + range, eye.y + range, eye.z + range);
        return player.level().getEntitiesOfClass(LivingEntity.class, box, e ->
            e != player && e.isAlive() && !e.isSpectator() && player.hasLineOfSight(e)
        ).stream()
            .min(Comparator.comparingDouble(e -> player.distanceToSqr(e)))
            .orElse(null);
    }
}
