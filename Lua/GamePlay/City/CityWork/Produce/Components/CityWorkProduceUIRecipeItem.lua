local BaseTableViewProCell = require ('BaseTableViewProCell')
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@class CityWorkProduceUIRecipeItem:BaseTableViewProCell
---@field starItemIconData StarItemIconData
---@field _uiMediator CityWorkProduceUIMediator
local CityWorkProduceUIRecipeItem = class('CityWorkProduceUIRecipeItem', BaseTableViewProCell)

function CityWorkProduceUIRecipeItem:OnCreate()
    ---@type StarItemIcon
    self._child_item_star_s = self:LuaObject("child_item_star_s")
    self._p_item_auto = self:GameObject("p_item_auto")
end

---@param data {cfg:CityProcessConfigCell, uiMediator:CityLegoBuildingUIPage_Produce}
function CityWorkProduceUIRecipeItem:OnFeedData(data)
    self._data = data.cfg
    self._resCfg = ConfigRefer.CityElementResource:Find(self._data:GenerateResType())
    self._uiMediator = data.uiMediator

    self.starItemIconData = self.starItemIconData or {}
    self.starItemIconData.starCount = self._resCfg:Star()
    self.starItemIconData.itemIconData = self.starItemIconData.itemIconData or {}

    local itemIconData = self.starItemIconData.itemIconData
    itemIconData.customImage = self._resCfg:Icon()
    itemIconData.customQuality = self._resCfg:Quality()
    itemIconData.showTips = false
    itemIconData.showCount = false
    itemIconData.showSelect = self._uiMediator.selectedRecipe ~= nil and self._data:Id() == self._uiMediator.selectedRecipe:Id()
    itemIconData.onClick = Delegate.GetOrCreate(self, self.OnClick)
    itemIconData.locked = not self._uiMediator.city.cityWorkManager:IsProcessEffective(self._data)
    self._child_item_star_s:FeedData(self.starItemIconData)

    self._p_item_auto:SetActive(self._uiMediator.showAuto and self._uiMediator:IsProducing(self._data:Id()))
    self:TryAddEventListener()
end

function CityWorkProduceUIRecipeItem:OnRecycle()
    self:TryRemoveEventListener()
end

function CityWorkProduceUIRecipeItem:OnClose()
    self:TryRemoveEventListener()
end

function CityWorkProduceUIRecipeItem:TryAddEventListener()
    if self.added then return end

    self.added = true
    g_Game.EventManager:AddListener(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
end

function CityWorkProduceUIRecipeItem:TryRemoveEventListener()
    if not self.added then return end

    self.added = false
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
end

---@param recipe CityProcessConfigCell
function CityWorkProduceUIRecipeItem:OnRecipeSelected(recipe)
    self.starItemIconData.itemIconData.showSelect = self._data:Id() == recipe:Id()
    self._child_item_star_s:FeedData(self.starItemIconData)
end

function CityWorkProduceUIRecipeItem:OnClick()
    if not self._data then return end
    if self._uiMediator.selectedRecipe ~= nil and self._data:Id() == self._uiMediator.selectedRecipe:Id() then return end
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, self._data)
end

return CityWorkProduceUIRecipeItem