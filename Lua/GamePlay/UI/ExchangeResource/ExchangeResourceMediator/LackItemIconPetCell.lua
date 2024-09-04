local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local PetCollectionEnum = require("PetCollectionEnum")

local LackItemIconPetCell = class('LackItemIconPetCell', BaseTableViewProCell)

function LackItemIconPetCell:OnCreate(param)
    self.btnItemResources = self:Button('', Delegate.GetOrCreate(self, self.OnBtnItemResourcesClicked))
    self.imgImgResourceUnselected = self:Image('p_group_unselected')
    self.imgImgResourceSelected = self:Image('p_group_selected')
    self.p_img_pet = self:Image('p_img_pet')
    ---@type UIPetWorkTypeComp
    self.child_type_pet_work = self:LuaObject("child_type_pet_work")
end

---@param data ExchangeResourceMediatorItemInfo
function LackItemIconPetCell:OnFeedData(data)
    self.data = data
    local itemCfg = ConfigRefer.Item:Find(data.id)
    local icon = itemCfg:Icon()
    if data.status ==  PetCollectionEnum.PetStatus.Lock then
        self.p_img_pet.color = CS.UnityEngine.Color(0, 0, 0, 0.5)
    else
        self.p_img_pet.color = CS.UnityEngine.Color(1, 1, 1, 1)
    end

    g_Game.SpriteManager:LoadSprite(icon, self.p_img_pet)

    local param = {icon = ModuleRefer.PetModule:GetPetWorkTypeIcon(data.petWorkType), level = data.petWorkTypeLevel}
    self.child_type_pet_work:FeedData(param)
end

function LackItemIconPetCell:OnBtnItemResourcesClicked()
    self:SelectSelf()
end

function LackItemIconPetCell:Select(param)
    self.imgImgResourceUnselected:SetVisible(false)
    self.imgImgResourceSelected:SetVisible(true)
    g_Game.EventManager:TriggerEvent(EventConst.EXCHANGE_RESOURCE_SELECT_ITEM, self.data)
end

function LackItemIconPetCell:UnSelect(param)
    self.imgImgResourceUnselected:SetVisible(true)
    self.imgImgResourceSelected:SetVisible(false)
end

return LackItemIconPetCell
