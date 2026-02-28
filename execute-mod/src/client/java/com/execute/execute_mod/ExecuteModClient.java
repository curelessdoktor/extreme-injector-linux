package com.execute.execute_mod;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.rendering.v1.HudRenderCallback;
import net.fabricmc.fabric.api.client.rendering.v1.world.WorldRenderEvents;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.world.entity.player.Abilities;
import org.lwjgl.glfw.GLFW;

public class ExecuteModClient implements ClientModInitializer {
    public static KeyMapping openMenuKey;
    public static KeyMapping toggleFlyKey;
    public static KeyMapping toggleEspKey;
    public static KeyMapping zoomKey;

    private static final KeyMapping.Category CATEGORY = KeyMapping.Category.MISC;

    @Override
    public void onInitializeClient() {
        ModFeatures.CONFIG = ExecuteConfig.load();

        openMenuKey = KeyBindingHelper.registerKeyBinding(new KeyMapping(
                "key.execute_mod.menu", GLFW.GLFW_KEY_RIGHT_SHIFT, CATEGORY));
        toggleFlyKey = KeyBindingHelper.registerKeyBinding(new KeyMapping(
                "key.execute_mod.fly", GLFW.GLFW_KEY_G, CATEGORY));
        toggleEspKey = KeyBindingHelper.registerKeyBinding(new KeyMapping(
                "key.execute_mod.esp", GLFW.GLFW_KEY_H, CATEGORY));
        zoomKey = KeyBindingHelper.registerKeyBinding(new KeyMapping(
                "key.execute_mod.zoom", GLFW.GLFW_KEY_C, CATEGORY));

        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (openMenuKey.consumeClick()) {
                if (client.screen == null) client.setScreen(new ExecuteMenuScreen(null));
                else if (client.screen instanceof ExecuteMenuScreen) client.screen.onClose();
            }
            while (toggleFlyKey.consumeClick()) {
                ModFeatures.CONFIG.flyEnabled = !ModFeatures.CONFIG.flyEnabled;
                ModFeatures.CONFIG.save();
            }
            while (toggleEspKey.consumeClick()) {
                ModFeatures.CONFIG.espEnabled = !ModFeatures.CONFIG.espEnabled;
                ModFeatures.CONFIG.save();
            }

            var player = client.player;
            if (player == null) return;

            Abilities abilities = player.getAbilities();
            if (ModFeatures.CONFIG.flyEnabled) {
                abilities.mayfly = true;
                abilities.flying = true;
                player.setNoGravity(true);
            } else {
                if (!player.isCreative() && !player.isSpectator()) {
                    abilities.mayfly = false;
                    abilities.flying = false;
                }
                player.setNoGravity(false);
            }

            float baseWalk = 0.1f;
            float baseFly = 0.05f;
            abilities.setWalkingSpeed(baseWalk * ModFeatures.CONFIG.speedMultiplier);
            abilities.setFlyingSpeed(baseFly * ModFeatures.CONFIG.speedMultiplier);

            SpeedHandler.tickEnd(player);
            CombatHandler.tick(client);
            HitSoundHandler.tick();

            if (ModFeatures.CONFIG.fullbright) {
                client.options.gamma().set(16.0);
            } else if (client.options.gamma().get() > 1.0) {
                client.options.gamma().set(1.0);
            }

            boolean zooming = zoomKey.isDown();
            int zoomFovInt = (int) ModFeatures.CONFIG.zoomFov;
            if (zooming && zoomFovInt < 90) {
                client.options.fov().set(zoomFovInt);
            } else if (!zooming && client.options.fov().get() != 90) {
                client.options.fov().set(90);
            }
        });

        WorldRenderEvents.END_MAIN.register(EspRenderer::render);
        HudRenderCallback.EVENT.register((gui, tickDelta) -> {
            float delta = tickDelta instanceof net.minecraft.client.DeltaTracker dt ? dt.getGameTimeDeltaPartialTick(false) : 0f;
            ExecuteHudRenderer.render(gui, delta);
            CrosshairRenderer.render(gui, gui.guiWidth(), gui.guiHeight());
        });

        try {
            net.fabricmc.fabric.api.event.player.AttackEntityCallback.EVENT.register((player, world, hand, entity, hitResult) -> {
                HitSoundHandler.onAttack(entity);
                return net.minecraft.world.InteractionResult.PASS;
            });
        } catch (NoClassDefFoundError | Exception ignored) {}
    }
}
