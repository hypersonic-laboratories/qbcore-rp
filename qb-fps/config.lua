Config = {}

-- Command that toggles the menu. Type it in the console as "/fps".
Config.Command = 'fps'

-- Show a notification each time a preset is applied.
Config.NotifyOnApply = true

-- Re-apply the player's saved settings when they load in (runtime cvars reset
-- each launch, so this restores their last choice every session).
Config.ReapplyOnLoad = true

-- ─────────────────────────────────────────────────────────────────────────
-- CVARS
-- Each entry is a rendering console variable the menu can drive at runtime.
--   cvar     the console variable name
--   label    shown in the Advanced tab
--   desc     one-line explanation
--   type     'bool'  -> on/off toggle
--            'scalar'-> numeric slider (min/max/step)
--            'enum'  -> dropdown (options list)
--   default  the game's stock value (used by the Quality preset / Reset)
-- ONLY runtime-applicable cvars belong here. Boot-only cvars (Nanite streaming
-- pool, Lumen surface-cache atlas size, initial root pages) cannot be changed
-- after launch and must go in the launch option instead (see README).
-- ─────────────────────────────────────────────────────────────────────────
Config.Cvars = {
    {
        cvar = 'r.RayTracing.Enable', label = 'Ray Tracing', type = 'bool', default = 1,
        desc = 'Hardware ray tracing. Off frees the ray-tracing acceleration structures (~700MB VRAM).',
    },
    {
        cvar = 'r.Lumen.HardwareRayTracing', label = 'Hardware Lumen', type = 'bool', default = 1,
        desc = 'Hardware-accelerated Lumen GI/reflections. Off falls back to software Lumen (needs Ray Tracing on).',
    },
    {
        cvar = 'r.LumenScene.FarField', label = 'Lumen Far Field', type = 'bool', default = 1,
        desc = 'Very-long-distance GI tracing. Off has almost no visual impact in dense areas.',
    },
    {
        cvar = 'r.Shadow.Virtual.MaxPhysicalPages', label = 'Shadow Pool', type = 'enum', default = 4096,
        desc = 'Virtual shadow map physical page pool. Lower = less VRAM, softer distant shadows.',
        options = {
            { label = 'Low (2048)', value = 2048 },
            { label = 'Medium (3072)', value = 3072 },
            { label = 'High (4096)', value = 4096 },
        },
    },
    {
        cvar = 'r.VT.PoolSizeScale', label = 'Virtual Texture Pool', type = 'scalar', default = 1.0,
        desc = 'Virtual texture pool size multiplier. Lower saves VRAM, more texture streaming.',
        min = 0.5, max = 1.0, step = 0.1,
    },
    {
        cvar = 'r.Streaming.PoolSize', label = 'Texture Pool (MB)', type = 'enum', default = 5000,
        desc = 'Texture streaming pool. On low-VRAM cards a smaller pool avoids paging to system RAM.',
        options = {
            { label = '1500 MB (8GB GPU)', value = 1500 },
            { label = '3000 MB (10-12GB GPU)', value = 3000 },
            { label = '5000 MB (12GB+ GPU)', value = 5000 },
        },
    },
    {
        cvar = 'r.Streaming.LimitPoolSizeToVRAM', label = 'Clamp Pool to VRAM', type = 'bool', default = 0,
        desc = 'Force the texture pool to fit inside available VRAM. Recommended On for low-VRAM cards.',
    },
    {
        cvar = 'r.ScreenPercentage', label = 'Resolution Scale', type = 'scalar', default = 100,
        desc = 'Internal render resolution percent. Lower = big FPS gain, softer image (upscaler resolves it).',
        min = 50, max = 100, step = 5,
    },
}

-- ─────────────────────────────────────────────────────────────────────────
-- PRESETS
-- A preset is a map of cvar -> value. The Advanced tab tweaks the same cvars
-- individually. The Performance preset targets 8GB GPUs on heavy maps.
-- ─────────────────────────────────────────────────────────────────────────
Config.Presets = {
    {
        id = 'quality',
        label = 'Quality',
        icon = 'sparkles',
        desc = 'Stock settings. Best visuals. Needs a 12GB+ GPU on heavy maps.',
        values = {
            ['r.RayTracing.Enable'] = 1,
            ['r.Lumen.HardwareRayTracing'] = 1,
            ['r.LumenScene.FarField'] = 1,
            ['r.Shadow.Virtual.MaxPhysicalPages'] = 4096,
            ['r.VT.PoolSizeScale'] = 1.0,
            ['r.Streaming.PoolSize'] = 5000,
            ['r.Streaming.LimitPoolSizeToVRAM'] = 0,
            ['r.ScreenPercentage'] = 100,
        },
    },
    {
        id = 'balanced',
        label = 'Balanced',
        icon = 'gauge',
        desc = 'Keeps ray tracing and Lumen GI. Trims shadow, VT and texture pools. ~10GB GPU.',
        values = {
            ['r.RayTracing.Enable'] = 1,
            ['r.Lumen.HardwareRayTracing'] = 1,
            ['r.LumenScene.FarField'] = 0,
            ['r.Shadow.Virtual.MaxPhysicalPages'] = 3072,
            ['r.VT.PoolSizeScale'] = 0.8,
            ['r.Streaming.PoolSize'] = 3000,
            ['r.Streaming.LimitPoolSizeToVRAM'] = 1,
            ['r.ScreenPercentage'] = 100,
        },
    },
    {
        id = 'performance',
        label = 'Performance',
        icon = 'zap',
        desc = 'Ray tracing and Lumen GI off, pools minimised. Runs heavy maps on an 8GB GPU.',
        values = {
            ['r.RayTracing.Enable'] = 0,
            ['r.Lumen.HardwareRayTracing'] = 0,
            ['r.LumenScene.FarField'] = 0,
            ['r.Shadow.Virtual.MaxPhysicalPages'] = 2048,
            ['r.VT.PoolSizeScale'] = 0.6,
            ['r.Streaming.PoolSize'] = 1500,
            ['r.Streaming.LimitPoolSizeToVRAM'] = 1,
            ['r.ScreenPercentage'] = 100,
        },
    },
}

-- Order presets appear in the UI (left to right).
Config.PresetOrder = { 'quality', 'balanced', 'performance' }
