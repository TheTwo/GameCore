local BaseTableViewProCell = require ('BaseTableViewProCell')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityWorkFormula = require("CityWorkFormula")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")

---@class CityWorkProcessUIRecipeFurnitureItem:BaseTableViewProCell
---@field uiMeidator CityWorkProcessUIMediator
local CityWorkProcessUIRecipeFurnitureItem = class('CityWorkProcessUIRecipeFurnitureItem', BaseTableViewProCell)

function CityWorkProcessUIRecipeFurnitureItem:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    self._p_frame_furniture = self:Image("p_frame_furniture")
    self._p_icon_furniture = self:Image("p_icon_furniture")
    self._button = self:Button("p_icon_furniture", Delegate.GetOrCreate(self, self.OnClick))
    self._child_img_select = self:GameObject("child_img_select")
    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

---@param data {recipe:CityProcessConfigCell, isEmpty:boolean, uiMediator:BaseUIComponent}
function CityWorkProcessUIRecipeFurnitureItem:OnFeedData(data)
    self.data = data
    self:RefreshEmpty(data.isEmpty)
    if not data.isEmpty then
        self.recipe = data.recipe
        self.uiMeidator = data.uiMediator
        self:Refresh()
        self:TryAddListener()
    end
end

function CityWorkProcessUIRecipeFurnitureItem:RefreshEmpty(isEmpty)
    self._statusRecord:ApplyStatusRecord(4)
    self._child_img_select:SetVisible(not isEmpty)
end

function CityWorkProcessUIRecipeFurnitureItem:Refresh()
    local status = self:GetStatus()
    self._statusRecord:ApplyStatusRecord(status)
    local customIcon = self.recipe:OutputIcon()
    local icon, background = string.Empty, string.Empty
    if string.IsNullOrEmpty(customIcon) then
        local itemGroup = ConfigRefer.ItemGroup:Find(self.recipe:Output())
        if itemGroup == nil then
            icon = "sp_icon_missing"
            background = ("sp_item_frame_%d"):format(1)
        else
            local output = CityWorkFormula.CalculateOutput(self.uiMeidator.workCfg, itemGroup, nil, self.uiMeidator.furnitureId, self.uiMeidator.citizenId)
            local firstOutput = output[1]
            local configCell = ConfigRefer.Item:Find(firstOutput.id)
            icon = configCell:Icon()
            background = ("sp_item_frame_%d"):format(configCell:Quality())
        end
    else
        icon = customIcon
        background = ("sp_item_frame_%d"):format(math.clamp(self.recipe:OutputQuality(), 1, 5))
    end
    self.showSelect = self.recipe == self.uiMeidator.selectedRecipe
    g_Game.SpriteManager:LoadSprite(icon, self._p_icon_furniture)
    g_Game.SpriteManager:LoadSprite(background, self._p_frame_furniture)
    self._child_img_select:SetVisible(self.showSelect)

    if self.showSelect then
        self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.OnEnable)
    end
end

function CityWorkProcessUIRecipeFurnitureItem:GetStatus()
    if self:ConditionNotMeet() then return 3 end

    local lvCfgId = self.uiMeidator:GetSelectRecipeOutputFurnitureLvCfgId(self.recipe)
    if lvCfgId == 0 then return 4 end

    local processCount, reachVersionLimit, versionLimitCount = self.uiMeidator.city.furnitureManager:GetFurnitureCanProcessCount(lvCfgId)
    if processCount > 0 then
        return 0
    else
        return reachVersionLimit and 2 or 1
    end
end

function CityWorkProcessUIRecipeFurnitureItem:OnClick()
    if self.data.isEmpty then return end
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, self.recipe)
end

function CityWorkProcessUIRecipeFurnitureItem:OnRecycle()
    self:TryRemoveListener()
end

function CityWorkProcessUIRecipeFurnitureItem:OnClose()
    self:TryRemoveListener()
end

function CityWorkProcessUIRecipeFurnitureItem:TryAddListener()
    if not self.evtListener then
        g_Game.EventManager:AddListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnSelectRecipeEvt))
        self.evtListener = true
    end
end

function CityWorkProcessUIRecipeFurnitureItem:TryRemoveListener()
    if self.evtListener then
        g_Game.EventManager:RemoveListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnSelectRecipeEvt))
        self.evtListener = nil
    end
end

---@param recipe CityProcessConfigCell
function CityWorkProcessUIRecipeFurnitureItem:OnSelectRecipeEvt(recipe)
    local showSelect = self.recipe == recipe and recipe ~= nil
    self.showSelect = showSelect
    self._child_img_select:SetVisible(showSelect)
end

function CityWorkProcessUIRecipeFurnitureItem:ConditionNotMeet()
    return not self.uiMeidator.city.cityWorkManager:IsProcessEffective(self.recipe)
end

return CityWorkProcessUIRecipeFurnitureItem