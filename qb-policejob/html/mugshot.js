/* qb-policejob mugshot viewfinder HUD — chrome around the UMG camera feed
   driven by client/mugshot.lua.
   Bridge:
     Lua -> JS : window 'message' { name, args:[payload] } — mugshot:open /
                 mugshot:close / mugshot:subject / mugshot:state
     JS -> Lua : hEvent('mugshot:op', { op, value }) (flat table: nested JS
                 objects don't survive hEvent JS->Lua)
   The WebUI holds input focus while the viewfinder is open, so buttons are
   clickable; keyboard shortcuts fire game-side in parallel. */
(function () {
    "use strict";

    var mugshotHud = document.getElementById("mugshotHud");
    if (!mugshotHud) return;

    var IS_PREVIEW = /[?&]preview\b/.test(location.search);
    if (IS_PREVIEW && typeof window.hEvent === "undefined") {
        window.hEvent = function (name, data) {
            console.log("[hEvent stub]", name, data);
            if (name === "mugshot:op" && window.__previewMugOp) window.__previewMugOp(data);
        };
    }

    function esc(v) {
        return String(v == null ? "" : v)
            .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
    }
    function svg(inner) {
        return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">' + inner + "</svg>";
    }

    var MUG = {
        open: false, zoom: 1, subject: null,
        lightAvailable: false, lightOn: true, lightIntensity: 10000, lightTemp: "neutral",
    };

    var MUG_ICO = {
        camera: svg('<path d="M4 8h3.2l1.8-2.6h6L16.8 8H20a1 1 0 011 1v9.4a1 1 0 01-1 1H4a1 1 0 01-1-1V9a1 1 0 011-1z"/><circle cx="12" cy="13" r="3.4"/>'),
        face: svg('<circle cx="12" cy="12" r="9"/><path d="M9 10h.01M15 10h.01M9 15.2c.9.8 1.9 1.2 3 1.2s2.1-.4 3-1.2"/>'),
        neutral: svg('<circle cx="12" cy="12" r="9"/><path d="M9 10h.01M15 10h.01M9 15.4h6"/>'),
        nohat: svg('<path d="M5 14c0-4 3.1-7 7-7s7 3 7 7"/><path d="M3 14h18M8 19l8-8"/>'),
        light: svg('<circle cx="12" cy="12" r="4.2"/><path d="M12 3v2.4M12 18.6V21M3 12h2.4M18.6 12H21M5.6 5.6l1.7 1.7M16.7 16.7l1.7 1.7M18.4 5.6l-1.7 1.7M7.3 16.7l-1.7 1.7"/>'),
        frame: svg('<path d="M4 8V5a1 1 0 011-1h3M16 4h3a1 1 0 011 1v3M20 16v3a1 1 0 01-1 1h-3M8 20H5a1 1 0 01-1-1v-3"/><circle cx="12" cy="12" r="3.4"/>'),
    };

    // Button op -> Lua (client/mugshot.lua control())
    function mugOp(op, value) {
        hEvent("mugshot:op", { op: op, value: value || "" });
    }

    // Real LIGHTING readout derived from the studio light state
    function mugLightQuality() {
        if (!MUG.lightAvailable) return { label: "GOOD", cls: "", fill: 6 }; // no light rig: cosmetic
        if (!MUG.lightOn) return { label: "DARK", cls: "bad", fill: 1 };
        var i = MUG.lightIntensity;
        var fill = Math.max(1, Math.min(6, Math.round((i / 30000) * 6)));
        if (i < 7000) return { label: "LOW", cls: "warn", fill: fill };
        if (i > 19000) return { label: "HARSH", cls: "warn", fill: fill };
        return { label: "GOOD", cls: "", fill: fill };
    }

    function mugZoomLabel() { return parseFloat(MUG.zoom.toFixed(2)) + "x"; }

    function renderMugshotHud() {
        if (!MUG.open) { mugshotHud.classList.add("hidden"); return; }
        var s = MUG.subject;
        var locked = !!s;
        var ins = [
            [MUG_ICO.face, "Have the subject face forward"],
            [MUG_ICO.neutral, "Keep a neutral expression"],
            [MUG_ICO.nohat, "Remove hats, glasses, masks"],
            [MUG_ICO.light, "Ensure even lighting on face"],
            [MUG_ICO.frame, "Center head within the frame"],
        ].map(function (it) { return '<div class="mugIns">' + it[0] + "<span>" + it[1] + "</span></div>"; }).join("");
        var row = function (k, v) {
            return '<div class="mugRow"><span class="k">' + k + '</span><span class="v ' + (v ? "" : "none") + '">' + (v ? esc(v) : "—") + "</span></div>";
        };
        var meter = function (k, m) {
            var bars = "";
            for (var i = 0; i < 6; i++) bars += '<i class="' + (i < m.fill ? "on" : "") + '"></i>';
            return '<div class="mugQ"><span class="k">' + k + '</span><span class="v ' + m.cls + '">' + m.label + "</span></div>" +
                '<div class="mugBar ' + m.cls + '">' + bars + "</div>";
        };
        var lightQ = mugLightQuality();
        var posQ = locked ? { label: "GOOD", cls: "", fill: 6 } : { label: "NO SUBJECT", cls: "bad", fill: 1 };
        var btn = function (op, label, value) {
            return '<button class="mugMini" data-mop="' + op + '"' + (value ? ' data-mval="' + value + '"' : "") + ">" + label + "</button>";
        };
        var temp = function (t, label) {
            return '<button class="mugMini temp ' + (MUG.lightTemp === t ? "on" : "") + '" data-mop="lightTemp" data-mval="' + t + '">' + label + "</button>";
        };

        var gauge = "";
        for (var g = 0; g < 10; g++) gauge += '<i class="' + (MUG.lightOn && g < Math.round(MUG.lightIntensity / 3000) ? "on" : "") + '"></i>';
        var lighting = MUG.lightAvailable
            ? '<div class="mugSec">LIGHTING <button class="mugMini pwr ' + (MUG.lightOn ? "on" : "") + '" data-mop="lightToggle">' + (MUG.lightOn ? "ON" : "OFF") + "</button></div>" +
              '<div class="mugCtlRow">' + btn("lightDown", "&minus;") + '<div class="mugGauge">' + gauge + "</div>" + btn("lightUp", "+") + "</div>" +
              '<div class="mugCtlRow">' + temp("cool", "COOL") + temp("neutral", "NEUTRAL") + temp("warm", "WARM") + "</div>"
            : '<div class="mugSec">LIGHTING</div><div class="mugNote">Light rig unavailable on this station</div>';

        mugshotHud.innerHTML =
            '<div class="mugHole">' +
                '<span class="mugCr tl"></span><span class="mugCr tr"></span><span class="mugCr bl"></span><span class="mugCr br"></span>' +
                '<span class="mugTick l"></span><span class="mugTick r"></span>' +
                '<div class="mugHead"><h1>POSITION SUBJECT</h1><p>Ensure the face is centered and clearly visible</p></div>' +
                '<div class="mugCross"></div>' +
                '<div class="mugZoom">' + btn("zoomOut", "&minus;") + '<span class="zval">' + mugZoomLabel() + "</span>" + btn("zoomIn", "+") + "</div>" +
            "</div>" +
            '<div class="mugPanel left">' +
                '<div class="mugTitle">' + MUG_ICO.camera + "<span>MUGSHOT SYSTEM</span></div>" +
                '<div class="mugStatus ' + (locked ? "locked" : "") + '"><span class="dot"></span>' + (locked ? "SUBJECT IN FRAME" : "READY — AWAITING SUBJECT") + "</div>" +
                '<div class="mugSec">SUBJECT INFO</div>' +
                row("ID", s && s.citizenid) + row("NAME", s && s.name) + row("DOB", s && s.dob) +
                row("GENDER", s ? (Number(s.gender) === 1 ? "Female" : "Male") : null) +
                lighting +
                '<div class="mugSec">CAMERA</div>' +
                '<div class="mugCtlRow"><span class="clab">MOVE</span>' + btn("camLeft", "&#9664;") + btn("camRight", "&#9654;") + btn("camUp", "&#9650;") + btn("camDown", "&#9660;") + "</div>" +
                '<div class="mugCtlRow"><span class="clab">AIM</span>' + btn("camYawL", "&#10226;") + btn("camYawR", "&#10227;") + btn("camPitchU", "&#8963;") + btn("camPitchD", "&#8964;") + "</div>" +
                '<div class="mugCtlRow"><button class="mugMini wide" data-mop="camReset">RESET CAMERA</button></div>' +
            "</div>" +
            '<div class="mugPanel right">' +
                '<div class="mugSec" style="margin-top:0;padding-top:0;border-top:0">CAPTURE INSTRUCTIONS</div>' + ins +
                '<div class="mugSec">PHOTO QUALITY</div>' +
                meter("LIGHTING", lightQ) +
                meter("FOCUS", { label: "GOOD", cls: "", fill: 6 }) +
                meter("POSITION", posQ) +
            "</div>" +
            '<button class="mugCancel" data-mop="cancel"><kbd>&#9003;</kbd> CANCEL</button>' +
            '<div class="mugCtl">' +
                '<button class="mugBtn" data-mop="zoomReset"><kbd>R</kbd> RESET ZOOM</button>' +
                '<button class="mugShutter" data-mop="capture">' + MUG_ICO.camera + "</button>" +
                '<button class="mugBtn" data-mop="capture"><kbd>E</kbd> TAKE PHOTO</button>' +
            "</div>" +
            '<div class="mugHint"><b>Press [E]</b> or click the shutter to capture<br>' +
                (locked
                    ? "Photo saves to the record of <b>" + esc(s.name || s.citizenid) + "</b>"
                    : '<span class="warn">No subject in frame</span> — you\'ll be asked for a Citizen ID after capture') +
            "</div>";
        mugshotHud.classList.remove("hidden");
    }

    mugshotHud.addEventListener("click", function (e) {
        var el = e.target.closest("[data-mop]");
        if (!el) return;
        mugOp(el.dataset.mop, el.dataset.mval);
    });

    window.addEventListener("keydown", function (e) {
        // The WebUI holds focus while the viewfinder is open, so Esc lands here.
        if (e.key === "Escape" && MUG.open) mugOp("cancel");
    });

    window.addEventListener("message", function (event) {
        var data = event.data || {};
        var payload = (Array.isArray(data.args) && data.args[0]) || {};
        switch (data.name) {
            case "mugshot:open":
                MUG.open = true; MUG.zoom = 1; MUG.subject = null;
                renderMugshotHud();
                break;
            case "mugshot:close":
                MUG.open = false;
                renderMugshotHud();
                break;
            case "mugshot:subject":
                MUG.subject = payload.subject || null;
                if (MUG.open) renderMugshotHud();
                break;
            case "mugshot:state":
                MUG.zoom = Number(payload.zoom) || 1;
                MUG.lightAvailable = !!payload.lightAvailable;
                MUG.lightOn = !!payload.lightOn;
                MUG.lightIntensity = Number(payload.lightIntensity) || 10000;
                MUG.lightTemp = payload.lightTemp || "neutral";
                if (MUG.open) renderMugshotHud();
                break;
        }
    });

    // Browser preview harness: ?preview&mugshot — buttons run against a
    // simulated Lua state machine. S toggles the subject, Backspace closes.
    if (IS_PREVIEW && /[?&]mugshot\b/.test(location.search)) {
        var demoSubject = { citizenid: "CIT88012", name: "Marcus Delgado", dob: "1989-03-14", gender: 0 };
        document.body.style.background = "#3a3f46"; // stand-in for the game feed
        var sim = { zoom: 1, lightAvailable: true, lightOn: true, lightIntensity: 10000, lightTemp: "neutral" };
        var pushSim = function () {
            window.postMessage({ name: "mugshot:state", args: [{ zoom: sim.zoom, lightAvailable: sim.lightAvailable, lightOn: sim.lightOn, lightIntensity: sim.lightIntensity, lightTemp: sim.lightTemp }] }, "*");
        };
        window.__previewMugOp = function (data) {
            var op = data.op, value = data.value;
            if (op === "cancel") { window.postMessage({ name: "mugshot:close", args: [{}] }, "*"); return; }
            if (op === "capture") { console.log("[preview] capture!"); return; }
            if (op === "zoomIn") sim.zoom = Math.min(2.5, sim.zoom + 0.25);
            if (op === "zoomOut") sim.zoom = Math.max(1, sim.zoom - 0.25);
            if (op === "zoomReset") sim.zoom = 1;
            if (op === "lightToggle") sim.lightOn = !sim.lightOn;
            if (op === "lightUp") sim.lightIntensity = Math.min(30000, sim.lightIntensity + 3000);
            if (op === "lightDown") sim.lightIntensity = Math.max(1000, sim.lightIntensity - 3000);
            if (op === "lightTemp") sim.lightTemp = value;
            pushSim();
        };
        setTimeout(function () {
            window.postMessage({ name: "mugshot:open", args: [{ stationIndex: 1 }] }, "*");
            pushSim();
            setTimeout(function () {
                window.postMessage({ name: "mugshot:subject", args: [{ ok: true, subject: demoSubject }] }, "*");
            }, 2500);
        }, 200);
        window.addEventListener("keydown", function (e) {
            if (!MUG.open) return;
            if (e.key === "ArrowUp") mugOp("zoomIn");
            if (e.key === "ArrowDown") mugOp("zoomOut");
            if (e.key.toLowerCase() === "r") mugOp("zoomReset");
            if (e.key.toLowerCase() === "s") window.postMessage({ name: "mugshot:subject", args: [MUG.subject ? { ok: true } : { ok: true, subject: demoSubject }] }, "*");
            if (e.key === "Backspace") mugOp("cancel");
        });
    }
})();
