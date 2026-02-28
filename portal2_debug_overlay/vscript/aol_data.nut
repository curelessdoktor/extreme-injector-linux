// Aperture Overlay Link (AOL) - Portal 2 VScript (Squirrel)
// Singleplayer: outputs JSON each tick with player eye pos, view angles, and entity list.
// Prefix: AOL_DATA: so the Python app can parse from the game log.
//
// Setup: In your map, add a logic_script entity and set its VScript file to this script,
// or include it from another script. Then call AOL_Start() once (e.g. from OnMapSpawn
// or console: script AOL_Start). Ensure con_logfile is set so console is written to a file.
// Example: con_logfile portal2_console.log

const AOL_INTERVAL = 0.1;  // 10 Hz

function AOL_Start() {
    if (!IsMultiplayer()) {
        AOL_Tick();
    }
}

function AOL_Tick() {
    if (IsMultiplayer()) return;

    local player = GetPlayer();
    if (player == null) {
        EntFireByHandle(self, "RunScriptCode", "AOL_Tick()", AOL_INTERVAL, null, null);
        return;
    }

    local eye = player.EyePosition();
    local ang = player.GetAngles();
    local eyePos = [eye.x, eye.y, eye.z];
    local viewAngles = [ang.x, ang.y, ang.z];  // pitch, yaw, roll

    local entities = [];
    local e = null;
    local maxEnts = 256;
    local n = 0;

    e = Entities.First();
    while (e != null && n < maxEnts) {
        if (e.IsValid()) {
            local o = e.GetOrigin();
            local classname = e.GetClassname();
            if (classname != null && classname != "") {
                local targetname = e.GetName();
                if (targetname == null) targetname = "";
                local origin = [o.x, o.y, o.z];
                entities.append({ classname = classname, targetname = targetname, origin = origin });
                n++;
            }
        }
        e = Entities.Next(e);
    }

    local json = AOL_ToJson(eyePos, viewAngles, entities);
    printl("AOL_DATA:" + json);

    EntFireByHandle(self, "RunScriptCode", "AOL_Tick()", AOL_INTERVAL, null, null);
}

function AOL_Escape(s) {
    if (s == null) return "\"\"";
    local out = "\"";
    local i = 0;
    local len = s.len();
    while (i < len) {
        local c = s.slice(i, i + 1);
        if (c == "\\") out += "\\\\";
        else if (c == "\"") out += "\\\"";
        else if (c == "\n") out += "\\n";
        else if (c == "\r") out += "\\r";
        else out += c;
        i++;
    }
    out += "\"";
    return out;
}

function AOL_VecToJson(v) {
    return "[" + v[0] + "," + v[1] + "," + v[2] + "]";
}

function AOL_ToJson(eyePos, viewAngles, entities) {
    local parts = [];
    parts.append("\"player_eye_pos\":" + AOL_VecToJson(eyePos));
    parts.append("\"player_view_angles\":" + AOL_VecToJson(viewAngles));
    local entStrs = [];
    foreach (ent in entities) {
        local o = ent.origin;
        entStrs.append("{\"classname\":" + AOL_Escape(ent.classname) +
            ",\"targetname\":" + AOL_Escape(ent.targetname) +
            ",\"origin\":[" + o[0] + "," + o[1] + "," + o[2] + "]}");
    }
    local entArr = "";
    foreach (i, s in entStrs) {
        if (i > 0) entArr += ",";
        entArr += s;
    }
    parts.append("\"entities\":[" + entArr + "]");
    local body = "";
    foreach (i, p in parts) {
        if (i > 0) body += ",";
        body += p;
    }
    return "{" + body + "}";
}
