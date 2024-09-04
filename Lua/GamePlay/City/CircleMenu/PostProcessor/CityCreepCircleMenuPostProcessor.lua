---@class CityCreepCircleMenuPostProcessor
local CityCreepCircleMenuPostProcessor = {}
local I18N = require("I18N")

---@param cellTile CityTileBase
---@param data TouchMenuUIDatum
---@return TouchMenuUIDatum
function CityCreepCircleMenuPostProcessor.PostData(cellTile, data)
    if not cellTile:IsPolluted() then
        return data
    end

    for _, page in ipairs(data.pages) do
        for button in page:Buttons() do
            button:SetEnable(false)
            button:SetOnClickDisable(CityCreepCircleMenuPostProcessor.ShowCreepToast)
        end
    end
    return data
end

---@private
function CityCreepCircleMenuPostProcessor.ShowCreepToast()
    local ModuleRefer = require("ModuleRefer")
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
    return true
end

return CityCreepCircleMenuPostProcessor