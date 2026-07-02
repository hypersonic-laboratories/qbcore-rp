Config = {
    Debug = true, -- print xray event flow for troubleshooting
    NearbyScanInterval = 2500, -- interval (ms) for rescanning the world to register newly spawned targets and sweep destroyed ones
    MaxDistance = 200, -- default interaction distance for options; also the focus (green outline) range
    DetectionDistance = 300, -- range at which targetable actors get the highlight outline
    HighlightColor = LinearColor(1.0, 0.0, 0.0, 1.0), -- color of objects when holding target key
    SelectColor = LinearColor(0.0, 1.0, 0.0, 1.0), -- color swaps to when hovering target
    InnerlineIntensity = 0.0, -- raising this will make the object change color, not just outline
    OutlineIntensity = 0.2, -- how thick the outline is
}

return Config
