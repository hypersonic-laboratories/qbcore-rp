Config = Config or {}

Config.TickMs = 250
Config.Debug = false

Config.CreateVolumeActors = true
Config.VolumeActorClass = '/QuietRuntimeEditor/Common/Features/ScaleTool/BP_ShellVolume.BP_ShellVolume_C'
Config.VolumeClusterClass = '/QuietRuntimeEditor/Common/Features/ScaleTool/BP_ShellVolumeCluster.BP_ShellVolumeCluster_C'

Config.DefaultBoxHeight = 200.0
Config.DefaultPolyHeight = 200.0

Config.Creator = {
    Enabled = true,
    StartKey = 'F7',
    AddPointKey = 'F8',
    FinishKey = 'F9',
    PrintZoneName = 'new_zone',
    VerticalPadding = 100.0,
    Preview = true,
    PointRadius = 17.5,
    EdgeThickness = 4.0,
    EdgeHeight = 4.0,
    CircleSegments = 32,
}
