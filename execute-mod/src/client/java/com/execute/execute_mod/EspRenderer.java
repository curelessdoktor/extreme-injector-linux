package com.execute.execute_mod;

import net.fabricmc.fabric.api.client.rendering.v1.world.WorldRenderContext;

/**
 * ESP (entity outlines through walls) is stubbed on 1.21.11 because the rendering API changed.
 * Fly, Speed, and Menu work. Toggle ESP does nothing until this is reimplemented for the new pipeline.
 */
public class EspRenderer {

    public static void render(WorldRenderContext context) {
        if (!ModFeatures.espEnabled()) return;
        // 1.21.11 uses a new rendering pipeline (extraction/draw phases, no legacy RenderSystem).
        // ESP would need to be reimplemented using the new APIs. No-op for now.
    }
}
