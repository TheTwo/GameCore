local ModuleRefer = require("ModuleRefer")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local UIMediatorNames = require("UIMediatorNames")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class TMCellRewardPet:BaseTableViewProCell
---@field new fun():TMCellRewardPet
---@field super BaseTableViewProCell
local TMCellRewardPet = class('TMCellRewardPet', BaseTableViewProCell)

TMCellRewardPet.PetCellCount = 3

function TMCellRewardPet:ctor()
    TMCellRewardPet.super.ctor(self)
    ---@type CS.DragonReborn.UI.LuaBaseComponent[]
    self._itemCells = {}
end

function TMCellRewardPet:OnCreate(param)
    self._p_icon_pet = self:Image("p_icon_pet")
    self._p_text_pet = self:Text("p_text_pet")
    for i = 1, TMCellRewardPet.PetCellCount do
        ---@see CommonPetIconBaseData
        self._itemCells[i] = self:LuaBaseComponent(("child_card_pet_s_%d"):format(i))
    end
end

---@param data TMCellRewardPetDatum
function TMCellRewardPet:OnFeedData(data)
    self.data = data
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
        parameter.level = 0
        parameter.rank = 0
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

return TMCellRewardPet