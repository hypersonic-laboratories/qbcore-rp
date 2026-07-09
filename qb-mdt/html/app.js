/* qb-mdt frontend — NIGHTWATCH terminal. Vanilla JS, wired to the Lua RPC
   bridge (single mdt:request channel). */
"use strict";

// Browser preview harness is opt-in via ?preview in the URL. In game the WebUI
// loads index.html WITHOUT that param, so this never runs — the auto-open harness
// and hEvent stub only exist for out-of-game QA. hEvent itself is injected by the
// HELIX WebUI runtime and is called bare at runtime (resolved when the user acts).
const IS_PREVIEW = /[?&]preview\b/.test(location.search);
if (IS_PREVIEW && typeof window.hEvent === "undefined") {
    window.hEvent = (name, data) => {
        console.log("[hEvent stub]", name, data);
        if (name === "mdt:request") window.__previewRpc(data);
    };
}

// ─────────────────────────── bridge ─────────────────────────────────────────

let reqCounter = 0;
const pending = {};

function rpc(action, payload) {
    return new Promise((resolve) => {
        const reqId = ++reqCounter;
        pending[reqId] = resolve;
        // Payload is JSON-stringified: HELIX hEvent does not reliably deliver a
        // NESTED JS object to the Lua handler, but a flat string always survives.
        // The server JSON.parses it back. (Lua->JS nesting via SendEvent is fine.)
        hEvent("mdt:request", { action, payload: JSON.stringify(payload || {}), reqId });
    });
}

// ─────────────────────────── state ──────────────────────────────────────────

const S = {
    open: false,
    booted: false,          // boot+login only on first open per session
    role: "police",
    officer: null,
    penal: [],              // categories [{category, charges:[{code,label,class,fine,sentence}]}]
    priorities: {},
    statuses: [],
    bulletins: [],
    units: [],
    calls: [],
    screen: "boot",
    // search
    searchQ: "", searchRes: null,
    // citizen
    citizen: null, citizenTab: "conv", citizenLoading: false,
    // vehicle
    plateQ: "", vehicle: null, vehicleMiss: null, recents: [],
    // dispatch
    callId: null, dspTab: "active",
    // reports
    reports: [], report: null, reportTab: "inv", chargeQ: "", citQ: "", citQRes: [],
    // bolos
    bolos: [],
    // warrants (dash stat)
    warrants: [],
    // ems
    medical: [],
    // ui
    modal: null, toast: null, panic: null, dutyPick: "available",
    unitBoard: [],          // [{id, channel, occupants:[{citizenid,name}]}]
    myUnit: null,           // unit currently connected to (callsign + radio)
};

const $ = (sel) => document.querySelector(sel);
const stage = $("#stage");
const tablet = $("#tablet");

// HELIX serializes an EMPTY Lua table as JSON {} (object), not []. Coerce any
// server "list" back to a real array before .map/.filter/.length touch it.
function toArr(v) {
    if (Array.isArray(v)) return v;
    if (v && typeof v === "object") return Object.values(v);
    return [];
}

function esc(v) {
    return String(v == null ? "" : v)
        .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}
const initials = (name) => String(name || "?").trim().split(/\s+/).map(w => w[0]).join("").slice(0, 3).toUpperCase() || "?";
const money = (n) => "$" + Number(n || 0).toLocaleString("en-US");
const months = (m) => { m = Number(m || 0); return m >= 12 ? Math.floor(m / 12) + "Y " + (m % 12) + "M" : m + " MO"; };
const clock = () => new Date().toLocaleTimeString("en-GB");
const dateStr = () => new Date().toLocaleDateString("en-US", { month: "2-digit", day: "2-digit", year: "numeric" });
const fmtTs = (ts) => esc(String(ts || "").replace("T", " ").slice(0, 16));
const priPill = (p) => (Number(p) === 1 ? "pbad" : Number(p) === 2 ? "pwarn" : "pinfo");
const priDot = (p) => "d" + Math.min(3, Math.max(1, Number(p) || 3));

function flatPenal() {
    const out = [];
    for (const cat of toArr(S.penal)) for (const c of toArr(cat.charges)) out.push(c);
    return out;
}
const chargeByCode = (code) => flatPenal().find(c => c.code === code);

// ─────────────────────────── scaling ────────────────────────────────────────

function rescale() {
    const scr = $("#tablet .screen");
    if (!scr) return;
    stage.style.setProperty("--s", (scr.clientWidth / 1452).toFixed(5));
}
window.addEventListener("resize", rescale);

// ─────────────────────────── toast / modal / panic ──────────────────────────

let toastTimer = null;
function toast(msg) {
    S.toast = msg;
    renderToastHost();
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { S.toast = null; renderToastHost(); }, 2800);
}

let panicTimer = null;
function showPanic(p) {
    S.panic = p;
    renderPanicHost();
    clearTimeout(panicTimer);
    panicTimer = setTimeout(() => { S.panic = null; renderPanicHost(); }, 9000);
}

function openModal(kind, data) { S.modal = { kind, data: data || {} }; renderModalHost(); }
function closeModal() { S.modal = null; render(); }

// ─────────────────────────── navigation ─────────────────────────────────────

// ─────────────────────────── icons ──────────────────────────────────────────
// Inline SVG set (feather-style, stroke = currentColor) so icons inherit
// text color from .navi / .av / .mug without extra assets.
const svg = (inner) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">${inner}</svg>`;
const ICO = {
    shield: svg('<path d="M12 2l8 3.5V11c0 5.2-3.4 8.9-8 10.5C7.4 19.9 4 16.2 4 11V5.5z"/>'),
    dash: svg('<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>'),
    dispatch: svg('<circle cx="12" cy="12" r="1.6" fill="currentColor" stroke="none"/><path d="M8.5 15.5a5 5 0 010-7M15.5 8.5a5 5 0 010 7M5.6 18.4a9 9 0 010-12.8M18.4 5.6a9 9 0 010 12.8"/>'),
    citizen: svg('<circle cx="12" cy="8" r="4"/><path d="M4 21c.9-3.9 4.1-6 8-6s7.1 2.1 8 6"/>'),
    vehicle: svg('<path d="M4 16v-3l1.7-4.5A2 2 0 017.6 7h8.8a2 2 0 011.9 1.5L20 13v3"/><path d="M4 16h16v3a1 1 0 01-1 1h-2a1 1 0 01-1-1v-1H8v1a1 1 0 01-1 1H5a1 1 0 01-1-1z"/><path d="M7 13h.01M17 13h.01"/>'),
    reports: svg('<path d="M14 2H7a2 2 0 00-2 2v16a2 2 0 002 2h10a2 2 0 002-2V7z"/><path d="M14 2v5h5M9 13h6M9 17h6"/>'),
    bolo: svg('<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>'),
    person: svg('<circle cx="12" cy="7.4" r="4.4" fill="currentColor" stroke="none"/><path d="M3.6 21.5c.8-4.7 4.3-7.1 8.4-7.1s7.6 2.4 8.4 7.1z" fill="currentColor" stroke="none"/>'),
};

function navDef() {
    return S.role === "police"
        ? [["dash", "DASHBOARD"], ["dispatch", "DISPATCH"], ["citizen", "CITIZENS"], ["vehicle", "VEHICLES"], ["reports", "REPORTS"], ["bolo", "BOLO BOARD"]]
        : [["dash", "DASHBOARD"], ["dispatch", "DISPATCH"], ["citizen", "PATIENTS"], ["bolo", "ADVISORIES"]];
}

function go(screen) {
    S.screen = screen;
    S.searchQ = ""; S.searchRes = null;
    render();
    if (screen === "dash") loadDashboard();
    if (screen === "dispatch") loadCalls();
    if (screen === "bolo") loadBolos();
    if (screen === "reports") loadReports();
}

// ─────────────────────────── data loads ─────────────────────────────────────

async function loadDashboard() {
    const [calls, bolos, warrants] = await Promise.all([
        rpc("getCalls"), rpc("getBolos"), S.role === "police" ? rpc("getWarrants") : Promise.resolve(null),
    ]);
    if (calls && calls.ok) { S.calls = toArr(calls.calls); S.units = toArr(calls.units); }
    if (bolos && bolos.ok) S.bolos = toArr(bolos.bolos);
    if (warrants && warrants.ok) S.warrants = toArr(warrants.warrants);
    if (S.screen === "dash") bgRender();
}

// Merge one updated call into local state (from an RPC response or the
// mdt:callUpdated push) — no round-trip needed to reflect attach/detach.
function applyCallUpdate(call) {
    if (!call || !call.id) return;
    call.units = toArr(call.units);
    const i = S.calls.findIndex(c => Number(c.id) === Number(call.id));
    if (i >= 0) S.calls[i] = call; else S.calls.unshift(call);
    S.calls = S.calls.filter(c => c.status !== "closed");
}

async function loadCalls() {
    const r = await rpc("getCalls");
    if (r && r.ok) { S.calls = toArr(r.calls); S.units = toArr(r.units); }
    if (!S.callId && S.calls.length) S.callId = S.calls[0].id;
    if (S.screen === "dispatch") bgRender();
}

async function loadBolos() {
    const r = await rpc("getBolos");
    if (r && r.ok) S.bolos = toArr(r.bolos);
    if (S.screen === "bolo") bgRender();
}

async function loadReports() {
    const r = await rpc("getIncidents", { page: 1 });
    if (r && r.ok) S.reports = toArr(r.incidents);
    if (S.screen === "reports") bgRender();
}

async function openCitizen(citizenid) {
    S.screen = "citizen"; S.citizenLoading = true; S.searchQ = ""; S.searchRes = null; S.citizenTab = "conv";
    render();
    const r = await rpc("getProfile", { citizenid });
    S.citizenLoading = false;
    if (r && r.ok) {
        S.citizen = r.profile;
        // Empty Lua tables arrive as {} — coerce every list on the profile.
        S.citizen.vehicles = toArr(S.citizen.vehicles);
        S.citizen.convictions = toArr(S.citizen.convictions);
        S.citizen.incidents = toArr(S.citizen.incidents);
        S.citizen.warrants = toArr(S.citizen.warrants);
        S.citizen.flags = toArr(S.citizen.flags);
        if (S.role === "ems") {
            const m = await rpc("getMedicalRecords", { citizenid });
            S.medical = toArr((m && m.ok && m.records) || S.citizen.medical);
        }
    } else {
        S.citizen = null;
        toast(r && r.message ? r.message : "Citizen not found");
    }
    if (S.screen === "citizen") render();
}

async function runPlate(plate) {
    plate = String(plate || "").trim().toUpperCase();
    if (!plate) return;
    S.screen = "vehicle"; S.plateQ = plate; S.vehicle = null; S.vehicleMiss = null;
    render();
    const r = await rpc("getVehicle", { plate });
    if (r && r.ok) {
        r.bolos = toArr(r.bolos);
        S.vehicle = r;
        if (!S.recents.includes(plate)) S.recents = [plate, ...S.recents].slice(0, 5);
    } else {
        S.vehicleMiss = plate;
    }
    if (S.screen === "vehicle") render();
}

async function openReport(id) {
    S.screen = "reports"; S.reportTab = "inv"; S.chargeQ = ""; S.citQ = ""; S.citQRes = [];
    if (!id) {
        S.report = { id: null, title: "", details: "", people: [], vehicles: [], evidence: [], charges: [] };
        render();
        return;
    }
    render();
    const r = await rpc("getIncident", { id });
    if (r && r.ok) {
        const inc = r.incident;
        const links = toArr(inc.links);
        S.report = {
            id: Number(inc.id), title: inc.title || "", details: inc.details || "",
            author: inc.author_name, created: inc.created,
            people: links.filter(l => l.link_type === "citizen").map(l => ({ id: l.identifier, label: l.label || l.identifier })),
            vehicles: links.filter(l => l.link_type === "vehicle").map(l => ({ id: l.identifier, label: l.label || "" })),
            evidence: links.filter(l => l.link_type === "evidence").map(l => ({ id: l.identifier, label: l.label || "" })),
            charges: [], convictions: toArr(inc.convictions),
        };
    }
    render();
}

async function saveReport(silent) {
    const rep = S.report;
    if (!rep) return;
    if (!rep.title.trim()) { toast("Report title required"); return; }
    const links = [
        ...rep.people.map(p => ({ link_type: "citizen", identifier: p.id, label: p.label })),
        ...rep.vehicles.map(v => ({ link_type: "vehicle", identifier: v.id, label: v.label })),
        ...rep.evidence.map(e => ({ link_type: "evidence", identifier: e.id, label: e.label })),
    ];
    const r = await rpc("saveIncident", { id: rep.id, title: rep.title, details: rep.details, links });
    if (r && r.ok) {
        rep.id = Number(r.id);
        if (!silent) toast("Report saved — RPT-" + rep.id);
        loadReports();
    } else {
        toast(r && r.message ? r.message : "Save failed");
    }
}

// ─────────────────────────── boot / login ───────────────────────────────────

const BOOT_LINES = [
    "NIGHTWATCH TERMINAL v4.2 — SECURE BOOT",
    "BIOS CHECK ................................. <span class='bok'>OK</span>",
    "CJIS UPLINK — NODE CC-EAST-04 .............. <span class='bok'>SECURE</span>",
    "RECORDS MIRROR ............................. <span class='bsync'>SYNCED</span>",
    "DISPATCH CHANNEL 1 ......................... <span class='bok'>LIVE</span>",
    "EVIDENCE LOCKER INDEX ...................... <span class='bok'>MOUNTED</span>",
    "BIOMETRIC SESSION KEY ...................... <span class='bok'>ISSUED</span>",
    "LOADING OPERATOR PROFILE ...",
];

function renderBoot() {
    const lines = BOOT_LINES.map((l, i) => `<div class="bl mono" style="animation-delay:${(i * 0.28).toFixed(2)}s">${l}</div>`).join("");
    return `<div class="boot mono" data-act="skipBoot">${lines}<span class="cur" style="margin-left:2px"></span></div>`;
}

function renderLogin() {
    const o = S.officer || {};
    const brandName = S.role === "police" ? "Pacifica PD" : "Pacifica EMS";
    const duty = (st) => `<button class="dbtn ${S.dutyPick === st ? "on" : ""}" data-act="dutyPick" data-arg="${st}">${st === "available" ? "10-8 · GO ON DUTY" : "10-7 · STANDBY"}</button>`;
    return `<div class="login stag">
        <div class="crest">${ICO.shield}</div>
        <div class="tc"><div class="disp fs22 fw7">${brandName}</div><div class="mono fs11 dim2 mt8">NIGHTWATCH v4.2</div></div>
        <div class="tc"><div class="disp fs22 fw7">${esc(o.name)}</div><div class="mono fs13 dim mt8">${esc(o.callsign)} · ${esc(o.grade)} · ${esc(o.job)}</div></div>
        <div style="width:420px">
            <div class="fx gap12">${duty("available")}${duty("unavailable")}</div>
            <button class="btnp btn w100 mt16" style="padding:13px" data-act="doLogin">AUTHENTICATE — ENTER TERMINAL</button>
        </div>
    </div>`;
}

// ─────────────────────────── shell chrome ───────────────────────────────────

function renderSidebar() {
    const brand = S.role === "police" ? "PPD" : "EMS";
    const brandName = S.role === "police" ? "Pacifica PD" : "Pacifica EMS";
    const nav = navDef().map(([key, label]) =>
        `<div class="navi ${S.screen === key ? "on" : ""}" data-act="nav" data-arg="${key}"><span class="nico">${ICO[key] || ICO.dash}</span><span class="disp fs15 fw6">${label}</span></div>`
    ).join("");
    return `<div class="side">
        <div class="fx ac gap12"><div class="logo">${ICO.shield}</div><div><div class="disp fs16 fw7" style="line-height:1.2">${brandName}</div><div class="mono fs11 dim2">NIGHTWATCH v4.2</div></div></div>
        <nav class="col f1" style="gap:4px">${nav}</nav>
        <div class="mono fs11 dim2" style="line-height:1.9">CJIS LINK · <span class="bok">SECURE</span><br>NODE CC-EAST-04<br>${dateStr()}</div>
    </div>`;
}

function renderSearchDrop() {
    if (!S.searchRes) return "";
    const { citizens = [], vehicles = [] } = S.searchRes;
    if (!citizens.length && !vehicles.length) {
        return `<div class="sdrop panel"><div class="pad16 dim fs14 tc">No records match "${esc(S.searchQ)}"</div></div>`;
    }
    let html = "";
    if (citizens.length) {
        html += `<div class="sgl">CITIZENS</div>` + citizens.map(c =>
            `<div class="srow" data-act="openCitizen" data-arg="${esc(c.citizenid)}"><div class="av">${initials(c.name)}</div><div class="f1"><div class="fw6 fs14">${esc(c.name)}</div><div class="fs12 dim mono">${esc(c.citizenid)} · DOB ${esc(c.dob)}</div></div><span class="pill pinfo">CITIZEN</span></div>`
        ).join("");
    }
    if (vehicles.length) {
        html += `<div class="sgl">VEHICLES</div>` + vehicles.map(v =>
            `<div class="srow" data-act="runPlate" data-arg="${esc(v.plate)}"><div class="av">${ICO.vehicle}</div><div class="f1"><div class="fw6 fs14 mono">${esc(v.plate)}</div><div class="fs12 dim">${esc(v.model)}</div></div><span class="pill pinfo">VEHICLE</span></div>`
        ).join("");
    }
    return `<div class="sdrop panel">${html}</div>`;
}

function renderTopbar() {
    const o = S.officer || {};
    return `<div class="topbar">
        <div class="posrel f1" style="max-width:520px">
            <input id="gsearch" class="inp w100 mono" style="font-size:14px" placeholder="SEARCH — citizens, plates…" value="${esc(S.searchQ)}" data-model="searchQ" autocomplete="off">
            ${renderSearchDrop()}
        </div>
        <div class="fx ac gap12">
            <span class="pill ${S.myUnit ? "pacc" : "pmut"} mono pointer" data-act="modalUnit" title="Click to switch unit / radio">${S.myUnit ? esc(S.myUnit) : "NO UNIT"}</span>
            <span class="pill ${S.dutyPick === "available" ? "pok" : "pwarn"} mono pointer" data-act="cycleStatus" title="Click to cycle status">${esc(S.dutyPick).toUpperCase()}</span>
            <span class="fs14 dim">${esc(o.name)}</span>
            <span id="clock" class="mono fs16 accent">${clock()}</span>
            <button class="btnd bsm btn" data-act="panic">▲ PANIC</button>
        </div>
    </div>`;
}

// ─────────────────────────── screens ────────────────────────────────────────

function callRow(c, opts) {
    const sel = opts && opts.sel;
    return `<div class="row fx ac gap12 pointer ${sel ? "selrow" : ""}" data-act="openCall" data-arg="${c.id}">
        <span class="dot ${priDot(c.priority)}"></span><span class="mono fs12 dim">C-${esc(c.id)}</span>
        <div class="f1"><div class="fw6 fs15">${esc(c.code || "CALL")} — ${esc(c.title)}</div><div class="fs13 dim">${esc((c.details || "").slice(0, 60))}</div></div>
        <span class="pill ${priPill(c.priority)}">PRI ${esc(c.priority)}</span>
        <span class="mono fs12 dim">${fmtTs(c.created).slice(11)}</span>
    </div>`;
}

function unitRow(u) {
    const cls = u.status === "available" ? "pok" : (u.status === "enroute" || u.status === "onscene") ? "pinfo" : "pwarn";
    return `<div class="row fx ac gap12"><span class="mono fs14 accent" style="width:96px">${esc(u.callsign)}</span><span class="f1 fs14">${esc(u.name)}</span><span class="pill ${cls}">${esc(u.status).toUpperCase()}</span></div>`;
}

// Radio slot row (dashboard). Occupants derive live from S.units by callsign,
// so unitsUpdated pushes keep counts fresh without an extra RPC.
function radioRow(u) {
    const occ = S.units.filter(x => x.callsign === u.id);
    const mine = S.myUnit === u.id;
    return `<div class="row fx ac gap12 ${mine ? "selrow" : ""}">
        <div class="f1">
            <div class="fx ac gap8"><span class="disp fw7 fs14">${esc(u.id)}</span><span class="mono fs11 dim2">${esc(u.freq || "")} MHz</span></div>
            <div class="fs12 ${occ.length ? "dim" : "dim2"} mt-2">${occ.length ? `${occ.length} connected — ${occ.map(x => esc(x.name)).join(", ")}` : "0 connected"}</div>
        </div>
        ${mine
            ? `<button class="btnd btn bsm" data-act="leaveUnit">LEAVE</button>`
            : `<button class="btnp btn bsm" data-act="joinUnit" data-arg="${esc(u.id)}">CONNECT</button>`}
    </div>`;
}

function renderDash() {
    const live = S.calls.filter(c => c.status !== "closed");
    const stats = S.role === "police"
        ? [["ACTIVE CALLS", live.length], ["UNITS ON DUTY", S.units.length], ["ACTIVE BOLOS", S.bolos.length], ["ACTIVE WARRANTS", S.warrants.length]]
        : [["ACTIVE CALLS", live.length], ["UNITS ON DUTY", S.units.length], ["ADVISORIES", S.bolos.length], ["BULLETINS", S.bulletins.length]];
    const bulls = S.bulletins.length
        ? S.bulletins.map(b => `<div class="row"><div class="fx ac jb"><div class="fw6 fs15">${esc(b.title)}</div>${(S.officer && (S.officer.supervisor || b.author_cid === S.officer.citizenid)) ? `<button class="xbtn" data-act="delBulletin" data-arg="${b.id}">×</button>` : ""}</div><div class="fs14 dim mt8" style="line-height:1.55">${esc(b.content)}</div><div class="mono fs12 dim2 mt8">${esc(b.author_name)} · ${fmtTs(b.created)}</div></div>`).join("")
        : `<div class="empty" style="margin:16px">No bulletins posted</div>`;
    return `<div class="scr">
        <div class="fx ac jb"><div><h1>Dashboard</h1><div class="mono fs12 dim mt8">${S.role === "police" ? "SHIFT BRAVO" : "CALDERA EMS"} · ${dateStr()} · ALL SYSTEMS NOMINAL</div></div></div>
        <div class="dashgrid">
            <section class="panel col ohide"><header class="ph"><span class="disp fs16 fw7">Active Calls</span><span class="pill pbad">${live.length} LIVE</span></header>
                <div class="col stag oauto f1">${live.length ? live.map(c => callRow(c)).join("") : `<div class="empty" style="margin:16px">No active calls — sector quiet</div>`}</div></section>
            <div class="col gap16 ohide">
                <div class="statgrid">${stats.map(s => `<div class="panel stat"><div class="mono fs12 dim upper">${s[0]}</div><div class="statv disp">${s[1]}</div></div>`).join("")}</div>
                <section class="panel col ohide f1"><header class="ph"><span class="disp fs16 fw7">Bulletins</span><button class="btn bsm" data-act="modalBulletin">+ POST</button></header><div class="col stag oauto">${bulls}</div></section>
            </div>
            <div class="col gap16 ohide">
                <section class="panel col ohide" style="flex:1.2"><header class="ph"><span class="disp fs16 fw7">Radios</span><span class="pill ${S.myUnit ? "pacc" : "pmut"} mono">${S.myUnit || "NO UNIT"}</span></header>
                    <div class="col stag oauto f1">${S.unitBoard.length ? S.unitBoard.map(radioRow).join("") : `<div class="empty" style="margin:16px">No unit slots configured</div>`}</div></section>
                <section class="panel col ohide f1"><header class="ph"><span class="disp fs16 fw7">Units On Duty</span><span class="pill pok">${S.units.length}</span></header>
                    <div class="col stag oauto f1">${S.units.length ? S.units.map(unitRow).join("") : `<div class="empty" style="margin:16px">No units registered</div>`}</div></section>
            </div>
        </div>
    </div>`;
}

function renderDispatch() {
    const live = S.calls.filter(c => c.status !== "closed");
    const call = live.find(c => String(c.id) === String(S.callId)) || live[0];
    const my = S.officer ? String(S.officer.citizenid) : "";
    let detail = `<div class="empty f1">No call selected</div>`;
    if (call) {
        const callUnits = toArr(call.units);
        const units = callUnits.map(u => `<span class="pill pacc mono">${esc(u.callsign)}</span>`).join(" ");
        const attached = callUnits.some(u => u.citizenid === my);
        const coords = call.coords ? `<button class="btn bsm" data-act="waypoint" data-arg="${call.id}">SET WAYPOINT</button>` : "";
        detail = `<section class="col gap16 ohide"><div class="panel">
            <div class="ph"><div class="fx ac gap12"><span class="dot ${priDot(call.priority)}"></span><span class="disp fs18 fw7">${esc(call.code || "CALL")} — ${esc(call.title)}</span></div><span class="pill ${priPill(call.priority)}">PRIORITY ${esc(call.priority)}</span></div>
            <div class="pad20">
                <div class="infr"><span class="dim">RECEIVED</span><span class="mono">${fmtTs(call.created)} · C-${esc(call.id)}</span></div>
                <div class="infr"><span class="dim">STATUS</span><span class="pill ${call.status === "active" ? "pinfo" : "pwarn"}">${esc(call.status).toUpperCase()}</span></div>
                <p class="fs15 dim m0 mt12" style="line-height:1.65">${esc(call.details || "No further details provided.")}</p>
                <div class="disp fs13 fw7 dim mt16 mb8">Units Attached</div>
                <div class="fx gap8 wrap">${units || `<span class="fs14 dim2">No units attached — call is uncovered</span>`}</div>
                <div class="fx gap12 mt16 wrap">
                    ${attached
                        ? `<span class="pill pok" style="padding:10px 16px">✓ ATTACHED — EN ROUTE</span><button class="btn" data-act="detachCall" data-arg="${call.id}">DETACH</button>`
                        : `<button class="btnp btn" data-act="attachCall" data-arg="${call.id}">ATTACH SELF — ${esc(S.officer ? S.officer.callsign : "")}</button>`}
                    ${coords}
                    <button class="btnd btn" data-act="closeCall" data-arg="${call.id}">CLOSE CALL</button>
                </div>
            </div></div>
            <div class="mapph"><div class="cross"></div><div class="tc" style="z-index:2"><div class="disp fs16 fw6 dim">MAP FEED</div><div class="mono fs12 dim2 mt8">${call.coords ? "GPS FIX AVAILABLE — USE SET WAYPOINT" : "NO GPS DATA ON THIS CALL"}</div></div></div>
        </section>`;
    }
    return `<div class="scr">
        <div class="fx ac jb"><div><h1>Dispatch</h1><div class="mono fs12 dim mt8">CHANNEL 1 PRIMARY · ${live.length} OPEN CALLS</div></div><button class="btnp btn bsm" data-act="modalCall">+ NEW CALL</button></div>
        <div class="dspgrid">
            <section class="panel col ohide"><header class="ph"><span class="disp fs16 fw7">Call Queue</span><span class="pill pbad">${live.length} LIVE</span></header>
                <div class="col stag oauto f1">${live.length ? live.map(c => callRow(c, { sel: call && String(c.id) === String(call.id) })).join("") : `<div class="empty" style="margin:16px">No open calls</div>`}</div></section>
            ${detail}
        </div>
    </div>`;
}

function licencePills(lic) {
    const keys = Object.keys(lic || {});
    if (!keys.length) return `<div class="fs14 dim2">No licence data</div>`;
    return keys.map(k => {
        const ok = !!lic[k];
        return `<div class="fx ac jb"><span class="fs14" style="text-transform:capitalize">${esc(k)} License</span><span class="pill ${ok ? "pok" : "pbad"}">${ok ? "VALID" : "REVOKED"}</span></div>`;
    }).join("");
}

function renderCitizen() {
    if (S.citizenLoading) {
        return `<div class="scr"><div class="fx ac jb"><h1>${S.role === "ems" ? "Patient" : "Citizen"} Record</h1></div>
        <div class="citgrid"><div class="panel pad20 col gap16"><div class="fx gap16"><div class="sk" style="width:110px;height:128px"></div><div class="col gap12 f1"><div class="sk" style="height:26px;width:80%"></div><div class="sk" style="height:15px;width:55%"></div><div class="sk" style="height:15px;width:65%"></div></div></div><div class="sk" style="height:15px"></div><div class="sk" style="height:15px;width:85%"></div><div class="sk" style="height:44px"></div></div>
        <div class="panel pad20 col gap14"><div class="fx gap12"><div class="sk" style="height:34px;width:130px"></div><div class="sk" style="height:34px;width:130px"></div></div><div class="sk" style="height:52px"></div><div class="sk" style="height:52px"></div><div class="sk" style="height:52px;width:90%"></div></div></div></div>`;
    }
    const c = S.citizen;
    if (!c) {
        return `<div class="scr"><div class="fx ac jb"><h1>${S.role === "ems" ? "Patients" : "Citizens"}</h1></div>
        <div class="empty f1"><div class="disp fs18 fw6" style="color:#8494ad">NO RECORD OPEN</div><div class="fs14 mt8">Use the global search above to pull a ${S.role === "ems" ? "patient" : "citizen"} record.</div></div></div>`;
    }
    const name = ((c.firstname || "") + " " + (c.lastname || "")).trim() || c.citizenid;
    const activeWarrant = (c.warrants || []).find(w => w.status === "active");
    const flags = (c.flags || []).map(f => `<span class="pill pbad">⚑ ${esc(f)}</span>`).join(" ");

    let tabsHtml = "", body = "";
    if (S.role === "police") {
        const convs = c.convictions || [], incs = c.incidents || [], vehs = c.vehicles || [], wars = c.warrants || [];
        const tabs = [["conv", `CONVICTIONS (${convs.length})`], ["inc", `INCIDENTS (${incs.length})`], ["veh", `VEHICLES (${vehs.length})`], ["war", `WARRANTS (${wars.length})`]];
        tabsHtml = tabs.map(([k, l]) => `<div class="tab ${S.citizenTab === k ? "on" : ""}" data-act="citTab" data-arg="${k}">${l}</div>`).join("");
        if (S.citizenTab === "conv") {
            body = convs.length ? convs.map(r => {
                const codes = toArr(r.charges).map(x => x.code).join(", ");
                const labels = toArr(r.charges).map(x => x.label).join(" · ");
                return `<div class="row fx ac gap16"><span class="mono accent fs13" style="min-width:80px">${esc(codes)}</span><span class="f1 fs15 fw5">${esc(labels)}</span><span class="mono fs13 dim">${money(r.fine)} · ${months(r.sentence)}</span><span class="mono fs12 dim2">${fmtTs(r.created).slice(0, 10)}</span></div>`;
            }).join("") : `<div class="empty" style="margin:20px">No convictions on record</div>`;
        } else if (S.citizenTab === "inc") {
            body = incs.length ? incs.map(r => `<div class="row fx ac gap16 pointer" data-act="openReport" data-arg="${r.id}"><span class="mono accent fs13">RPT-${esc(r.id)}</span><span class="f1 fs15 fw5">${esc(r.title)}</span><span class="mono fs13 dim">${esc(r.author_name)}</span><span class="mono fs12 dim2">${fmtTs(r.created).slice(0, 10)}</span></div>`).join("") : `<div class="empty" style="margin:20px">No incident history</div>`;
        } else if (S.citizenTab === "veh") {
            body = vehs.length ? vehs.map(v => `<div class="row fx ac gap16"><span class="mono fs16 fw6">${esc(v.plate)}</span><span class="f1 fs14 dim">${esc(v.vehicle)}</span><button class="btn bsm" data-act="runPlate" data-arg="${esc(v.plate)}">RUN PLATE</button></div>`).join("") : `<div class="empty" style="margin:20px">No registered vehicles</div>`;
        } else {
            body = wars.length ? wars.map(w => `<div class="row fx ac gap16">${w.status === "active" ? `<span class="wpulse"></span>` : ""}<span class="mono accent fs13">W-${esc(w.id)}</span><div class="f1"><div class="fs15 fw6 ${w.status === "active" ? "wtitle" : ""}">${esc(w.reason)}</div><div class="fs13 dim mt8">${esc(w.author_name)}</div></div><span class="pill ${w.status === "active" ? "pbad" : "pmut"}">${esc(w.status).toUpperCase()}</span>${w.status === "active" ? `<button class="btn bsm" data-act="serveWarrant" data-arg="${w.id}">MARK SERVED</button>` : ""}</div>`).join("") : `<div class="empty" style="margin:20px">No warrants</div>`;
        }
    } else {
        // EMS: medical records timeline
        const recs = toArr(S.medical);
        tabsHtml = `<div class="tab on">MEDICAL RECORDS (${recs.length})</div>`;
        body = (recs.length ? recs.map(r => `<div class="row"><div class="fx ac jb"><div class="fw6 fs15">${toArr(r.injuries).map(i => esc(typeof i === "string" ? i : i.zone + " — " + i.injury)).join(" · ") || "General entry"}</div><span class="mono fs12 dim2">${fmtTs(r.created)}</span></div>${r.treatment ? `<div class="fs14 dim mt8">TX: ${esc(r.treatment)}</div>` : ""}${r.medications ? `<div class="fs14 dim mt8">RX: ${esc(r.medications)}</div>` : ""}${r.notes ? `<div class="fs14 dim2 mt8">${esc(r.notes)}</div>` : ""}<div class="mono fs12 dim2 mt8">${esc(r.author_name)}</div></div>`).join("") : `<div class="empty" style="margin:20px">No medical history</div>`)
            + `<div class="pad16"><button class="btnp btn w100" data-act="modalMedical">+ NEW MEDICAL RECORD</button></div>`;
    }

    return `<div class="scr">
        ${activeWarrant && S.role === "police" ? `<div class="wban"><span class="wpulse"></span><div class="f1"><div class="disp fs20 fw7 wtitle">Active Warrant — ${esc(activeWarrant.reason)}</div><div class="mono fs13 dim mt8">W-${esc(activeWarrant.id)} · ISSUED ${fmtTs(activeWarrant.created)} · ${esc(activeWarrant.author_name)}</div></div><button class="btnp btn bsm" data-act="newReportFor" data-arg="${esc(c.citizenid)}">OPEN ARREST REPORT</button></div>` : ""}
        <div class="fx ac jb"><h1>${S.role === "ems" ? "Patient" : "Citizen"} Record</h1><span class="mono fs13 dim">${esc(c.citizenid)} ${c.online ? '· <span class="bok">IN CITY</span>' : ""}</span></div>
        <div class="citgrid">
            <div class="panel pad20 col gap16 oauto">
                <div class="fx gap16"><div class="mug">${c.image ? `<img src="${esc(c.image)}" alt="">` : ICO.person}</div>
                    <div class="f1"><div class="disp fs26 fw7" style="line-height:1.15">${esc(name)}</div><div class="mono fs13 dim mt8">${esc(c.citizenid)}</div>
                    <div class="fx gap8 mt12 wrap">${flags}</div></div></div>
                <div>
                    <div class="infr"><span class="dim">DATE OF BIRTH</span><span class="mono">${esc(c.dob)}</span></div>
                    <div class="infr"><span class="dim">GENDER</span><span class="mono">${Number(c.gender) === 1 ? "F" : "M"}</span></div>
                    <div class="infr"><span class="dim">NATIONALITY</span><span>${esc(c.nationality)}</span></div>
                    <div class="infr"><span class="dim">PHONE</span><span class="mono">${esc(c.phone)}</span></div>
                    <div class="infr"><span class="dim">EMPLOYMENT</span><span>${esc(c.job.label)}${c.job.grade ? " · " + esc(c.job.grade) : ""}</span></div>
                    ${S.role === "police" ? `<div class="infr"><span class="dim">GANG AFFILIATION</span><span class="mono accent">${esc(c.gang.label || "—")}</span></div>` : ""}
                    ${S.role === "ems" ? `<div class="infr"><span class="dim">BLOOD TYPE</span><span class="disp fs20 fw7" style="color:var(--acc)">${esc(c.bloodtype || "—")}</span></div>` : ""}
                </div>
                ${S.role === "police" ? `<div><div class="disp fs14 fw7 dim mb8">Licenses</div><div class="col gap8">${licencePills(c.licences)}</div></div>` : ""}
                <div><div class="disp fs14 fw7 dim mb8">Notes</div>
                    <textarea class="rte" id="citNotes" style="min-height:90px" placeholder="Department notes…">${esc(c.notes)}</textarea>
                    <div class="fx gap8 mt8"><button class="btn bsm f1" data-act="saveNotes">SAVE NOTES</button>
                    ${S.role === "police" ? `<button class="btnd btn bsm" data-act="modalWarrant" data-arg="${esc(c.citizenid)}">+ WARRANT</button>` : ""}</div></div>
            </div>
            <div class="panel col ohide">
                <div class="tabs" style="padding:0 12px">${tabsHtml}</div>
                <div class="col oauto f1">${body}</div>
            </div>
        </div>
    </div>`;
}

function renderVehicle() {
    let result = "";
    if (S.vehicleMiss) {
        result = `<div class="empty"><div class="disp fs18 fw6" style="color:#8494ad">NO DMV RECORD</div><div class="fs14 mt8">No vehicle registered under "${esc(S.vehicleMiss)}". Verify plate or try a partial via search.</div></div>`;
    } else if (S.vehicle) {
        const v = S.vehicle.vehicle, o = S.vehicle.owner, bolos = S.vehicle.bolos || [];
        result = `${bolos.length ? `<div class="wban"><span class="wpulse"></span><div class="f1"><div class="disp fs20 fw7 wtitle">Active BOLO — ${esc(bolos[0].title)}</div><div class="mono fs13 dim mt8">${esc(bolos[0].description || "")} · BY ${esc(bolos[0].author_name)}</div></div><button class="btnd btn bsm" data-act="nav" data-arg="bolo">VIEW BOARD</button></div>` : ""}
        <div class="panel col ohide stag">
            <div class="ph"><div class="fx ac gap16"><span class="mono fs26 fw6" style="letter-spacing:.15em">${esc(v.plate)}</span>${v.fakeplate ? `<span class="pill pwarn">FAKE PLATE: ${esc(v.fakeplate)}</span>` : ""}</div>
            <div class="fx gap8"><span class="pill ${Number(v.state) === 1 ? "pok" : "pwarn"}">${Number(v.state) === 2 ? "IMPOUNDED" : Number(v.state) === 0 ? "OUT" : "GARAGED"}</span></div></div>
            <div class="fx gap20 pad20">
                <div class="mug" style="width:190px;height:120px">${ICO.vehicle}</div>
                <div class="f1">
                    <div class="disp fs22 fw7">${esc(v.model)}</div>
                    <div class="infr mt12"><span class="dim">REGISTERED OWNER</span>${o ? `<span class="accent pointer" data-act="openCitizen" data-arg="${esc(o.citizenid)}">${esc(o.name)} ↗</span>` : "<span>—</span>"}</div>
                    <div class="infr"><span class="dim">GARAGE</span><span class="mono">${esc(v.garage || "—")}</span></div>
                    <div class="infr"><span class="dim">FUEL</span><span class="mono">${esc(v.fuel)}%</span></div>
                </div>
            </div>
        </div>`;
    }
    const recents = S.recents.map(p => `<span class="chip mono fs13" data-act="runPlate" data-arg="${esc(p)}">${esc(p)}</span>`).join(" ");
    return `<div class="scr">
        <div class="fx ac jb"><div><h1>Vehicle Lookup</h1><div class="mono fs12 dim mt8">DMV MIRROR · LIVE</div></div></div>
        <div style="max-width:920px" class="col gap20 w100">
            <div class="fx gap12"><input id="plateInp" class="inp mono f1" style="font-size:18px;letter-spacing:.2em" placeholder="ENTER PLATE" value="${esc(S.plateQ)}" data-model="plateQ"><button class="btnp btn" style="padding:0 30px" data-act="doPlate">RUN PLATE</button></div>
            ${S.recents.length ? `<div class="fx ac gap12"><span class="mono fs12 dim2">RECENT:</span>${recents}</div>` : ""}
            ${result}
        </div>
    </div>`;
}

function renderReports() {
    const rep = S.report;
    if (!rep) {
        const rows = S.reports.map(r => `<div class="row fx ac gap16 pointer" data-act="openReport" data-arg="${r.id}"><span class="mono accent fs13">RPT-${esc(r.id)}</span><span class="f1 fs15 fw5">${esc(r.title)}</span><span class="mono fs13 dim">${esc(r.author_name)}</span><span class="mono fs12 dim2">${fmtTs(r.created)}</span></div>`).join("");
        return `<div class="scr">
            <div class="fx ac jb"><div><h1>Incident Reports</h1><div class="mono fs12 dim mt8">${S.reports.length} ON FILE</div></div><button class="btnp btn bsm" data-act="openReport" data-arg="">+ NEW REPORT</button></div>
            <section class="panel col ohide f1"><div class="col stag oauto f1">${rows || `<div class="empty" style="margin:16px">No reports filed yet</div>`}</div></section>
        </div>`;
    }
    // editor
    const tabs = [["inv", "INVOLVED"], ["ev", "EVIDENCE"], ["chg", `CHARGES (${rep.charges.length})`]];
    const tabsHtml = tabs.map(([k, l]) => `<div class="tab ${S.reportTab === k ? "on" : ""}" data-act="repTab" data-arg="${k}">${l}</div>`).join("");
    let side = "";
    if (S.reportTab === "inv") {
        const res = S.citQRes.map(c => `<div class="fx ac gap12"><div class="av">${initials(c.name)}</div><div class="f1"><div class="fs14 fw6">${esc(c.name)}</div><div class="mono fs12 dim">${esc(c.citizenid)}</div></div><button class="btn bsm" data-act="repAddPerson" data-arg="${esc(c.citizenid)}|${esc(c.name)}">+ ATTACH</button></div>`).join("");
        const people = rep.people.map((p, i) => `<div class="fx ac gap12"><div class="av">${initials(p.label)}</div><div class="f1"><div class="fs14 fw6">${esc(p.label)}</div><div class="mono fs12 dim">${esc(p.id)}</div></div><button class="xbtn" data-act="repRmPerson" data-arg="${i}">×</button></div>`).join("");
        const vehs = rep.vehicles.map((v, i) => `<div class="fx ac gap12"><span class="mono fs14 fw6">${esc(v.id)}</span><span class="f1 fs13 dim">${esc(v.label)}</span><button class="xbtn" data-act="repRmVeh" data-arg="${i}">×</button></div>`).join("");
        side = `<div class="pad16 col gap12">
            <input class="inp w100" placeholder="Search citizens to attach…" value="${esc(S.citQ)}" data-model="citQ">${res}
            <div class="disp fs13 fw7 dim mt8">Attached Citizens</div>${people || `<div class="fs13 dim2">None attached</div>`}
            <div class="disp fs13 fw7 dim mt8">Attached Vehicles</div>${vehs || `<div class="fs13 dim2">None attached</div>`}
            <div class="fx gap8"><input id="repPlate" class="inp f1 mono" placeholder="PLATE"><button class="btn bsm" data-act="repAddVeh">+ ATTACH</button></div>
        </div>`;
    } else if (S.reportTab === "ev") {
        const evs = rep.evidence.map((e, i) => `<div class="fx ac gap12"><span class="mono fs13 accent">${esc(e.id)}</span><span class="f1 fs13 dim">${esc(e.label)}</span><button class="xbtn" data-act="repRmEv" data-arg="${i}">×</button></div>`).join("");
        side = `<div class="pad16 col gap12">
            <div class="disp fs13 fw7 dim">Logged To This Report</div>${evs || `<div class="fs13 dim2">No evidence logged</div>`}
            <div class="disp fs13 fw7 dim mt8">Log Evidence ID</div>
            <div class="fs12 dim2">Casing / blood / fingerprint IDs from the field scanner.</div>
            <div class="fx gap8"><input id="repEvId" class="inp f1 mono" placeholder="e.g. casing-a1b2c3d4"><input id="repEvLabel" class="inp f1" placeholder="Label"><button class="btn bsm" data-act="repAddEv">+ LOG</button></div>
        </div>`;
    } else {
        const q = S.chargeQ.trim().toLowerCase();
        const sel = rep.charges.map((code, i) => {
            const c = chargeByCode(code) || { label: code, fine: 0, sentence: 0 };
            return `<div class="fx ac gap12"><span class="mono fs13 accent" style="width:52px">${esc(code)}</span><span class="f1 fs14 fw6">${esc(c.label)}</span><span class="mono fs13">${money(c.fine)}</span><button class="xbtn" data-act="repRmChg" data-arg="${i}">×</button></div>`;
        }).join("");
        const list = flatPenal().filter(c => !q || (c.code + " " + c.label).toLowerCase().includes(q)).slice(0, 12).map(c =>
            `<div class="fx ac gap12"><span class="mono fs13 dim" style="width:52px">${esc(c.code)}</span><div class="f1"><div class="fs14">${esc(c.label)}</div><div class="mono fs12 dim2">${money(c.fine)} · ${months(c.sentence)} · ${esc(c.class)}</div></div><button class="btn bsm" data-act="repAddChg" data-arg="${esc(c.code)}">+</button></div>`
        ).join("");
        const totalFine = rep.charges.reduce((a, code) => a + Number((chargeByCode(code) || {}).fine || 0), 0);
        const totalSent = rep.charges.reduce((a, code) => a + Number((chargeByCode(code) || {}).sentence || 0), 0);
        const targets = rep.people.map(p => `<option value="${esc(p.id)}">${esc(p.label)}</option>`).join("");
        side = `<div class="col f1 ohide"><div class="pad16 col gap12 oauto f1">
            <div class="disp fs13 fw7 dim">Filed Charges</div>${sel || `<div class="fs13 dim2">No charges selected</div>`}
            <input class="inp w100 mt8" placeholder="Filter penal code…" value="${esc(S.chargeQ)}" data-model="chargeQ">${list}
        </div>
        <div class="totals">
            <div class="fx jb"><span class="dim fs14">TOTAL FINE</span><span class="mono fs18 fw6" style="color:#eaf2ff">${money(totalFine)}</span></div>
            <div class="fx jb mt8"><span class="dim fs14">TOTAL SENTENCE</span><span class="mono fs18 fw6" style="color:#eaf2ff">${months(totalSent)}</span></div>
            <div class="fx gap8 mt12 ac"><span class="fs13 dim">SUSPECT</span><select id="arrestTarget" class="inp f1">${targets || `<option value="">— attach a citizen first —</option>`}</select></div>
            <button class="btnp btn w100 mt12" style="padding:13px" ${(!rep.charges.length || !rep.people.length) ? "disabled" : ""} data-act="processArrest">PROCESS ARREST</button>
        </div></div>`;
    }
    return `<div class="scr">
        <div class="fx ac jb"><div><h1>Incident Report</h1><div class="mono fs12 dim mt8">${rep.id ? "RPT-" + rep.id : '<span class="pwarn pill">NEW DRAFT</span>'} · ${esc(rep.author || (S.officer && S.officer.name) || "")}</div></div>
        <div class="fx gap8"><button class="btn bsm" data-act="closeReport">← ALL REPORTS</button><button class="btnp btn bsm" data-act="saveReport">SAVE REPORT</button></div></div>
        <div class="repgrid">
            <div class="col gap12 ohide">
                <input id="repTitle" class="inp disp fs18 fw6" placeholder="REPORT TITLE" value="${esc(rep.title)}">
                <textarea id="repText" class="rte" placeholder="Narrative…">${esc(rep.details)}</textarea>
            </div>
            <div class="panel col ohide">
                <div class="tabs" style="padding:0 10px">${tabsHtml}</div>
                <div class="col ohide f1">${side}</div>
            </div>
        </div>
    </div>`;
}

function renderBolo() {
    const label = S.role === "police" ? "BOLO Board" : "Advisories";
    const cards = S.bolos.map(b => {
        const pri = Number(b.priority);
        const strip = pri === 1 ? "sh" : pri === 2 ? "sm" : "sl";
        const pcls = pri === 1 ? "pbad" : pri === 2 ? "pwarn" : "pmut";
        const pl = pri === 1 ? "HIGH" : pri === 2 ? "MED" : "LOW";
        return `<div class="panel col ohide"><div class="strp ${strip}"></div>
            <div class="bphoto">${b.image ? `<img src="${esc(b.image)}" style="width:100%;height:100%;object-fit:cover">` : (b.bolo_type === "vehicle" ? ICO.vehicle : ICO.person)}</div>
            <div class="pad16 col gap8 f1">
                <div class="fx ac jb"><span class="pill ${pcls}">${pl} PRIORITY</span><span class="pill pmut">${esc(b.bolo_type).toUpperCase()}</span></div>
                <div class="disp fs18 fw7 mt8">${esc(b.title)}</div>
                ${b.identifier ? `<div class="mono fs13 accent">${esc(b.identifier)}</div>` : ""}
                <div class="fs14 dim" style="line-height:1.55">${esc(b.description || "")}</div>
                <div class="fx ac jb mt8"><span class="mono fs12 dim2">${esc(b.author_name)} · ${fmtTs(b.created)}</span><button class="btn bsm" data-act="resolveBolo" data-arg="${b.id}">RESOLVE</button></div>
            </div></div>`;
    }).join("");
    return `<div class="scr">
        <div class="fx ac jb"><div><h1>${label}</h1><div class="mono fs12 dim mt8">${S.bolos.length} ACTIVE ADVISORIES</div></div><button class="btnp btn bsm" data-act="modalBolo">+ NEW ${S.role === "police" ? "BOLO" : "ADVISORY"}</button></div>
        <div class="bologrid stag">${cards || `<div class="empty" style="grid-column:1/-1">Nothing active — board is clear</div>`}</div>
    </div>`;
}

// ─────────────────────────── overlays ───────────────────────────────────────

function renderModal() {
    if (!S.modal) return "";
    const { kind, data } = S.modal;
    let inner = "";
    if (kind === "bulletin") {
        inner = `<div class="disp fs22 fw7">Post Bulletin</div>
        <input id="mTitle" class="inp w100 mt16" placeholder="Title">
        <textarea id="mBody" class="rte w100 mt12" style="min-height:110px" placeholder="Content…"></textarea>
        <div class="fx gap12 mt16"><button class="btn f1" data-act="closeModal">CANCEL</button><button class="btnp btn f1" data-act="submitBulletin">POST</button></div>`;
    } else if (kind === "call") {
        inner = `<div class="disp fs22 fw7">Create Dispatch Call</div>
        <div class="fx gap12 mt16"><input id="mCode" class="inp mono" style="width:120px" placeholder="CODE"><input id="mTitle" class="inp f1" placeholder="Title"></div>
        <textarea id="mBody" class="rte w100 mt12" style="min-height:90px" placeholder="Details…"></textarea>
        <div class="fx gap8 mt12 ac"><span class="fs13 dim">PRIORITY</span><select id="mPri" class="inp f1"><option value="1">1 — Emergency</option><option value="2" selected>2 — Priority</option><option value="3">3 — Routine</option></select></div>
        <div class="fx gap12 mt16"><button class="btn f1" data-act="closeModal">CANCEL</button><button class="btnp btn f1" data-act="submitCall">BROADCAST</button></div>`;
    } else if (kind === "unit") {
        const rows = S.unitBoard.map(u => {
            const mine = S.myUnit === u.id;
            const occ = u.occupants.map(o2 => esc(o2.name)).join(", ");
            return `<div class="fx ac gap12 mt12">
                <div class="f1"><div class="fx ac gap8"><span class="disp fw7 fs15">${esc(u.id)}</span><span class="mono fs11 dim2">${esc(u.freq || "")} MHz</span></div>
                <div class="fs12 ${occ ? "dim" : "dim2"} mt-2">${occ || "Unassigned"}</div></div>
                ${mine ? `<button class="btnd btn bsm" data-act="leaveUnit">DISCONNECT</button>` : `<button class="btnp btn bsm" data-act="joinUnit" data-arg="${esc(u.id)}">CONNECT</button>`}
            </div>`;
        }).join("");
        inner = `<div class="disp fs22 fw7">Unit &amp; Radio</div>
        <div class="fs13 dim mt8">Connecting to a unit sets your callsign and joins its radio frequency. Partners on the same unit share the channel.</div>
        ${rows}
        <div class="fx gap12 mt16"><button class="btn f1" data-act="closeModal">CLOSE</button></div>`;
    } else if (kind === "warrant") {
        inner = `<div class="disp fs22 fw7">Issue Warrant</div>
        <div class="mono fs13 dim mt8">TARGET: ${esc(data.citizenid)}</div>
        <input id="mTitle" class="inp w100 mt16" placeholder="Reason / charge">
        <div class="fx gap8 mt12 ac"><span class="fs13 dim">EXPIRES</span><select id="mExp" class="inp f1"><option value="">Never</option><option value="3">3 days</option><option value="7" selected>7 days</option><option value="14">14 days</option><option value="30">30 days</option></select></div>
        <div class="fx gap12 mt16"><button class="btn f1" data-act="closeModal">CANCEL</button><button class="btnd btn f1" data-act="submitWarrant">ISSUE WARRANT</button></div>`;
    } else if (kind === "bolo") {
        inner = `<div class="disp fs22 fw7">New ${S.role === "police" ? "BOLO" : "Advisory"}</div>
        <div class="fx gap8 mt16 ac"><span class="fs13 dim">TYPE</span><select id="mType" class="inp f1"><option value="person">Person</option><option value="vehicle">Vehicle</option></select>
        <span class="fs13 dim">PRIORITY</span><select id="mPri" class="inp f1"><option value="1">High</option><option value="2" selected>Med</option><option value="3">Low</option></select></div>
        <input id="mTitle" class="inp w100 mt12" placeholder="Title (name / plate headline)">
        <input id="mIdent" class="inp w100 mono mt12" placeholder="Identifier — citizen ID or plate (optional)">
        <textarea id="mBody" class="rte w100 mt12" style="min-height:90px" placeholder="Description…"></textarea>
        <div class="fx gap12 mt16"><button class="btn f1" data-act="closeModal">CANCEL</button><button class="btnp btn f1" data-act="submitBolo">BROADCAST</button></div>`;
    } else if (kind === "medical") {
        inner = `<div class="disp fs22 fw7">New Medical Record</div>
        <div class="mono fs13 dim mt8">PATIENT: ${esc(S.citizen ? S.citizen.citizenid : "")}</div>
        <input id="mInj" class="inp w100 mt16" placeholder="Injuries (comma separated)">
        <input id="mTx" class="inp w100 mt12" placeholder="Treatment administered">
        <input id="mRx" class="inp w100 mt12" placeholder="Medications">
        <textarea id="mBody" class="rte w100 mt12" style="min-height:80px" placeholder="Notes…"></textarea>
        <div class="fx gap12 mt16"><button class="btn f1" data-act="closeModal">CANCEL</button><button class="btnp btn f1" data-act="submitMedical">FILE RECORD</button></div>`;
    } else if (kind === "arrest") {
        const lines = data.charges.map(c => `<div class="fx jb fs14 mt8"><span>${esc(c.code)} — ${esc(c.label)}</span><span class="mono">${money(c.fine)} · ${months(c.sentence)}</span></div>`).join("");
        inner = `<div class="disp fs22 fw7">Confirm Arrest</div>
        <div class="mono fs13 dim mt8">SUSPECT: ${esc(data.label)} (${esc(data.citizenid)})</div>
        <div class="panel pad16 mt12">${lines}
        <div class="fx jb mt12" style="border-top:1px solid rgba(125,165,230,.13);padding-top:10px"><span class="disp fw7">TOTAL</span><span class="mono fw6">${money(data.fine)} · ${months(data.sentence)}</span></div></div>
        <div class="fx gap12 mt16"><button class="btn f1" data-act="closeModal">CANCEL</button><button class="btnd btn f1" data-act="confirmArrest">PROCESS — FILE CONVICTION</button></div>`;
    }
    // NOTE: no stopPropagation on .modal — that would kill the delegated click
    // handler for buttons inside it. Backdrop-close is handled by an .ovl target
    // check in the stage click listener instead.
    return `<div class="ovl"><div class="modal panel">${inner}</div></div>`;
}

// Three independent hosts so updating a toast/panic never rebuilds the modal
// (which would wipe any in-progress form inputs).
function renderModalHost() {
    const h = $("#modalHost");
    if (h) h.innerHTML = renderModal();
}
function renderToastHost() {
    const h = $("#toastHost");
    if (h) h.innerHTML = S.toast ? `<div class="toastw panel"><span class="dot d3" style="background:var(--acc);box-shadow:0 0 10px var(--glow)"></span><span class="fs14 fw5 mono">${esc(S.toast)}</span></div>` : "";
}
function renderPanicHost() {
    const h = $("#panicHost");
    if (h) h.innerHTML = S.panic ? `<div class="panicov"><div class="pframe"></div><div class="pban"><span class="wpulse"></span><div><div class="disp fs20 fw7" style="color:#ff6b75">PANIC BROADCAST — ${esc(S.panic.callsign)}</div><div class="mono fs13 dim mt8">${esc(S.panic.name)}${S.panic.coords ? " · GPS FIX ATTACHED" : ""}</div></div>${S.panic.coords ? `<button class="btnd btn bsm" data-act="panicWaypoint">RESPOND</button>` : ""}</div></div>` : "";
}
function renderOverlays() {
    renderModalHost();
    renderToastHost();
    renderPanicHost();
}

// ─────────────────────────── root render ────────────────────────────────────

function render() {
    stage.className = "shell " + (S.role === "ems" ? "ems" : "police");
    let inner;
    if (S.screen === "boot") inner = renderBoot();
    else if (S.screen === "login") inner = renderLogin();
    else {
        const scr = { dash: renderDash, dispatch: renderDispatch, citizen: renderCitizen, vehicle: renderVehicle, reports: renderReports, bolo: renderBolo }[S.screen] || renderDash;
        inner = `<div class="fx w100" style="height:100%">${renderSidebar()}<div class="col f1 ohide">${renderTopbar()}<div class="content">${scr()}</div></div></div>`;
    }
    stage.innerHTML = `<div class="gridbg"></div>${inner}<div id="overlays"><div id="modalHost"></div><div id="toastHost"></div><div id="panicHost"></div></div><div class="scanl"></div>`;
    renderOverlays();
    const gs = $("#gsearch");
    if (gs && S.searchRes) gs.focus();
}

// A full render() rebuilds the whole DOM, wiping any in-progress form. Background
// updates (loads, dispatch push events) must not do that while the user is filling
// a modal or the report editor — the data is still stored in S and shown on close.
function isEditing() {
    return !!S.modal || (S.screen === "reports" && !!S.report);
}
function bgRender() {
    if (!isEditing()) render();
}

// ─────────────────────────── actions ────────────────────────────────────────

let searchTimer = null;

const ACTIONS = {
    skipBoot() { S.screen = "login"; render(); },
    dutyPick(arg) { S.dutyPick = arg; render(); },
    async doLogin() {
        await rpc("setUnitStatus", { status: S.dutyPick });
        S.booted = true;
        go("dash");
    },
    modalUnit() { openModal("unit"); },
    async joinUnit(arg) { await applyJoinUnit(arg, false); render(); },
    async leaveUnit() {
        const r = await rpc("leaveUnit", {});
        if (r && r.ok) {
            S.myUnit = null;
            if (S.officer) S.officer.callsign = "NO CALLSIGN";
            syncMyUnitEntry("NO CALLSIGN");
            S.unitBoard = toArr(r.unitBoard);
            toast("Disconnected from unit radio");
        }
        render();
    },
    nav(arg) { if (arg === "citizen") { S.screen = "citizen"; render(); } else if (arg === "vehicle") { S.screen = "vehicle"; render(); } else if (arg === "reports") { S.report = null; go("reports"); } else go(arg); },
    cycleStatus() {
        const opts = S.statuses.length ? S.statuses : ["available", "busy", "enroute", "onscene", "unavailable"];
        const i = opts.indexOf(S.dutyPick);
        S.dutyPick = opts[(i + 1) % opts.length];
        rpc("setUnitStatus", { status: S.dutyPick });
        render();
    },
    panic() { hEvent("mdt:panic", {}); toast("Panic broadcast sent"); },
    // Nested objects don't survive hEvent JS->Lua — stringify, Lua parses (same as rpc()).
    panicWaypoint() { if (S.panic && S.panic.coords) { hEvent("mdt:setWaypoint", { payload: JSON.stringify({ coords: S.panic.coords, title: "PANIC — " + S.panic.callsign }) }); toast("Waypoint set"); } },
    openCitizen(arg) { openCitizen(arg); },
    citTab(arg) { S.citizenTab = arg; render(); },
    async saveNotes() {
        const notes = ($("#citNotes") || {}).value || "";
        const r = await rpc("saveProfile", { citizenid: S.citizen.citizenid, notes, flags: S.citizen.flags || [], image: S.citizen.image || "" });
        toast(r && r.ok ? "Notes saved" : "Save failed");
        if (S.citizen) S.citizen.notes = notes;
    },
    runPlate(arg) { runPlate(arg); },
    doPlate() { runPlate(($("#plateInp") || {}).value); },
    openCall(arg) { S.callId = arg; if (S.screen !== "dispatch") S.screen = "dispatch"; render(); },
    async attachCall(arg) {
        const r = await rpc("attachToCall", { id: Number(arg) });
        if (r && r.ok) { toast("Attached to call"); applyCallUpdate(r.call); }
        else toast((r && (r.message || r.error)) || "Could not attach");
        render();
        loadCalls(); // authoritative refresh behind the optimistic update
    },
    async detachCall(arg) {
        const r = await rpc("detachFromCall", { id: Number(arg) });
        if (r && r.ok) applyCallUpdate(r.call);
        else toast((r && (r.message || r.error)) || "Could not detach");
        render();
        loadCalls();
    },
    async closeCall(arg) {
        const r = await rpc("closeCall", { id: Number(arg) });
        if (r && r.ok) { toast("Call closed"); S.calls = S.calls.filter(c => Number(c.id) !== Number(arg)); }
        else toast((r && (r.message || r.error)) || "Could not close call");
        render();
        loadCalls();
    },
    waypoint(arg) {
        const call = S.calls.find(c => String(c.id) === String(arg));
        // Nested objects don't survive hEvent JS->Lua — stringify, Lua parses (same as rpc()).
        if (call && call.coords) { hEvent("mdt:setWaypoint", { payload: JSON.stringify({ coords: call.coords, title: call.title }) }); toast("Waypoint set"); }
    },
    // reports
    openReport(arg) { openReport(arg ? Number(arg) : null); },
    closeReport() { S.report = null; render(); },
    repTab(arg) { S.reportTab = arg; syncReportInputs(); render(); },
    saveReport() { syncReportInputs(); saveReport(); },
    newReportFor(arg) {
        const c = S.citizen;
        S.report = { id: null, title: "", details: "", people: [{ id: arg, label: c ? ((c.firstname || "") + " " + (c.lastname || "")).trim() : arg }], vehicles: [], evidence: [], charges: [] };
        S.reportTab = "chg"; S.screen = "reports";
        render();
    },
    repAddPerson(arg) { const [id, label] = arg.split("|"); syncReportInputs(); if (!S.report.people.some(p => p.id === id)) S.report.people.push({ id, label }); S.citQ = ""; S.citQRes = []; render(); },
    repRmPerson(arg) { syncReportInputs(); S.report.people.splice(Number(arg), 1); render(); },
    repAddVeh() { syncReportInputs(); const p = (($("#repPlate") || {}).value || "").trim().toUpperCase(); if (p && !S.report.vehicles.some(v => v.id === p)) S.report.vehicles.push({ id: p, label: "" }); render(); },
    repRmVeh(arg) { syncReportInputs(); S.report.vehicles.splice(Number(arg), 1); render(); },
    repAddEv() { syncReportInputs(); const id = (($("#repEvId") || {}).value || "").trim(); const label = (($("#repEvLabel") || {}).value || "").trim(); if (id) S.report.evidence.push({ id, label }); render(); },
    repRmEv(arg) { syncReportInputs(); S.report.evidence.splice(Number(arg), 1); render(); },
    repAddChg(arg) { syncReportInputs(); S.report.charges.push(arg); render(); },
    repRmChg(arg) { syncReportInputs(); S.report.charges.splice(Number(arg), 1); render(); },
    processArrest() {
        syncReportInputs();
        const sel = $("#arrestTarget");
        const citizenid = sel ? sel.value : "";
        if (!citizenid) { toast("Attach a citizen first"); return; }
        const person = S.report.people.find(p => p.id === citizenid);
        const charges = S.report.charges.map(code => chargeByCode(code)).filter(Boolean);
        openModal("arrest", {
            citizenid, label: person ? person.label : citizenid, charges,
            fine: charges.reduce((a, c) => a + Number(c.fine), 0),
            sentence: charges.reduce((a, c) => a + Number(c.sentence), 0),
        });
    },
    async confirmArrest() {
        const d = S.modal.data;
        closeModal();
        await saveReport(true);
        const r = await rpc("processArrest", { citizenid: d.citizenid, incidentId: S.report.id, charges: S.report.charges });
        if (r && r.ok) { toast(`Conviction filed — ${money(r.fine)} · ${months(r.sentence)}`); S.report.charges = []; openReport(S.report.id); }
        else toast(r && r.message ? r.message : "Arrest failed");
    },
    // warrants
    modalWarrant(arg) { openModal("warrant", { citizenid: arg }); },
    async submitWarrant() {
        const reason = (($("#mTitle") || {}).value || "").trim();
        const exp = ($("#mExp") || {}).value;
        if (!reason) { toast("Reason required"); return; }
        const r = await rpc("createWarrant", { citizenid: S.modal.data.citizenid, reason, expiresDays: exp ? Number(exp) : undefined });
        closeModal();
        if (r && r.ok) { toast("Warrant issued"); if (S.citizen) openCitizen(S.citizen.citizenid); }
    },
    async serveWarrant(arg) { const r = await rpc("updateWarrant", { id: Number(arg), status: "served" }); if (r && r.ok) { toast("Warrant served"); if (S.citizen) openCitizen(S.citizen.citizenid); } },
    // bolos
    modalBolo() { openModal("bolo"); },
    async submitBolo() {
        const payload = {
            bolo_type: ($("#mType") || {}).value, priority: Number(($("#mPri") || {}).value || 2),
            title: (($("#mTitle") || {}).value || "").trim(), identifier: (($("#mIdent") || {}).value || "").trim(),
            description: (($("#mBody") || {}).value || "").trim(),
        };
        if (!payload.title) { toast("Title required"); return; }
        const r = await rpc("createBolo", payload);
        closeModal();
        if (r && r.ok) { toast("Broadcast sent"); loadBolos(); }
    },
    async resolveBolo(arg) { const r = await rpc("resolveBolo", { id: Number(arg) }); if (r && r.ok) { toast("Resolved"); loadBolos(); } },
    // bulletins
    modalBulletin() { openModal("bulletin"); },
    async submitBulletin() {
        const title = (($("#mTitle") || {}).value || "").trim();
        const content = (($("#mBody") || {}).value || "").trim();
        if (!title) { toast("Title required"); return; }
        const r = await rpc("addBulletin", { title, content });
        closeModal();
        if (r && r.ok) { S.bulletins.unshift({ id: r.id, title, content, author_name: S.officer.name, author_cid: S.officer.citizenid, created: new Date().toISOString() }); toast("Bulletin posted"); render(); }
    },
    async delBulletin(arg) {
        const r = await rpc("deleteBulletin", { id: Number(arg) });
        if (r && r.ok) { S.bulletins = S.bulletins.filter(b => Number(b.id) !== Number(arg)); render(); }
    },
    // dispatch modal
    modalCall() { openModal("call"); },
    async submitCall() {
        const payload = { code: (($("#mCode") || {}).value || "").trim(), title: (($("#mTitle") || {}).value || "").trim(), details: (($("#mBody") || {}).value || "").trim(), priority: Number(($("#mPri") || {}).value || 2) };
        if (!payload.title) { toast("Title required"); return; }
        const r = await rpc("createCall", payload);
        closeModal();
        if (r && r.ok) { toast("Call broadcast"); loadCalls(); }
        else toast((r && (r.message || r.error)) || "Call failed — not saved");
    },
    // medical
    modalMedical() { openModal("medical"); },
    async submitMedical() {
        const injuries = (($("#mInj") || {}).value || "").split(",").map(s => s.trim()).filter(Boolean);
        const payload = { citizenid: S.citizen.citizenid, injuries, treatment: (($("#mTx") || {}).value || "").trim(), medications: (($("#mRx") || {}).value || "").trim(), notes: (($("#mBody") || {}).value || "").trim(), flags: [] };
        const r = await rpc("saveMedicalRecord", payload);
        closeModal();
        if (r && r.ok) { toast("Record filed"); openCitizen(S.citizen.citizenid); }
    },
    closeModal() { closeModal(); },
};

// Mirror my callsign into the local S.units entry so occupancy counts update
// immediately; the server's unitsUpdated broadcast overwrites it moments later.
function syncMyUnitEntry(callsign) {
    if (!S.officer) return;
    const me = S.units.find(x => x.citizenid === S.officer.citizenid);
    if (me) me.callsign = callsign;
}

async function applyJoinUnit(unitId, quiet) {
    const r = await rpc("joinUnit", { unit: unitId });
    if (r && r.ok) {
        S.myUnit = r.unit;
        if (S.officer) S.officer.callsign = r.unit;
        syncMyUnitEntry(r.unit);
        S.unitBoard = toArr(r.unitBoard);
        if (!quiet) toast(`Connected — ${r.unit} · ${r.freq || ""} MHz`);
    } else if (!quiet) {
        toast((r && r.message) || "Could not join unit");
    }
    return r;
}

// ─────────────────────────── radio PTT HUD ──────────────────────────────────
// Small in-game overlay (independent of the tablet) shown while someone on
// the unit is keying up. Payload from qb-mdt:client:ptt via mdt:ptt.
const radioHud = document.getElementById("radioHud");
let pttHideTimer = null;

function renderPttHud(p) {
    clearTimeout(pttHideTimer);
    if (!p || !p.talking) {
        // brief linger so quick key taps still read
        pttHideTimer = setTimeout(() => radioHud.classList.add("hidden"), 180);
        return;
    }
    const bars = Array.from({ length: 24 }, () => "<i></i>").join("");
    radioHud.className = S.role === "ems" ? "ems" : "police"; // re-theme, unhide
    radioHud.innerHTML = `<div class="rhud">
        <div class="rtop">
            <span class="rico">${ICO.dispatch}</span>
            <div class="f1">
                <div class="rline1"><span class="runit">${esc(p.unit || "")}</span><span class="rfreq">${esc(p.freq || "")} MHz</span></div>
                <div class="rline2">${p.self ? (p.voice ? "TRANSMITTING" : "ON AIR — HOLD V TO SPEAK") : `SPEAKING — ${esc(p.name || "")}`}</div>
            </div>
            <span class="rdot"></span>
        </div>
        <div class="rwave ${p.voice ? "on" : ""}">${bars}</div>
    </div>`;
}

function syncReportInputs() {
    if (!S.report) return;
    const t = $("#repTitle"), d = $("#repText");
    if (t) S.report.title = t.value;
    if (d) S.report.details = d.value;
}

// ─────────────────────────── event wiring ───────────────────────────────────

stage.addEventListener("click", (e) => {
    // Backdrop click (only the .ovl itself, not its children) closes the modal.
    if (e.target.classList && e.target.classList.contains("ovl")) { closeModal(); return; }
    const el = e.target.closest("[data-act]");
    if (!el) return;
    const fn = ACTIONS[el.dataset.act];
    if (fn) fn.call(ACTIONS, el.dataset.arg);
});

stage.addEventListener("input", (e) => {
    const el = e.target;
    const model = el.dataset && el.dataset.model;
    if (!model) return;
    S[model] = el.value;
    if (model === "searchQ") {
        clearTimeout(searchTimer);
        const q = el.value.trim();
        if (q.length < 2) { S.searchRes = null; renderSearchDropOnly(); return; }
        searchTimer = setTimeout(async () => {
            const r = await rpc("search", { query: q });
            if (r && r.ok && S.searchQ.trim() === q) { r.citizens = toArr(r.citizens); r.vehicles = toArr(r.vehicles); S.searchRes = r; renderSearchDropOnly(); }
        }, 300);
    }
    if (model === "citQ") {
        clearTimeout(searchTimer);
        const q = el.value.trim();
        if (q.length < 2) { S.citQRes = []; return; }
        searchTimer = setTimeout(async () => {
            const r = await rpc("search", { query: q });
            if (r && r.ok) { syncReportInputs(); S.citQRes = toArr(r.citizens).slice(0, 3); render(); const inp = stage.querySelector('[data-model="citQ"]'); if (inp) { inp.focus(); inp.setSelectionRange(inp.value.length, inp.value.length); } }
        }, 300);
    }
    if (model === "chargeQ") { syncReportInputs(); render(); const inp = stage.querySelector('[data-model="chargeQ"]'); if (inp) { inp.focus(); inp.setSelectionRange(inp.value.length, inp.value.length); } }
});

stage.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && e.target.id === "plateInp") runPlate(e.target.value);
    if (e.key === "Enter" && e.target.id === "gsearch") {
        // open first result
        const r = S.searchRes;
        if (r && r.citizens && r.citizens[0]) openCitizen(r.citizens[0].citizenid);
        else if (r && r.vehicles && r.vehicles[0]) runPlate(r.vehicles[0].plate);
    }
});

function renderSearchDropOnly() {
    const holder = $("#gsearch") && $("#gsearch").parentElement;
    if (!holder) return;
    const old = holder.querySelector(".sdrop");
    if (old) old.remove();
    holder.insertAdjacentHTML("beforeend", renderSearchDrop());
}

window.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
        if (S.modal) { closeModal(); return; }
        hEvent("mdt:close", {});
    }
});

// clock — cheap targeted update
setInterval(() => { const c = $("#clock"); if (c) c.textContent = clock(); }, 1000);

// ─────────────────────────── Lua -> JS ──────────────────────────────────────

window.addEventListener("message", (event) => {
    // HELIX WebUI:SendEvent delivers { name, args:[payload] } (see qb-banking).
    const { name: action, args } = event.data || {};
    if (!action) return;
    const payload = args && args[0];

    switch (action) {
        case "mdt:open": {
            S.open = true;
            S.role = payload.role || "police";
            S.officer = payload.officer || {};
            S.bulletins = toArr(payload.bulletins);
            S.units = toArr(payload.units);
            S.unitBoard = toArr(payload.unitBoard);
            S.myUnit = (S.officer.callsign && S.officer.callsign !== "NO CALLSIGN") ? S.officer.callsign : null;
            S.penal = toArr(payload.penalCode);
            S.priorities = payload.priorities || {};
            S.statuses = toArr(payload.statuses);
            tablet.classList.remove("hidden", "closing");
            rescale();
            if (!S.booted) { S.screen = "boot"; render(); setTimeout(() => { if (S.screen === "boot") { S.screen = "login"; render(); } }, 2600); }
            else go("dash");
            break;
        }
        case "mdt:close":
            S.open = false;
            // Hide instantly — no exit animation: the WebUI throttles rendering
            // once input mode drops, so a CSS fade can freeze mid-frame and
            // leave a ghost tablet on screen.
            tablet.classList.remove("closing");
            tablet.classList.add("hidden");
            break;
        case "mdt:response": {
            const resolve = pending[payload.reqId];
            if (resolve) { delete pending[payload.reqId]; resolve(payload.data); }
            break;
        }
        case "mdt:newCall": {
            payload.units = toArr(payload.units);
            S.calls.unshift(payload);
            if (S.open) { toast(`NEW CALL — ${payload.code || ""} ${payload.title}`); if (S.screen === "dispatch" || S.screen === "dash") bgRender(); }
            break;
        }
        case "mdt:callUpdated": {
            applyCallUpdate(payload);
            if (S.open && (S.screen === "dispatch" || S.screen === "dash")) bgRender();
            break;
        }
        case "mdt:unitsUpdated":
            S.units = toArr(payload);
            if (S.open && (S.screen === "dash" || S.screen === "dispatch")) bgRender();
            break;
        case "mdt:warrantIssued":
            if (S.open) toast(`WARRANT ISSUED — ${payload.citizenid}`);
            break;
        case "mdt:boloIssued":
            if (S.open) { toast(`NEW BOLO — ${payload.title}`); if (S.screen === "bolo") loadBolos(); }
            break;
        case "mdt:panic":
            if (S.open) showPanic(payload);
            break;
        case "mdt:ptt":
            renderPttHud(payload);
            break;
        case "mdt:refresh":
            if (S.open && S.screen === "dash") loadDashboard();
            break;
    }
});

// ─────────────────────────── browser preview harness ────────────────────────
// Runs only outside HELIX (window.hEvent absent). Feeds demo data so the UI is
// reviewable in a plain browser. Zero effect in game.
if (IS_PREVIEW) {
    const demo = {
        unitBoard: [
            { id: "ADAM-1", channel: 30101, freq: "126.525", occupants: [{ citizenid: "X2", name: "D. Mercer" }] },
            { id: "ADAM-2", channel: 30102, freq: "126.550", occupants: [] },
            { id: "ADAM-3", channel: 30103, freq: "126.575", occupants: [] },
            { id: "ADAM-4", channel: 30104, freq: "126.600", occupants: [] },
            { id: "ADAM-5", channel: 30105, freq: "126.625", occupants: [] },
            { id: "ADAM-6", channel: 30106, freq: "126.650", occupants: [] },
            { id: "LINCOLN-1", channel: 30111, freq: "127.100", occupants: [{ citizenid: "X3", name: "R. Vance" }] },
            { id: "LINCOLN-2", channel: 30112, freq: "127.125", occupants: [] },
        ],
        profile: {
            citizenid: "CIT88012", firstname: "Marcus", lastname: "Delgado", dob: "1989-03-14", gender: 0,
            nationality: "USA", phone: "555-0142", job: { label: "Civilian", grade: "Freelancer" }, gang: { label: "Vago Kings" },
            bloodtype: "O-", licences: { driver: false, weapon: false }, notes: "Known to frequent Dockside Row.",
            flags: ["VIOLENT", "ARMED"], image: "", online: true,
            vehicles: [{ plate: "KRT4402", vehicle: "Warrener GTS", garage: "downtown", state: 0, fuel: 80 }],
            convictions: [{ id: 1, charges: [{ code: "PR-06", label: "Armed Robbery", fine: 5000, sentence: 45 }], fine: 5000, sentence: 45, officer_name: "K. Reyes", created: "2026-07-02 21:40" }],
            warrants: [{ id: 12, reason: "Armed Robbery — PR-06", status: "active", author_name: "K. Reyes", created: "2026-07-02 22:00" }],
            incidents: [{ id: 7, title: "Robbery — Meridian Savings", author_name: "K. Reyes", created: "2026-07-02 21:50" }],
        },
        calls: [
            { id: 4471, code: "10-71", title: "Shots Fired", details: "Multiple callers report 6-8 gunshots near the fish market.", priority: 1, status: "pending", units: [], coords: { x: 100, y: 200, z: 30 }, created: "2026-07-07 21:42" },
            { id: 4470, code: "10-90", title: "Bank Alarm — Silent", details: "Silent alarm triggered at teller station 2.", priority: 2, status: "active", units: [{ citizenid: "X", callsign: "KING-7" }], coords: null, created: "2026-07-07 21:38" },
            { id: 4467, code: "10-16", title: "Civil Dispute", details: "Landlord/tenant dispute over property access.", priority: 3, status: "pending", units: [], coords: null, created: "2026-07-07 21:04" },
        ],
        units: [
            { citizenid: "OFC1", name: "K. Reyes", callsign: "NO CALLSIGN", role: "police", grade: "Officer", status: "available" },
            { citizenid: "X3", name: "R. Vance", callsign: "LINCOLN-1", role: "police", grade: "Sergeant", status: "onscene" },
            { citizenid: "X2", name: "D. Mercer", callsign: "ADAM-1", role: "police", grade: "Officer", status: "busy" },
        ],
        bolos: [
            { id: 1, bolo_type: "person", identifier: "CIT88012", title: 'Marcus "Saint" Delgado', description: "Armed robbery suspect. Last seen Dockside Row heading north. Considered armed and dangerous.", priority: 1, image: "", status: "active", author_name: "Det. Ames", created: "2026-07-07 20:00" },
            { id: 2, bolo_type: "vehicle", identifier: "KRT4402", title: "KRT-4402 — Warrener GTS", description: "Getaway vehicle in the Meridian Savings robbery. Matte black, loud exhaust.", priority: 1, image: "", status: "active", author_name: "Det. Ames", created: "2026-07-07 20:05" },
            { id: 3, bolo_type: "vehicle", identifier: "QRX7810", title: "QRX-7810 — Blista", description: "Hit & run on Meridian Ave. Front-end damage, missing mirror.", priority: 2, image: "", status: "active", author_name: "KING-7", created: "2026-07-07 15:00" },
        ],
        warrants: [{ id: 12, citizenid: "CIT88012", reason: "Armed Robbery — PR-06", status: "active", author_name: "K. Reyes", created: "2026-07-02" }],
        reports: [
            { id: 7, title: "Robbery — Meridian Savings & Loan", author_name: "K. Reyes", created: "2026-07-02 21:50" },
            { id: 6, title: "Stolen Vehicle — KRT-4402", author_name: "D. Mercer", created: "2026-07-02 20:10" },
        ],
    };
    window.__previewRpc = (req) => {
        const { action, reqId } = req;
        let payload = {};
        try { payload = JSON.parse(req.payload || "{}"); } catch (e) { payload = {}; }
        let data = { ok: true };
        if (action === "search") data = { ok: true, citizens: [{ citizenid: "CIT88012", name: "Marcus Delgado", dob: "1989-03-14", job: "Civilian" }], vehicles: [{ plate: "KRT4402", model: "Warrener GTS", owner_cid: "CIT88012" }] };
        else if (action === "getProfile") data = { ok: true, profile: demo.profile };
        else if (action === "getCalls") data = { ok: true, calls: demo.calls, units: demo.units };
        else if (action === "getBolos") data = { ok: true, bolos: demo.bolos };
        else if (action === "getWarrants") data = { ok: true, warrants: demo.warrants };
        else if (action === "getIncidents") data = { ok: true, incidents: demo.reports };
        else if (action === "getIncident") data = { ok: true, incident: { id: payload.id, title: demo.reports[0].title, details: "On 07/02 at approx 21:14, units responded to a 10-90...", author_name: "K. Reyes", created: "2026-07-02", links: [{ link_type: "citizen", identifier: "CIT88012", label: "Marcus Delgado" }, { link_type: "vehicle", identifier: "KRT4402", label: "Warrener GTS" }], convictions: [] } };
        else if (action === "getVehicle") data = { ok: true, vehicle: { plate: "KRT4402", fakeplate: null, model: "Warrener GTS", garage: "downtown", state: 0, fuel: 80 }, owner: { citizenid: "CIT88012", name: "Marcus Delgado" }, bolos: [demo.bolos[1]] };
        else if (action === "saveIncident") data = { ok: true, id: payload.id || 8 };
        else if (action === "processArrest") data = { ok: true, fine: 5000, sentence: 45 };
        else if (action === "joinUnit") {
            demo.unitBoard.forEach(u => { u.occupants = u.occupants.filter(o => o.citizenid !== "OFC1"); });
            const slot = demo.unitBoard.find(u => u.id === payload.unit);
            if (slot) slot.occupants.push({ citizenid: "OFC1", name: "K. Reyes" });
            data = { ok: true, unit: payload.unit, channel: slot ? slot.channel : 0, freq: slot ? slot.freq : "", unitBoard: demo.unitBoard };
        }
        else if (action === "leaveUnit") {
            demo.unitBoard.forEach(u => { u.occupants = u.occupants.filter(o => o.citizenid !== "OFC1"); });
            data = { ok: true, unitBoard: demo.unitBoard };
        }
        else if (action === "getUnitBoard") data = { ok: true, unitBoard: demo.unitBoard };
        setTimeout(() => window.postMessage({ name: "mdt:response", args: [{ reqId, action, data }] }, "*"), 120);
    };
    setTimeout(() => {
        window.postMessage({
            name: "mdt:open",
            args: [{
                ok: true, role: "police",
                officer: { citizenid: "OFC1", name: "K. Reyes", callsign: "NO CALLSIGN", grade: "Officer", job: "Law Enforcement", supervisor: true },
                bulletins: [{ id: 1, title: "Vago Kings activity up 40% in Old Town", content: "Increased presence requested on the Dockside corridor between 20:00-04:00.", author_name: "Det. Ames", author_cid: "X", created: "2026-07-07 18:20" }],
                units: demo.units,
                unitBoard: demo.unitBoard,
                penalCode: [
                    { category: "Offenses Against Persons", charges: [{ code: "P-01", label: "Assault", class: "misdemeanor", fine: 250, sentence: 10 }, { code: "P-05", label: "Murder", class: "felony", fine: 10000, sentence: 120 }] },
                    { category: "Offenses Against Property", charges: [{ code: "PR-06", label: "Armed Robbery", class: "felony", fine: 5000, sentence: 45 }] },
                ],
                priorities: { 1: { label: "Emergency" }, 2: { label: "Priority" }, 3: { label: "Routine" } },
                statuses: ["available", "busy", "enroute", "onscene", "unavailable"],
            }],
        }, "*");
    }, 300);
}
