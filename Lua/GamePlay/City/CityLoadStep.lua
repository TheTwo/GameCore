local CityLoadStep = {
    NONE            = 0x00,
    ROOT            = 0x01,
    MAP_GRID_VIEW   = 0x02,
    FOG             = 0x04,
    CREEP           = 0x08,
    SAFE_AREA       = 0x10,
    SLICE_BIN       = 0x20,
}
CityLoadStep.ALL = table.sumValues(CityLoadStep)
return CityLoadStep