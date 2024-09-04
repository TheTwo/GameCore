local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local NM = ModuleRefer.NotificationModule
local NotificationType = require('NotificationType')
---@class UIPetIconTableViewCellData : CommonPetIconBaseData
---@field hp number
---@field maxHp number

---@class UIPetIconTableViewCell : BaseTableViewProCell
local UIPetIconTableViewCell = class('UIPetIconTableViewCell', BaseTableViewProCell)

function UIPetIconTableViewCell:ctor()

end

function UIPetIconTableViewCell:OnCreate()
    ---@see CommonPetIconBaseData
    self._comp = self:LuaObject("child_card_pet_circle")
    if self._comp == nil then
        self._comp = self:LuaObject("child_card_pet_s")
    end
    ---@see NotificationNode
    self._redDot = self:LuaObject("child_reddot_default")

    self.sliderTroopHp = self:Slider("p_troop_hp")
    self.textTroopHp = self:Text("p_text_hp")

    -- 推荐图标
    self.p_icon_recomment = self:GameObject('p_icon_recomment')

end

function UIPetIconTableViewCell:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PET_REFRESH_UNLOCK_STATE, Delegate.GetOrCreate(self, self.OnChangeState))
    g_Game.EventManager:AddListener(EventConst.PET_REFRESH_SELECT, Delegate.GetOrCreate(self, self.Select))
end

function UIPetIconTableViewCell:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PET_REFRESH_UNLOCK_STATE, Delegate.GetOrCreate(self, self.OnChangeState))
    g_Game.EventManager:RemoveListener(EventConst.PET_REFRESH_SELECT, Delegate.GetOrCreate(self, self.Select))
end

---@param data UIPetIconTableViewCellData
function UIPetIconTableViewCell:OnFeedData(data)
    self.data = data
    self.selected = data.selected
    if (self._comp) then
        self._comp:FeedData(data)
    end
    if (self._redDot) then
        local node = ModuleRefer.PetModule:GetPetRedDot(data.id)
        if (node) and ModuleRefer.TroopModule:GetPetBelongedTroopIndex(data.id) ~= 0 then
            NM:AttachToGameObject(node, self._redDot.go,self._redDot.redDot)
            self._redDot:SetVisible(true)
        else
            self._redDot:SetVisible(false)
        end
    end
    if (self.sliderTroopHp and self.textTroopHp) then
        local hp = data.hp
        local maxHp = data.maxHp
        self.sliderTroopHp.value = hp / maxHp
        self.textTroopHp.text = string.format("%d / %d", hp, maxHp)
    end
end

function UIPetIconTableViewCell:OnChangeState(petId)
    if (self._comp and self.data and self.data.id == petId) then
        self._comp:FeedData(self.data)
    end
end

function UIPetIconTableViewCell:Select()
    self.selected = true
    self._comp:OnSelect()
end

function UIPetIconTableViewCell:UnSelect()
    self.selected = false
    self._comp:OnUnselect()
end

return UIPetIconTableViewCell;
