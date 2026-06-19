# qb-zones

PolyZone-style client zones for HELIX/QB scripts.

`qb-zones` checks the local player's position on a timer and supports box, sphere, circle, polygon, combo, and box-volume cluster zones. Cluster zones also create `BP_ShellVolumeCluster` / `BP_ShellVolume` actors by default so they line up with the volume pattern used by `qb-houses`.

## Box

```lua
exports['qb-zones']:AddBoxZone('bank_counter', Vector(563550, 561761, 4570), 300, 180, {
    heading = 90.0,
    height = 200.0,
    debug = true,
    onEnter = function(zone)
        print('entered ' .. zone.name)
    end,
    onExit = function(zone)
        print('left ' .. zone.name)
    end,
})
```

## Polygon

```lua
exports['qb-zones']:AddPolyZone('odd_room', {
    Vector(0, 0, 4500),
    Vector(600, 0, 4500),
    Vector(800, 300, 4500),
    Vector(200, 600, 4500),
}, {
    minZ = 4400,
    maxZ = 4700,
    onPointInOut = function(isInside, point, zone)
        print(zone.name, isInside, point.X, point.Y, point.Z)
    end,
})
```

## Volume Cluster

```lua
exports['qb-zones']:AddClusterZone('l_shaped_room', {
    {
        type = 'box',
        center = Vector(1000, 1000, 4500),
        length = 700,
        width = 250,
        height = 220,
    },
    {
        type = 'box',
        center = Vector(1300, 1350, 4500),
        length = 250,
        width = 700,
        height = 220,
    },
}, {
    debug = true,
    data = { room = 'living' },
    enterEvent = 'my-resource:client:enteredLivingRoom',
    exitEvent = 'my-resource:client:leftLivingRoom',
})
```

## Helpers

```lua
local inside = exports['qb-zones']:IsPointInside('l_shaped_room', GetEntityCoords(GetPlayerPawn()))
local zones = exports['qb-zones']:GetPlayerZones()
exports['qb-zones']:SetZoneDebug('l_shaped_room', true)
exports['qb-zones']:RemoveZone('l_shaped_room')
```

## In-Game Creator

The creator is enabled by default in `config.lua`.

- `F7`: start a new zone and save the first point at your current coords.
- `F8`: add another point at your current coords.
- `F9`: finish and print a pasteable `AddPolyZone` snippet.

While active, the creator draws temporary visible sphere components at each point and thin connector components between points. Debug zones draw visible components: boxes use a box extent, spheres use a sphere component, and circles/polygons use perimeter wall segments from `minZ` to `maxZ` when a vertical range is provided.
