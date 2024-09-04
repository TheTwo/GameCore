---@childScene:scene_child_hud_construction_manage/scene_child_hud_map_function
local BaseUIComponent = require ('BaseUIComponent')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIMediatorNames = require("UIMediatorNames")
local CityManageCenterUIParameter = require("CityManageCenterUIParameter")
local CityWorkHelper = require("CityWorkHelper")
local NotificationType = require("NotificationType")
local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")
local DBEntityPath = require("DBEntityPath")
local CityWorkType = require("CityWorkType")
local QueuedTask = require("QueuedTask")
local I18N = require("I18N")

---@class CityManageHudComponent:BaseUIComponent
local CityManageHudComponent = class('CityManageHudComponent', BaseUIComponent)

local ManageCenterState = {
    EggHatchFinished = 1,
    FreeFurLvUpQueue = 2,
    FreeHatchEggQueue = 3,
    HungryEmoji = 4,
}

function CityManageHudComponent:OnCreate()
    self._p_btn_construction = self:Button("p_btn_construction", Delegate.GetOrCreate(self, self.OnClick))
    self._child_reddot_default = self:GameObject("child_reddot_default")
    self._child_status_free = self:GameObject("child_status_free")
    self._p_icon = self:Image("p_icon")

    ---队列信息角标
    ---@type CommonPairsQuantity
    self._p_quantity = self:LuaObject("p_quantity")

    ---饥饿提示信息
    self._p_popup_hint = self:GameObject("p_popup_hint")
    self._p_text_hint = self:Text("p_text_hint")
end

function CityManageHudComponent:OnShow()
    self:AttachNotifyPoint()
    if not self:TryShowOverviewButton() then
        g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.OnFunctionListOpened))
    end
    local city = ModuleRefer.CityModule.myCity
    self:UpdateManageCenterButtonState(city)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemCountChange))
end

function CityManageHudComponent:OnHide()
    self:DetachNotifyPoint()
    g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.OnFunctionListOpened))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemCountChange))
end

---@param city City
function CityManageHudComponent:UpdateManageCenterButtonState(city)
    local state, param1, param2 = self:GetManageCenterState(city)
    self.state = state
    if self.state == ManageCenterState.EggHatchFinished then
        self:HideFoot()
        self:UpdateHatchEggFinishedIcon(param1)
        self:ShowHatchEggFinishedHint()
    elseif self.state == ManageCenterState.FreeFurLvUpQueue then
        self:ShowLvUpQueueFoot(param1, param2)
        self:UpdateLvUpIcon()
        self:HideTextHint()
    elseif self.state == ManageCenterState.FreeHatchEggQueue then
        self:ShowHatchEggFoot(param1, param2)
        self:UpdateHatchEggIcon()
        self:HideTextHint()
    else
        self:HideFoot()
        self:UpdateHungryEmojiIcon(city)
        self:UpdateHungryHint(city)
    end
end

function CityManageHudComponent:OnClick()
    local city = ModuleRefer.CityModule.myCity
    if not city then return end

    if self.state == ManageCenterState.EggHatchFinished then
        local furnitures = city.furnitureManager:GetFurnituresByWorkType(CityWorkType.Incubate)
        for i, furniture in ipairs(furnitures) do
            local castleFurniture = furniture:GetCastleFurniture()
            if castleFurniture and castleFurniture.ProcessInfo.FinishNum > 0 then
                if city.showed then
                    furniture:TryOpenHatchEggUI()
                    local camera = city:GetCamera()
                    if camera then
                        camera:LookAt(furniture:CenterPos(), 0.5)
                    end
                else
                    g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
                        local queueTask = QueuedTask.new()
                        queueTask:WaitTrue(function()
                            return city ~= nil and city.showed
                        end):DoAction(function()
                            self:OnClick()
                        end):Start()
                    end)
                end
                return
            end
        end
    end

    if self.state == ManageCenterState.FreeFurLvUpQueue then
        local furniture = city.furnitureManager:GetAnyCanLevelUpFurniture(true, true)
        if furniture then
            if city.showed then
                furniture:TryOpenLvUpUI()
                local camera = city:GetCamera()
                if camera then
                    camera:LookAt(furniture:CenterPos(), 0.5)
                end
            else
                g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
                    local queueTask = QueuedTask.new()
                    queueTask:WaitTrue(function()
                        return city ~= nil and city.showed
                    end):DoAction(function()
                        self:OnClick()
                    end):Start()
                end)
            end
            return
        end
    end

    if self.state == ManageCenterState.FreeHatchEggQueue then
        local furnitures = city.furnitureManager:GetFurnituresByWorkType(CityWorkType.Incubate)
        for _, furniture in ipairs(furnitures) do
            local castleFurniture = furniture:GetCastleFurniture()
            if castleFurniture and castleFurniture.ProcessInfo.ConfigId == 0 then
                if city.showed then
                    furniture:TryOpenHatchEggUI()
                    local camera = city:GetCamera()
                    if camera then
                        camera:LookAt(furniture:CenterPos(), 0.5)
                    end
                else
                    g_Game.EventManager:TriggerEvent(EventConst.HUD_RETURN_TO_MY_CITY, function()
                        local queueTask = QueuedTask.new()
                        queueTask:WaitTrue(function()
                            return city ~= nil and city.showed
                        end):DoAction(function()
                            self:OnClick()
                        end):Start()
                    end)
                end
                return
            end
        end
    end
    
    local param = CityManageCenterUIParameter.new(city)
    g_Game.UIManager:Open(UIMediatorNames.CityManageCenterUIMediator, param)
end

function CityManageHudComponent:AttachNotifyPoint()
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityWorkHelper.GetNotifyRootName(), NotificationType.CITY_FURNITURE_OVERVIEW, self._child_reddot_default, self._child_reddot_default)
end

function CityManageHudComponent:DetachNotifyPoint()
    ModuleRefer.NotificationModule:RemoveFromGameObject(self._child_reddot_default, true)
end

function CityManageHudComponent:TryShowOverviewButton()
    local entryCfg = ConfigRefer.SystemEntry:Find(90)
    if entryCfg == nil then
        self._p_btn_construction:SetVisible(true)
        return true
    end

    local isUnlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(90)
    self._p_btn_construction:SetVisible(isUnlocked)
    return isUnlocked
end

function CityManageHudComponent:OnFunctionListOpened(list)
    for i, v in ipairs(list) do
        if v == 90 then
            self._p_btn_construction:SetVisible(true)
            g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.OnFunctionListOpened))
            return
        end
    end
end

---@param city City
function CityManageHudComponent:UpdateHungryEmojiIcon(city)
    if not city or not city:IsMyCity() then return end

    if self:AnyPetExaustedOrHungry(city) then
        return g_Game.SpriteManager:LoadSprite("sp_hud_icon_management_3", self._p_icon)
    end

    local remainTime = city.petManager:GetRemainFoodCanAffordTime()
    local maxTime = ConfigTimeUtility.NsToSeconds(ConfigRefer.CityConfig:MaxOfflineWorkTime())
    if remainTime >= maxTime then
        return g_Game.SpriteManager:LoadSprite("sp_hud_icon_management_1", self._p_icon)
    else
        return g_Game.SpriteManager:LoadSprite("sp_hud_icon_management_2", self._p_icon)
    end
end

function CityManageHudComponent:ShowHatchEggFinishedHint()
    self._p_popup_hint:SetVisible(true)
    self._p_text_hint.text = I18N.Get("work_finish_tips")
end

function CityManageHudComponent:HideTextHint()
    self._p_popup_hint:SetVisible(false)
end

---@param city City
function CityManageHudComponent:GetManageCenterState(city)
    if not city or not city:IsMyCity() then return ManageCenterState.HungryEmoji end

    local hatchEggFinished, furniture = self:IsAnyEggHatchFinished(city)
    if hatchEggFinished then
        return ManageCenterState.EggHatchFinished, furniture
    end

    local lvUpQueueCount = city.furnitureManager:GetUpgradeQueueMaxCount()
    local lvUpCount = city.cityWorkManager:GetWorkingCountByType(CityWorkType.FurnitureLevelUp)
    if lvUpCount < lvUpQueueCount then
        if city.furnitureManager:GetAnyCanLevelUpFurniture(true) then
            return ManageCenterState.FreeFurLvUpQueue, lvUpCount, lvUpQueueCount
        end
    end

    local hatchEggFurnitures = city.furnitureManager:GetFurnituresByWorkType(CityWorkType.Incubate)
    local hatchEggQueueCount = #hatchEggFurnitures
    local hatchEggCount = 0
    for i, furniture in ipairs(hatchEggFurnitures) do
        local castleFurniture = furniture:GetCastleFurniture()
        if castleFurniture and castleFurniture.ProcessInfo.ConfigId > 0 then
            hatchEggCount = hatchEggCount + 1
        end
    end
    if hatchEggCount < hatchEggQueueCount then
        local FunctionClass = require("FunctionClass")
        if ModuleRefer.InventoryModule:GetAmountByFunctionClass(FunctionClass.OpenPetEgg) > 0 then
            return ManageCenterState.FreeHatchEggQueue, hatchEggCount, hatchEggQueueCount
        end
    end
    
    return ManageCenterState.HungryEmoji
end

---@param city City
function CityManageHudComponent:UpdateHungryHint(city)
    if not city or not city:IsMyCity() then return end

    self._p_popup_hint:SetActive(self:AnyPetExaustedOrHungry(city))
    self._p_text_hint.text = I18N.Get("animal_work_alert")
end

---@param city City
function CityManageHudComponent:AnyPetExaustedOrHungry(city)
    for _, petDatum in pairs(city.petManager.cityPetData) do
        if petDatum:IsHungry() or petDatum:IsExhausted() then
            return true
        end
    end
    return false
end

---@param castleBrief wds.CastleBrief
function CityManageHudComponent:OnFurnitureUpdate(castleBrief, changeTable)
    local city = ModuleRefer.CityModule:GetMyCity()
    self:UpdateManageCenterButtonState(city)
end

function CityManageHudComponent:ShowLvUpQueueFoot(cur, max)
    self._p_quantity:SetVisible(true)
    self._child_status_free:SetActive(true)
    self._p_quantity:FeedData({
        itemIcon = "sp_comp_icon_build",
        num1 = ("%d"):format(cur),
        num2 = ("/%d"):format(max),
    })
end

function CityManageHudComponent:ShowHatchEggFoot(cur, max)
    self._p_quantity:SetVisible(true)
    self._child_status_free:SetActive(true)
    self._p_quantity:FeedData({
        itemIcon = "sp_comp_icon_egg",
        num1 = ("%d"):format(cur),
        num2 = ("/%d"):format(max),
    })
end

function CityManageHudComponent:HideFoot()
    self._p_quantity:SetVisible(false)
    self._child_status_free:SetActive(false)
end

function CityManageHudComponent:OnItemCountChange()
    if self.state == ManageCenterState.HungryEmoji then
        local city = ModuleRefer.CityModule:GetMyCity()
        self:UpdateManageCenterButtonState(city)
    end
end

---@param city City
function CityManageHudComponent:IsAnyEggHatchFinished(city)
    if not city or not city:IsMyCity() then return false end

    local hatchEggFurnitures = city.furnitureManager:GetFurnituresByWorkType(CityWorkType.Incubate)
    for i, furniture in ipairs(hatchEggFurnitures) do
        local castleFurniture = furniture:GetCastleFurniture()
        if castleFurniture and castleFurniture.ProcessInfo.FinishNum > 0 then
            return true, furniture
        end
    end

    return false
end

---@param furniture CityFurniture
function CityManageHudComponent:UpdateHatchEggFinishedIcon(furniture)
    local castleFurniture = furniture:GetCastleFurniture()
    if castleFurniture then
        local processInfo = castleFurniture.ProcessInfo
        local processCfg = ConfigRefer.CityWorkProcess:Find(processInfo.ConfigId)
        if processCfg then
            local output = ConfigRefer.Item:Find(processCfg:Output())
            if output then
                g_Game.SpriteManager:LoadSprite(output:Icon(), self._p_icon)
            end
        end
    end
end

function CityManageHudComponent:UpdateLvUpIcon()
    g_Game.SpriteManager:LoadSprite("sp_comp_icon_build", self._p_icon)
end

function CityManageHudComponent:UpdateHatchEggIcon()
    g_Game.SpriteManager:LoadSprite("sp_comp_icon_egg", self._p_icon)
end

return CityManageHudComponent