local I18N = require('I18N')
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")

---@class LandformPetProbabilityMediatorParameter
---@field landCfgId number @LandConfigCell Id

---@class LandformPetProbabilityMediator:BaseUIMediator
---@field new fun():LandformPetProbabilityMediator
---@field super BaseUIMediator
local LandformPetProbabilityMediator = class('LandformPetProbabilityMediator', BaseUIMediator)

---@param param LandformPetProbabilityMediatorParameter
function LandformPetProbabilityMediator:OnCreate(param)
    self.landCfgId = param.landCfgId

    self.txtTitle = self:Text('p_text_title', 'bw_info_petrarerange')
    self.txtDesc = self:Text('p_text_detail', 'bw_info_circle_petrange_des')
    self.tableInfo = self:TableViewPro('p_table')
end

function LandformPetProbabilityMediator:OnShow(param)
    self:RefreshUI()
end

function LandformPetProbabilityMediator:OnHide(param)

end

function LandformPetProbabilityMediator:RefreshUI()
    local landCfgCell = ConfigRefer.Land:Find(self.landCfgId)

    self.tableInfo:Clear()

    local colorCount = landCfgCell:PetRangeIconLength()
    local iconCount = landCfgCell:PetRangeIconLength()
    local typeCount = landCfgCell:PetRangeTypeLength()
    local propCount = landCfgCell:PetRangePropLength()
    if colorCount ~= iconCount or colorCount ~= typeCount or colorCount ~= propCount then
        g_Logger.Error('colorCount %s iconCount %s typeCount %s propCount %s', colorCount, iconCount, typeCount, propCount)
        return
    end

    for i = 1, landCfgCell:PetRangeIconLength() do
        ---@type LandformPetProbabilityCellData
        local cellData = {}
        cellData.colorKey = landCfgCell:PetRangeColor(i)
        cellData.imagePath = landCfgCell:PetRangeIcon(i)
        cellData.content = landCfgCell:PetRangeType(i)
        cellData.probability = landCfgCell:PetRangeProp(i)
        self.tableInfo:AppendData(cellData)
    end
end

return LandformPetProbabilityMediator