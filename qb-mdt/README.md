# qb-mdt

Mobile Data Terminal for HELIX — a shared police + EMS tablet. Job-agnostic:
any job whose `type` maps to a role in `Config.Roles` gets the MDT, themed and
scoped per department (police see the penal code, warrants and BOLOs; EMS see
patients, medical records and advisories).

Open with **F5** (`Config.OpenKey`) while on duty.

## Features

- **Dashboard** — active calls, department stats, bulletins board, unit radios,
  units on duty.
- **Dispatch** — live call queue with priorities, call detail, create calls,
  waypoint to scene. Attaching/detaching moves your whole unit (crew ride
  together). Calls auto-close after `Config.CallRetentionHours`.
- **Units & radio** — officers connect to a unit slot (`ADAM-1`, `MEDIC-2`, …)
  from the dashboard or the topbar pill. Connecting sets the callsign and joins
  the unit's voice channel; partners on the same slot share a private frequency.
- **Citizens** — search by name/ID, full profile (licenses, vehicles, history),
  officer notes and flags.
- **Vehicles** — plate lookup with owner and BOLO cross-check.
- **Reports** — incident reports with linked people/vehicles, charge calculator
  backed by the penal code in `config.lua`, arrest processing (collects the
  fine, records the conviction, serves warrants).
- **Warrants & BOLOs** — issue/resolve, broadcast to the department.
- **Medical records** — EMS patient records (injuries, treatment, medications).
- **Panic button** — full-department alert with GPS fix and a RESPOND waypoint.
- **Supervisor log** — audit trail of MDT actions (grade-gated).

## Voice / radio model

HELIX voice keeps every player in the proximity channel; extra voice channels
are additive and global. The MDT uses one reserved channel per unit slot
(`Config.Units`, band 30101–30204 — clear of qb-radio dials, capped at 500, and
qb-phone calls, 50000+).

Crew stay in their unit channel permanently, so the radio is always audible.
The *speak* side is gated per listener: your voice is muted for crew members
beyond `Config.UnitProxRangeCm` unless you key up. In practice:

- **V** — talk normally: proximity only, far crew hear nothing.
- **CapsLock + V** (`Config.PttKey`) — transmit: proximity + radio. A HUD card
  shows who is on air with a live waveform (`HEvent:VoiceStateChanged`).

CapsLock alone cannot open the mic — the engine mic is V-gated and there is no
Lua API to force it.

## Integration points

| Hook | Direction | Purpose |
|---|---|---|
| `exports['qb-mdt']:CreateCall(data)` | in | feed dispatch from any resource |
| `qb-mdt:server:911` (event: message, coords, anonymous) | in | 911 calls (qb-phone) |
| `exports['qb-mdt']:IsWarranted(citizenid)` | out | warrant check (cuffs, ANPR) |
| `exports['qb-mdt']:GetVehicleBolo(plate)` | out | BOLO check (ANPR) |
| `exports['qb-mdt']:AddMedicalRecord(data)` | in | auto-record on revive |
| `qb-mdt:server:convictionProcessed` (local event) | out | jail bridge after arrest |

None of the consuming resources are wired yet — these are the seams.

## HELIX platform notes

Engineering constraints this resource is built around (they differ from FiveM):

- Engine `RegisterCallback`/`TriggerCallback` silently drop any callback whose
  name contains a colon (`res:action` style never fires; plain names work).
  All request/response therefore rides one plain-named callback (`mdtRpc`)
  dispatching to per-action handlers — see `MDT.RegisterRpc` in
  `server/main.lua` and `Rpc()` in `client/main.lua`.
- Nested JS objects do not survive `hEvent` into Lua: WebUI payloads are
  JSON-stringified client-side and parsed in the RPC dispatcher.
- An empty Lua table serializes to JSON `{}`, not `[]`: every list from the
  server is coerced with `toArr()` in `app.js` before use.
- A `nil` inside a `DatabaseAction` params array truncates it and the statement
  fails silently; params are always fully populated (`''`/`0`), and inserts are
  verified by re-selecting the newest matching row because
  `last_insert_rowid()` returns a stale id after a failed insert.
- `SetMetaData` writes don't survive the qb-core export boundary, so
  `MDT.Units` (server memory) is authoritative for callsigns while on duty.
- Keybinds fire while a WebUI has focus; binds are guarded with
  `HPlayer:GetInputMode()`.

## Known limitations

- Dispatch map is a placeholder grid — needs a top-down world image, two
  calibration coordinates and unit position sync.
- No dispatch/all-units broadcast role yet (multi-channel voice).
- Profile photos come from the qb-policejob mugshot station (pushed through
  `exports['qb-mdt']:SetProfileImage`); BOLO photos still need an `image` URL
  set by hand.
- Voice gating (mute-by-distance, PTT) still needs multiplayer testing.

## Development

`html/index.html?preview=1` in a browser runs a demo-data harness for UI work
(never active in game). The `?preview` flag gates an `hEvent` stub and fake
RPC responses in `app.js`.
