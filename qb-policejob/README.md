# qb-policejob

Police job for HELIX/QBCore: duty, interactions, evidence, fingerprints, CCTV, helicopter camera, ANPR, vehicle impound, licenses, trackers, and a booking-room mugshot station.

## Mugshot station

Officers photograph a suspect at a booking-room tripod. The photo uploads to an image host and is stored per citizen; other resources read it through an export.

How it works in game:

1. An officer targets the tripod ("Take Mugshot", LEO only) and gets a live viewfinder rendered from a fixed camera aimed at the height chart.
2. The suspect stands on the chart mark. The viewfinder shows their ID, name, DOB and gender once they are in frame, driven by a 1s server probe.
3. The officer can zoom (1.0x to 2.5x), nudge and re-aim the camera, and control a studio light (on/off, intensity, color temperature) from the viewfinder, by mouse or keyboard. `E` takes the photo, `R` resets zoom, `Backspace` or `Esc` cancels.
4. On capture the server records who is in frame at that moment, the PNG uploads in the background, and the photo is saved to that citizen with the photographing officer logged. If nobody is in frame, the officer is prompted for a citizen ID instead.

The subject is found with a ray test along the camera's line of sight: the player closest to the lens within `corridorCm` of the sight line wins, so a person standing behind the suspect cannot end up in the record.

### Reading mugshots from other resources

```lua
-- server: latest photo for a citizen, or nil
local shot = exports['qb-policejob']:GetMugshot(citizenid)
if shot then
    print(shot.url, shot.taken)
end
```

Every saved photo is also pushed to the MDT profile through `exports['qb-mdt']:SetProfileImage(citizenid, url)`. The call is wrapped in pcall, so servers without qb-mdt keep working and keep their full history in the `police_mugshots` table (citizen, URL, officer, timestamp; one row per photo).

### Adding a station

Run `/mugshotsetup` twice in game: once standing at the tripod facing the height chart, once standing on the chart mark. The command prints a finished station block for `Config.Mugshot.stations`:

```lua
{
    interact = Vector(562173, 570672, 4665),  -- tripod target
    camPos = Vector(562148, 570672, 4725),    -- lens position, at face height
    camRot = Rotator(0, -179.5, 0),           -- lens rotation, facing the chart
    stand = Vector(562013, 570678, 4654),     -- chart mark the suspect stands on
    corridorCm = 100,                         -- sight-line half-width for subject detection
    fov = 24,                                 -- frames head and shoulders at 1.6m
},
```

Uploads go to the endpoint in `Config.Mugshot.imageApi` (FiveManage by default); set your own API key there.
