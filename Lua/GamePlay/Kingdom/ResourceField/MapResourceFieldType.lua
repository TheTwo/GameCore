local MapResourceFieldType = {
    Woods = 1 << 0,
    Stones = 1 << 1,
    Food = 1 << 2,
    All = (1 << 3) - 1,
}
return MapResourceFieldType