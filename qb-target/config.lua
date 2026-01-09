Config = {
	RaycastInterval = 100,                                -- interval for raycast checks (ms)
	RaycastStartOffset = 25.0,                            -- offset from camera to start raycast
	NearbyScanInterval = 1000,                             -- interval for nearby entity scans (ms)
	MaxDistance = 1000,                                   -- max distance for raycast
	HighlightColor = LinearColor(1.0, 0.0, 0.0, 1.0),     -- color of objects when holding target key
	SelectColor = LinearColor(0.0, 1.0, 0.0, 1.0),        -- color swaps to when hovering target
	InnerlineIntensity = 0.0,                             -- raising this will make the object change color, not just outline
	OutlineIntensity = 0.2,                               -- how thick the outline is
}

return Config
