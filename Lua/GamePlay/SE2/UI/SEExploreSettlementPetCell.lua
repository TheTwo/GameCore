local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class SEExploreSettlementPetCellData
---@field itemConfig ItemConfigCell

---@class SEExploreSettlementPetCell:BaseTableViewProCell
---@field new fun():SEExploreSettlementPetCell
---@field super BaseTableViewProCell
local SEExploreSettlementPetCell = class('SEExploreSettlementPetCell', BaseTableViewProCell)

function SEExploreSettlementPetCell:OnCreate()
    ---@type CommonPetIcon
    self._child_card_pet_s = self:LuaObject("child_card_pet_s")
end

---@param data SEExploreSettlementPetCellData
function SEExploreSettlementPetCell:OnFeedData(data)
    local itemConfig = data.itemConfig
    local useParamLength = itemConfig:UseParamLength()
    if useParamLength < 2 then
        return
    end
    ---@type CommonPetIconBaseData
    local petData = {}
    petData.id = nil
    petData.cfgId = tonumber(itemConfig:UseParam(1))
    petData.level = tonumber(itemConfig:UseParam(2))
    if useParamLength > 2 then
        ---@type PetSkillLevelQuality
        local oneSkillLv = {}
        oneSkillLv.level = tonumber(itemConfig:UseParam(3))
        oneSkillLv.quality = ConfigRefer.Pet:Find(petData.cfgId):Quality()
        petData.skillLevels = {oneSkillLv}
    end
    self._child_card_pet_s:FeedData(petData)
end

return SEExploreSettlementPetCell