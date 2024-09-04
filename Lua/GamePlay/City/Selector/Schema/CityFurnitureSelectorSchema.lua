local schema = require("schema")
local CitySelectorSchema = require("CitySelectorSchema")

local CityFurnitureSelectorSchema = {
    {"arrowL", typeof(CS.UnityEngine.Transform)},
    {"arrowR", typeof(CS.UnityEngine.Transform)},
    {"arrowT", typeof(CS.UnityEngine.Transform)},
    {"arrowB", typeof(CS.UnityEngine.Transform)},
}

schema.append(CityFurnitureSelectorSchema, CitySelectorSchema)

return CityFurnitureSelectorSchema