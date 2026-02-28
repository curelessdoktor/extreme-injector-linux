# How to build the Execute mod

Do these in order in your terminal.

---

## Step 1: Java 17 or 21

The mod builds with **Java 17** or **Java 21**. If `java -version` shows 17 or 21, you're good.

---

## Step 2: Go to the mod folder

```bash
cd /home/doktordestrukt/Desktop/Execute/execute-mod
```

---

## Step 3: Build the mod

```bash
./gradlew build --no-daemon
```

*(First run may download Gradle and dependencies; give it a minute.)*

---

## Step 4: Get the built mod

When the build succeeds, the mod jar is here:

```
/home/doktordestrukt/Desktop/Execute/execute-mod/build/libs/execute-mod-1.0.0.jar
```

Copy that file into your Minecraft **mods** folder (e.g. `~/.minecraft/mods/`).  
You must have **Fabric Loader** and **Fabric API** for **1.21.1** installed.

---

## Quick copy-paste

```bash
cd /home/doktordestrukt/Desktop/Execute/execute-mod
./gradlew build --no-daemon
```

Then copy `build/libs/execute-mod-1.0.0.jar` into `~/.minecraft/mods/`.
