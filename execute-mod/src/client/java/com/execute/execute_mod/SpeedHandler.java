package com.execute.execute_mod;

import net.minecraft.world.phys.Vec3;

/**
 * Applies real speed by scaling the movement delta each tick.
 * Runs at end of tick: scale the move that just happened by speedMultiplier.
 */
public class SpeedHandler {
    private static Vec3 lastPos = null;

    public static void tickEnd(net.minecraft.world.entity.player.Player player) {
        if (player == null || !player.level().isClientSide()) return;
        if (ModFeatures.CONFIG == null) return;
        float mult = ModFeatures.speedMultiplier();
        Vec3 cur = player.position();
        if (lastPos != null && mult > 1f) {
            Vec3 delta = cur.subtract(lastPos);
            double dx = lastPos.x + delta.x * mult;
            double dy = lastPos.y + delta.y * mult;
            double dz = lastPos.z + delta.z * mult;
            player.setPos(dx, dy, dz);
        }
        lastPos = player.position();
    }
}
