// ── Stat config ──────────────────────────────────────────
// To add a new stat: add an entry to this array.
// To remove one: delete its entry.
// To reorder: change the order here — pill follows automatically.
//
// Each entry:
//   id        — must match the key sent in UpdateHUD data from Lua
//   icon      — any Lucide icon name (kebab-case): https://lucide.dev/icons
//   color     — icon stroke color at normal value
//   warnLow   — turn red when value <= this (null = disabled)
//   warnHigh  — turn red when value >= this (null = disabled)

const STAT_CONFIG = [
    { id: "health", icon: "heart", color: "#3FA554", warnLow: 30, warnHigh: null },
    { id: "armor", icon: "shield", color: "#326dbf", warnLow: 30, warnHigh: null },
    { id: "hunger", icon: "coffee", color: "#dd6e14", warnLow: 30, warnHigh: null },
    { id: "thirst", icon: "droplets", color: "#1a7cad", warnLow: 30, warnHigh: null },
    { id: "stress", icon: "brain", color: "#9F7AEA", warnLow: null, warnHigh: 30 },

    // ── Adding a new stat is one object ───────────────────
    // { id: "oxygen", icon: "wind", color: "#5DCAA5", warnLow: 25, warnHigh: null },
];

// ── Lucide icon helper ────────────────────────────────────
// Lucide UMD structure: lucide[PascalName] = [defaultAttrs, children]
// Returns the inner SVG path markup as an HTML string.

function lucideIcon(name) {
    const key = name.replace(/(^|-)([a-z])/g, (_, __, c) => c.toUpperCase());
    const icon = lucide[key];
    if (!icon) {
        console.warn(`[HUD] Lucide icon "${name}" not found`);
        return "";
    }
    // icon IS the children array — no destructuring needed
    return (icon || [])
        .map(
            ([tag, attrs]) =>
                `<${tag} ${Object.entries(attrs)
                    .map(([k, v]) => `${k}="${v}"`)
                    .join(" ")}/>`,
        )
        .join("");
}

// ── Cash formatter ───────────────────────────────────────

function formatCash(n) {
    n = Math.round(n);
    if (n >= 1e9) return "$" + (n / 1e9).toFixed(1).replace(/\.0$/, "") + "b";
    if (n >= 1e6) return "$" + (n / 1e6).toFixed(1).replace(/\.0$/, "") + "m";
    if (n >= 1e3) return "$" + (n / 1e3).toFixed(1).replace(/\.0$/, "") + "k";
    return "$" + n;
}

// ── Build pill ───────────────────────────────────────────

function buildPill() {
    const pill = document.getElementById("hud-pill");
    if (!pill) return;

    // Voice segment — SVG paths managed by setVoice()
    pill.innerHTML = `
        <div class="seg">
            <svg id="voice-icon" class="voice-ico" viewBox="0 0 24 24" fill="none"
                 stroke="rgba(255,255,255,0.3)" stroke-width="1.75"
                 stroke-linecap="round" stroke-linejoin="round"></svg>
            <div class="pvbars" id="voice-bars">
                <div class="pvb" style="height:3px"></div>
                <div class="pvb" style="height:5px"></div>
                <div class="pvb" style="height:7px"></div>
                <div class="pvb" style="height:9px"></div>
                <div class="pvb" style="height:11px"></div>
            </div>
        </div>`;

    // One segment per stat
    STAT_CONFIG.forEach(({ id, icon, color }) => {
        const seg = document.createElement("div");
        seg.className = "seg";
        seg.innerHTML = `
            <svg class="stat-ico" viewBox="0 0 24 24" fill="none"
                 stroke="${color}" stroke-width="1.75"
                 stroke-linecap="round" stroke-linejoin="round">
                ${lucideIcon(icon)}
            </svg>
            <span class="stat-num" id="val-${id}">100</span>`;
        pill.appendChild(seg);
    });

    // Divider + cash — always last
    pill.insertAdjacentHTML(
        "beforeend",
        `
        <div class="seg-divider"></div>
        <div class="seg">
            <span class="cash-label">cash</span>
            <span class="cash-val" id="val-cash">$0</span>
        </div>`,
    );

    // Initialise voice icon to muted state
    setVoice("mute");
}

// ── Stat rendering ───────────────────────────────────────

function setStat(id, value) {
    const el = document.getElementById("val-" + id);
    if (!el) return;
    const cfg = STAT_CONFIG.find((s) => s.id === id);
    el.textContent = Math.round(value);
    let warn = false;
    if (cfg) {
        if (cfg.warnLow !== null && value <= cfg.warnLow) warn = true;
        if (cfg.warnHigh !== null && value >= cfg.warnHigh) warn = true;
    }
    el.classList.toggle("warn", warn);
}

// ── Voice indicator ──────────────────────────────────────

let voiceAnimFrame = null;

const VOICE_PATHS = {
    mic: [
        ["path", { d: "M12 2a3 3 0 0 1 3 3v7a3 3 0 0 1-6 0V5a3 3 0 0 1 3-3z" }],
        ["path", { d: "M19 10v2a7 7 0 0 1-14 0v-2" }],
        ["line", { x1: "12", y1: "19", x2: "12", y2: "22" }],
    ],
    radio: [
        ["path", { d: "M4.9 19.1C1 15.2 1 8.8 4.9 4.9" }],
        ["path", { d: "M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5" }],
        ["circle", { cx: "12", cy: "12", r: "2" }],
        ["path", { d: "M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5" }],
        ["path", { d: "M19.1 4.9C23 8.8 23 15.1 19.1 19" }],
    ],
};

function setVoice(mode) {
    // Cancel any running bar animation
    if (voiceAnimFrame) {
        cancelAnimationFrame(voiceAnimFrame);
        voiceAnimFrame = null;
    }

    const ico = document.getElementById("voice-icon");
    const bars = [...document.querySelectorAll("#voice-bars .pvb")];

    bars.forEach((b) => b.classList.remove("lit", "talking", "radio"));

    if (!ico) return;

    // Swap icon shape + stroke color
    const paths = mode === "radio" ? VOICE_PATHS.radio : VOICE_PATHS.mic;
    ico.innerHTML = paths
        .map(
            ([tag, attrs]) =>
                `<${tag} ${Object.entries(attrs)
                    .map(([k, v]) => `${k}="${v}"`)
                    .join(" ")}/>`,
        )
        .join("");
    ico.setAttribute("stroke", mode === "radio" ? "#5DCAA5" : mode === "talking" ? "#FFFF3E" : "rgba(255,255,255,0.3)");

    if (mode === "mute") return;

    // Animate bars
    let t = 0;

    function step() {
        t += 0.2;
        const level = Math.round(2.5 + 2.5 * Math.sin(t) * (0.5 + 0.5 * Math.random()));
        bars.forEach((b, i) => {
            const lit = i < level;
            b.classList.toggle("lit", lit);
            b.classList.toggle("talking", lit && mode === "talking");
            b.classList.toggle("radio", lit && mode === "radio");
        });
        voiceAnimFrame = requestAnimationFrame(step);
    }

    step();
}

// ── Message listener ─────────────────────────────────────
// Helix SendEvent(name, arg1, arg2, ...) arrives as:
//   event.data = { name: "EventName", args: [arg1, arg2, ...] }

window.addEventListener("message", function (event) {
    const msg = event.data;
    if (!msg || !msg.name) return;
    const args = msg.args || [];

    switch (msg.name) {
        case "UpdateHUD": {
            // Lua: SendEvent('UpdateHUD', health, armor, hunger, thirst, stress, playerDead)
            const [health, armor, hunger, thirst, stress, playerDead] = args;
            const pill = document.getElementById("hud-pill");
            if (pill) pill.style.display = "flex";
            const values = { health, armor, hunger, thirst, stress };
            STAT_CONFIG.forEach(({ id }) => {
                const value = values[id];
                if (value !== undefined) setStat(id, id === "health" && playerDead ? 100 : value);
            });
            break;
        }
        case "UpdateMoney": {
            // Lua: SendEvent('UpdateMoney', { cashAmount, bankAmount, type, ... })
            const arg = args[0];
            if (arg && arg.type === "cash" && arg.cashAmount !== undefined) {
                const el = document.getElementById("val-cash");
                if (el) el.textContent = formatCash(arg.cashAmount);
            }
            break;
        }
        case "ShowCashAmount": {
            // Lua: SendEvent('ShowCashAmount', amount)
            const el = document.getElementById("val-cash");
            if (el && args[0] !== undefined) el.textContent = formatCash(args[0]);
            break;
        }
        case "onRadio":
            // Lua: SendEvent('onRadio', bool)
            setVoice(args[0] ? "radio" : "mute");
            break;
        case "IsTalking":
            // Lua: SendEvent('IsTalking', isTalking)
            setVoice(args[0] ? "talking" : "mute");
            break;
        // ShowBankAmount / UpdateVoiceVolume — no-ops kept for Lua compatibility
    }
});

// ── Init ─────────────────────────────────────────────────

buildPill();
