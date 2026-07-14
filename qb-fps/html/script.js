(function () {
    "use strict";

    const LS_PRESET = "qb-fps:preset";
    const LS_VALUES = "qb-fps:values";

    let cfg = null;          // payload from Lua: cvars, presets, presetOrder
    let current = {};        // cvar -> value applied right now
    let currentPreset = null;
    let statusTimer = null;

    // ── Lucide icon helper (same approach as qb-menu / qb-hud) ────────────
    function lucideSvg(name) {
        if (!name || typeof lucide === "undefined") return "";
        const key = name.replace(/(^|-)([a-z])/g, (_, __, c) => c.toUpperCase());
        const icon = lucide[key];
        if (!icon) return "";
        const inner = (icon || [])
            .map(([tag, attrs]) =>
                `<${tag} ${Object.entries(attrs).map(([k, v]) => `${k}="${v}"`).join(" ")}/>`)
            .join("");
        return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"
            stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">${inner}</svg>`;
    }

    function paintStaticIcons() {
        document.querySelectorAll("[data-icon]").forEach((el) => {
            el.innerHTML = lucideSvg(el.getAttribute("data-icon"));
        });
    }

    // ── Lua bridge ────────────────────────────────────────────────────────
    function send(name, payload) {
        if (typeof hEvent === "function") {
            hEvent(name, payload || {});
        }
    }

    // ── Persistence (per-machine, survives relaunch) ──────────────────────
    function saveLocal() {
        try {
            localStorage.setItem(LS_VALUES, JSON.stringify(current));
            if (currentPreset) localStorage.setItem(LS_PRESET, currentPreset);
            else localStorage.removeItem(LS_PRESET);
        } catch (e) { /* storage may be unavailable */ }
    }

    function loadLocal() {
        try {
            const v = localStorage.getItem(LS_VALUES);
            const p = localStorage.getItem(LS_PRESET);
            return { values: v ? JSON.parse(v) : null, preset: p || null };
        } catch (e) {
            return { values: null, preset: null };
        }
    }

    // ── Rendering ─────────────────────────────────────────────────────────
    function valuesMatchPreset(preset) {
        return cfg.cvars.every((c) => {
            const want = preset.values[c.cvar];
            if (want === undefined) return true;
            return Number(current[c.cvar]) === Number(want);
        });
    }

    function renderPresets() {
        const grid = document.getElementById("preset-grid");
        grid.innerHTML = "";
        const order = cfg.presetOrder && cfg.presetOrder.length
            ? cfg.presetOrder
            : cfg.presets.map((p) => p.id);

        order.forEach((id) => {
            const preset = cfg.presets.find((p) => p.id === id);
            if (!preset) return;
            const selected = currentPreset === preset.id ||
                (!currentPreset && valuesMatchPreset(preset));
            const el = document.createElement("button");
            el.className = "preset" + (selected ? " selected" : "");
            el.innerHTML = `
                <div class="preset-icon">${lucideSvg(preset.icon || "settings")}</div>
                <div class="preset-text">
                    <div class="preset-name">
                        ${preset.label}
                        ${selected ? '<span class="badge">Active</span>' : ""}
                    </div>
                    <div class="preset-desc">${preset.desc || ""}</div>
                </div>`;
            el.addEventListener("click", () => applyPreset(preset.id));
            grid.appendChild(el);
        });
    }

    function renderAdvanced() {
        const list = document.getElementById("advanced-list");
        list.innerHTML = "";
        cfg.cvars.forEach((c) => {
            const row = document.createElement("div");
            row.className = "setting";
            row.innerHTML = `
                <div class="setting-info">
                    <div class="setting-name">${c.label}</div>
                    <div class="setting-desc">${c.desc || ""}</div>
                </div>
                <div class="setting-control"></div>`;
            row.querySelector(".setting-control").appendChild(buildControl(c));
            list.appendChild(row);
        });
    }

    function buildControl(c) {
        const val = current[c.cvar];

        if (c.type === "bool") {
            const btn = document.createElement("button");
            const on = Number(val) === 1;
            btn.className = "toggle" + (on ? " on" : "");
            btn.addEventListener("click", () => {
                const next = btn.classList.contains("on") ? 0 : 1;
                btn.classList.toggle("on", next === 1);
                setCvar(c.cvar, next);
            });
            return btn;
        }

        if (c.type === "enum") {
            const sel = document.createElement("select");
            sel.className = "select";
            (c.options || []).forEach((opt) => {
                const o = document.createElement("option");
                o.value = opt.value;
                o.textContent = opt.label;
                if (Number(opt.value) === Number(val)) o.selected = true;
                sel.appendChild(o);
            });
            sel.addEventListener("change", () => setCvar(c.cvar, Number(sel.value)));
            return sel;
        }

        // scalar
        const wrap = document.createElement("div");
        wrap.className = "slider-wrap";
        const slider = document.createElement("input");
        slider.type = "range";
        slider.className = "slider";
        slider.min = c.min;
        slider.max = c.max;
        slider.step = c.step;
        slider.value = val;
        const out = document.createElement("span");
        out.className = "slider-val";
        const fmt = (v) => (c.step < 1 ? Number(v).toFixed(1) : String(v));
        out.textContent = fmt(val);
        slider.addEventListener("input", () => { out.textContent = fmt(slider.value); });
        slider.addEventListener("change", () => setCvar(c.cvar, Number(slider.value)));
        wrap.appendChild(slider);
        wrap.appendChild(out);
        return wrap;
    }

    function flashStatus(text) {
        const el = document.getElementById("status");
        el.textContent = text;
        el.style.opacity = "1";
        clearTimeout(statusTimer);
        statusTimer = setTimeout(() => { el.style.opacity = "0"; }, 1800);
    }

    // ── Actions ───────────────────────────────────────────────────────────
    function applyPreset(id) {
        currentPreset = id;
        const preset = cfg.presets.find((p) => p.id === id);
        if (preset) {
            cfg.cvars.forEach((c) => {
                if (preset.values[c.cvar] !== undefined) {
                    current[c.cvar] = preset.values[c.cvar];
                }
            });
        }
        send("fpsApplyPreset", { id });
        renderPresets();
        renderAdvanced();
        saveLocal();
        flashStatus((preset ? preset.label : id) + " applied");
    }

    function setCvar(cvar, value) {
        current[cvar] = value;
        currentPreset = null;
        send("fpsSetCvar", { cvar, value });
        renderPresets();
        saveLocal();
        const c = cfg.cvars.find((x) => x.cvar === cvar);
        flashStatus((c ? c.label : cvar) + " updated");
    }

    // ── Open / close ──────────────────────────────────────────────────────
    function open(payload) {
        cfg = payload;
        current = Object.assign({}, payload.current || {});
        currentPreset = payload.currentPreset || null;

        // If Lua has no state yet, fall back to what we persisted locally.
        if (!Object.keys(current).length) {
            const saved = loadLocal();
            if (saved.values) current = saved.values;
            if (saved.preset) currentPreset = saved.preset;
        }
        // Fill any gaps with cvar defaults so controls always have a value.
        cfg.cvars.forEach((c) => {
            if (current[c.cvar] === undefined) current[c.cvar] = c.default;
        });

        document.getElementById("key-label").textContent = "/" + (payload.command || "fps");
        renderPresets();
        renderAdvanced();
        document.getElementById("root").classList.remove("hidden");
    }

    function close() {
        document.getElementById("root").classList.add("hidden");
    }

    // ── Wiring ────────────────────────────────────────────────────────────
    document.addEventListener("DOMContentLoaded", () => {
        paintStaticIcons();

        document.querySelectorAll(".tab").forEach((tab) => {
            tab.addEventListener("click", () => {
                document.querySelectorAll(".tab").forEach((t) => t.classList.remove("active"));
                document.querySelectorAll(".tab-body").forEach((b) => b.classList.remove("active"));
                tab.classList.add("active");
                document.getElementById("tab-" + tab.dataset.tab).classList.add("active");
            });
        });

        document.getElementById("close-btn").addEventListener("click", () => {
            send("fpsClose");
            close();
        });

        // Report persisted settings so Lua can re-apply them this session.
        const saved = loadLocal();
        send("fpsReady", { preset: saved.preset, values: saved.values });
    });

    window.addEventListener("keydown", (e) => {
        if (e.key === "Escape" && !document.getElementById("root").classList.contains("hidden")) {
            e.preventDefault();
            send("fpsClose");
            close();
        }
    });

    window.addEventListener("message", (event) => {
        const data = event.data || {};
        const args = data.args || [];
        switch (data.name) {
            case "open": return open(args[0] || {});
            case "close": return close();
            case "applied":
                if (args[0]) {
                    if (args[0].values) current = Object.assign(current, args[0].values);
                    currentPreset = args[0].preset || null;
                    saveLocal();
                    renderPresets();
                }
                return;
            default: return;
        }
    });
})();
