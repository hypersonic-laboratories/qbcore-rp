# qb-fps

A client-side FPS and graphics menu for QBCore on HELIX. Players pick a
rendering preset, or tweak individual settings, to run heavy maps on GPUs with
less VRAM than the map wants. No config editing, no console commands to
memorize.

Everything runs on the client. These are per-player rendering console
variables: nothing goes to the server and there is no database. The player's
choice is saved on their machine and re-applied every session.

## Install

Add `qb-fps` to the `packages` list in your server's scripts `config.json`,
then restart or `/packagerefresh`. The package won't load without this.

## Usage

Type `/fps` in the console to open the menu. The command name is set by
`Config.Command`.

The Presets tab has three options:

- Quality: stock settings. Best visuals, wants a 12GB+ GPU on heavy maps.
- Balanced: keeps ray tracing and Lumen GI, trims the memory pools. Around 10GB.
- Performance: ray tracing and Lumen off, pools minimized. Runs on 8GB.

The Advanced tab exposes each setting individually with toggles and sliders.

## Why this exists

Some HELIX maps keep a very large GPU working set resident at all times. On a
GPU below the map's target VRAM, Windows pages GPU resources out to system
memory over PCIe, which shows up as sustained low FPS and stutter in dense
areas. The Performance preset shrinks the biggest consumers: ray-tracing
acceleration structures, Lumen, and the shadow, virtual-texture, and texture
streaming pools. Measured on one heavy map with an RTX 5060 8GB, tracked GPU
memory dropped from about 11.8GB to 8.4GB and the map became playable.

## What it can and cannot change at runtime

Three console variables only take effect at launch, so the menu leaves them
out (changing them live does nothing):

- `r.Nanite.Streaming.StreamingPoolSize`
- `r.Nanite.Streaming.NumInitialRootPages`
- `r.LumenScene.SurfaceCache.AtlasSize`

To get those too, add a launch option to the game. This is where the biggest
savings on 8GB cards come from:

```
-dpcvars="r.RayTracing.Enable=0,r.Lumen.HardwareRayTracing=0,r.LumenScene.FarField=0,r.LumenScene.SurfaceCache.AtlasSize=2048,r.Shadow.Virtual.MaxPhysicalPages=2048,r.VT.PoolSizeScale=0.6,r.Streaming.PoolSize=1500,r.Streaming.LimitPoolSizeToVRAM=1,r.Nanite.Streaming.StreamingPoolSize=384,r.Nanite.Streaming.NumInitialRootPages=3072"
```

Do not add `r.Nanite` as a runtime toggle. Turning Nanite off and back on
rebuilds every draw command under memory pressure and can crash the client.
That's why it isn't in the cvar list.

## Configuration

Everything lives in `config.lua`:

- `Config.Command`: command that opens the menu (default `fps`)
- `Config.NotifyOnApply`: toast when a preset is applied
- `Config.ReapplyOnLoad`: re-apply the saved choice on player load
- `Config.Cvars`: the runtime cvars the menu drives (label, type, default)
- `Config.Presets` and `Config.PresetOrder`: the preset definitions

To tune a preset, edit its `values` map. To add a setting to the Advanced tab,
add an entry to `Config.Cvars`, and to the preset `values` maps if presets
should drive it. Only add cvars that apply at runtime.

## Exports

```lua
exports['qb-fps']:ApplyPreset('performance') -- apply a preset by id
exports['qb-fps']:OpenMenu()
exports['qb-fps']:CloseMenu()
```

## Files

`config.lua` has the command name, key, cvar list, and presets. `client.lua`
opens the menu and applies cvars through `ExecuteConsoleCommand`. `html/` is
the WebUI (presets and advanced tabs, lucide icons).

Preset values come from profiling: memreport, the CSV profiler, and per-process
GPU memory logging.
