package com.execute.execute_mod;

import net.fabricmc.api.ModInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ExecuteMod implements ModInitializer {
    public static final String MOD_ID = "execute_mod";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        LOGGER.info("Execute mod initialized.");
    }
}
