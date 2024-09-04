local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationGainPetCellParameter
---@field content string
---@field petConfigIds number[]

---@class AllianceVillageOccupationGainPetCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationGainPetCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationGainPetCell = class('AllianceVillageOccupationGainPetCell', BaseTableViewProCell)

AllianceVillageOccupationGainPetCell.CellCount = 3

function AllianceVillageOccupationGainPetCell:ctor()
    AllianceVillageOccupationGainPetCell.super.ctor(self)
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._itemCells = {}
end

function AllianceVillageOccupationGainPetCell:OnCreate(param)
    self._p_icon_pet = self:Image("p_icon_pet")
    self._p_text_pet = self:Text("p_text_pet")
    for i = 1, AllianceVillageOccupationGainPetCell.CellCount do
        ---@see CommonPetIconBaseData
        self._itemCells[i] = self:LuaBaseComponent(("child_card_pet_s_%d"):format(i))
    end
end

---@param data AllianceVillageOccupationGainPetCellParameter
function AllianceVillageOccupationGainPetCell:OnFeedData(data)
    self._p_text_pet.text = data.content
    local group = data.petConfigIds
    local itemCount = group and #group or 0
    local cellCount = #self._itemCells
    for i = 1, cellCount do
        self._itemCells[i]:SetVisible(i <= itemCount)
    end
    local showCount = math.min(itemCount, cellCount)
    for i = 1, showCount do
        ---@type UIPetIconData
        local parameter = {}
        parameter.cfgId = group[i]
        parameter.showMask = false
        local cfg = ModuleRefer.PetModule:GetPetCfg(parameter.cfgId)
        if cfg and cfg:SourceItemsLength() > 0 then
            parameter.onClick = function()
                local param = {
                    itemId = cfg:SourceItems(1),
                    itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
                }
                g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
            end
        end
        self._itemCells[i]:FeedData(parameter)
    end
end

return AllianceVillageOccupationGainPetCell