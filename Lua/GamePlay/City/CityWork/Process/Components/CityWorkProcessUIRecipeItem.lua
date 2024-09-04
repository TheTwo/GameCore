local BaseTableViewProCell = require ('BaseTableViewProCell')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityWorkFormula = require("CityWorkFormula")
local UIHelper = require("UIHelper")

---@class CityWorkProcessUIRecipeItem:BaseTableViewProCell
---@field uiMediator CityWorkProcessUIMediator
local CityWorkProcessUIRecipeItem = class('CityWorkProcessUIRecipeItem', BaseTableViewProCell)

function CityWorkProcessUIRecipeItem:OnCreate()
    ---@type BaseItemIcon
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
    self._p_item_empty = self:GameObject("p_item_empty")
    self.gameObject = self.CSComponent.gameObject
end

---@param data {recipe:CityProcessConfigCell, isEmpty:boolean, uiMediator:BaseUIComponent}
function CityWorkProcessUIRecipeItem:OnFeedData(data)
    self.data = data
    self:RefreshEmpty(data.isEmpty)
    if not data.isEmpty then
        self.recipe = data.recipe
        self.uiMediator = data.uiMediator
        self:Refresh()
        self:TryAddListener()
    end
end

function CityWorkProcessUIRecipeItem:RefreshEmpty(empty)
    self._p_item_empty:SetVisible(empty)
    self._child_item_standard_s:SetVisible(not empty)
end

function CityWorkProcessUIRecipeItem:Refresh()
    ---@type ItemIconData
    local itemData = {}
    local customIcon = self.recipe:OutputIcon()
    if string.IsNullOrEmpty(customIcon) then
        local itemGroup = ConfigRefer.ItemGroup:Find(self.recipe:Output())
        if itemGroup == nil then
            itemData.customImage = "sp_icon_missing"
            itemData.customQuality = 1
        else
            local output = CityWorkFormula.CalculateOutput(self.uiMediator.workCfg, itemGroup, nil, self.uiMediator.furnitureId, self.uiMediator.citizenId)
            local firstOutput = output[1]
            itemData.configCell = ConfigRefer.Item:Find(firstOutput.id)
        end
    else
        itemData.customImage = customIcon
        itemData.customQuality = 1
    end
    itemData.showSelect = self.recipe == self.uiMediator.selectedRecipe
    itemData.showCount = false
    itemData.onClick = Delegate.GetOrCreate(self, self.OnClickSelectRecipe)
    itemData.locked = self:ConditionNotMeet()
    self.itemData = itemData
    self._child_item_standard_s:FeedData(self.itemData)
end

function CityWorkProcessUIRecipeItem:OnRecycle()
    self:TryRemoveListener()
end

function CityWorkProcessUIRecipeItem:OnClose()
    self:TryRemoveListener()
end

function CityWorkProcessUIRecipeItem:TryAddListener()
    if not self.evtListener then
        g_Game.EventManager:AddListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnSelectRecipeEvt))
        self.evtListener = true
    end
end

function CityWorkProcessUIRecipeItem:TryRemoveListener()
    if self.evtListener then
        g_Game.EventManager:RemoveListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnSelectRecipeEvt))
        self.evtListener = nil
    end
end

function CityWorkProcessUIRecipeItem:OnClickSelectRecipe()
    if self.data.isEmpty then return end
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, self.recipe)
end

---@param recipe CityProcessConfigCell
function CityWorkProcessUIRecipeItem:OnSelectRecipeEvt(recipe)
    if not self.itemData then return end

    local showSelect = self.recipe == recipe and recipe ~= nil
    self.itemData.showSelect = showSelect
    self._child_item_standard_s:FeedData(self.itemData)
end

function CityWorkProcessUIRecipeItem:ConditionNotMeet()
    return not self.uiMediator.city.cityWorkManager:IsProcessEffective(self.recipe)
end

return CityWorkProcessUIRecipeItem