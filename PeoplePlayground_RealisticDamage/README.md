# Realistic Damage & Organ Failure (People Playground Mod)

A People Playground mod that makes damage more realistic and adds organ failure simulation.

## Features

### Realistic damage
- **Higher lethality**: Shot and impact damage multipliers increased so bullets and impacts are much more deadly.
- **Easier bone breakage**: Lower breaking threshold so limbs break more easily under force.
- **Reduced regeneration**: Very slow natural healing so injuries persist.
- **G-force sensitivity**: Characters pass out and take damage from impacts at lower G-forces.
- **More bleeding**: Wounds bleed more (higher blood loss rate).
- **Head and torso**: Extra damage multipliers on head and torso; breaking the head can be lethal.

### Organ failure
- **Heart**: When the heart limb is badly damaged, heart “efficiency” drops → consciousness and blood flow suffer, shock rises.
- **Lungs**: Punctured lungs (game’s existing system) cause oxygen to drop and consciousness to fall.
- **Brain**: Uses the game’s brain/braindead logic; head damage is more lethal.
- **Liver & kidneys**: Simulated from torso health; low torso health reduces “efficiency” and keeps pain and shock high (slower recovery, more shock).
- **Internal bleeding**: Severe torso damage and broken bones increase internal bleeding intensity, causing ongoing pain and shock.

### Extra effects
- **Broken bones**: Cause ongoing pain and a small amount of internal bleeding at the break site.
- **Severe torso damage**: Drives internal bleeding, high pain, high shock, and falling consciousness.
- **Organ failure cascade**: Heart, lung, liver, and kidney failure all push shock and consciousness in a more realistic direction.

## Installation

1. Locate your People Playground mods folder:
   - **Steam**: `Steam/steamapps/common/People Playground/Mods`
   - **Or**: In-game use the mods menu to open the Mods folder.
2. Copy the entire **PeoplePlayground_RealisticDamage** folder (containing `mod.json` and `script.cs`) into the Mods folder.
3. Enable the mod in People Playground’s mod menu and restart if needed.

## Usage

- In the spawn menu, under **People**, spawn **“Person - RealisticDamage”** instead of the default Person.
- Only characters spawned as “Person - RealisticDamage” use the realistic damage and organ systems.
- Use them with guns, explosions, falls, and other tools to see more lethal damage, organ failure, and bleeding.

## Requirements

- People Playground (Steam).
- No other mods required.

## File structure

```
PeoplePlayground_RealisticDamage/
  mod.json    - Mod metadata
  script.cs   - Realistic damage tuning + organ failure logic
  README.md   - This file
```

## Version

1.0.0
