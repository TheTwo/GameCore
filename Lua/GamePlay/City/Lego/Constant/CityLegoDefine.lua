local CityLegoDefine = {
    BlockSize = 3
}

function CityLegoDefine.GetCoordHashCode(x, y, z)
    return (x * 1313 + y) * 1313 + z
end

function CityLegoDefine.GetWallHashCode(x, y, z, side)
    return (((x * 1313 + y) * 1313) + z) * 1313 + side
end

return CityLegoDefine