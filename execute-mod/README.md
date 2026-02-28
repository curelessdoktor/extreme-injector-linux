# Execute – Minecraft 1.21.1 Fabric Mod

Client-side mod that adds **Fly**, **ESP** (entity outlines through walls), and **Speed** controls, with a smooth animated menu.

## Features

- **Fly** – Toggle flight (no gravity, creative-style flying). Keybind: **G**
- **ESP** – See entity hitboxes through walls (hostile = red, others = green). Keybind: **H**
- **Speed** – Change walk/fly speed (cycle 0.25x–10x from the menu or keep adjusting with the Speed button)
- **Menu** – **Right Shift** opens a smooth, animated panel with:
  - Fly ON/OFF
  - ESP ON/OFF
  - Speed (click to cycle)
  - Done to close

## Requirements

- Minecraft **1.21.1**
- **Fabric Loader** and **Fabric API**
- Java 21

## Build

1. Install [Gradle](https://gradle.org/install/) if you don’t have it (or run `gradle wrapper` in another Fabric project and copy `gradlew`, `gradlew.bat`, and `gradle/wrapper/` into this project).
2. From the mod folder:
   ```bash
   ./gradlew build
   ```
3. Output jar: `build/libs/execute-mod-1.0.0.jar`  
   Put it in your Minecraft `mods` folder with Fabric API.

## Keybinds

| Key         | Action     |
|------------|------------|
| Right Shift | Open/close menu |
| G          | Toggle Fly |
| H          | Toggle ESP |

## License

MIT
