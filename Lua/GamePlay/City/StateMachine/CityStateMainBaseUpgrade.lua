local CityState = require("CityState")
---@class CityStateMainBaseUpgrade:CityState
---@field new fun():CityStateMainBaseUpgrade
local CityStateMainBaseUpgrade = class("CityStateMainBaseUpgrade", CityState)
local UIMediatorNames = require("UIMediatorNames")
local CityConst = require("CityConst")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local UIAsyncDataProvider = require("UIAsyncDataProvider")

function CityStateMainBaseUpgrade:Enter()
    self.furniture = self.stateMachine:ReadBlackboard("furniture")
    g_Game.UIManager:CloseByName(UIMediatorNames.CityLegoBuildingUIMediator)

    local camera = self.city:GetCamera()
    if camera then
        camera.enableDragging = false
        camera.enablePinch = false
    end

    g_Game.EventManager:AddListener(EventConst.UI_MEDIATOR_CLOSED, Delegate.GetOrCreate(self, self.OnMainBaseUpgradeUIClosed))
    g_Game.UIManager:Open(UIMediatorNames.CityMainBaseUpgradeUIMediator, self.furniture)

    self.continuousCheckHasCitizenCelebrate = true
    self.hasCitizenCelebrate = false
end

function CityStateMainBaseUpgrade:Tick(delta)
    if self.continuousCheckHasCitizenCelebrate then
        self.hasCitizenCelebrate = self.hasCitizenCelebrate or self.city.cityCitizenManager:GetForSignForVillageUpgradeCitizenCount() > 0
    end

    if self.delay then
        self.delay = self.delay - delta
        if self.delay <= 0 then
            self:ExitToIdleState()
        end
    end
end

function CityStateMainBaseUpgrade:OnMainBaseUpgradeUIClosed(uiName)
    if uiName ~= UIMediatorNames.CityMainBaseUpgradeUIMediator then return end

    self.continuousCheckHasCitizenCelebrate = false
    if self.hasCitizenCelebrate then
        self.delay = CityConst.MAIN_BASE_BLOCK_SCREEN_TIME or 2
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_main_bui_upgrade_citizen_1"))
    else
        self:ExitToIdleState()
    end
end

function CityStateMainBaseUpgrade:Exit()
    g_Game.EventManager:RemoveListener(EventConst.UI_MEDIATOR_CLOSED, Delegate.GetOrCreate(self, self.OnMainBaseUpgradeUIClosed))
    local camera = self.city:GetCamera()
    if camera then
        camera.enableDragging = true
        camera.enablePinch = true
    end

    -- local chatNpcCall = 0
    -- for _, cfg in ConfigRefer.NewBaseUpgradeUIData:ipairs() do
    --     if cfg:Level() == self.furniture.level then
    --         local npcId = cfg:ChatNpcCall()
    --         if npcId and npcId > 0 then
    --             chatNpcCall = npcId
    --             break
    --         end
    --     end
    -- end

    self.furniture = nil
    self.delay = nil

    -- if chatNpcCall > 0 then
        -- g_Game.UIManager:Open(UIMediatorNames.QuestEventUIMediator, {chatNpcId = chatNpcCall, isNew = true})
        -- ---@type UIAsyncDataProvider
        -- local provider = UIAsyncDataProvider.new()
        -- local mediatorName = UIMediatorNames.QuestEventUIMediator
        -- local check = UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
        -- provider:Init(mediatorName, nil, check, nil, false, {chatNpcId = chatNpcCall, isNew = true})
        -- provider:AddOtherMediatorWhiteList(UIMediatorNames.NewFunctionUnlockMediator)
        -- g_Game.UIAsyncManager:AddAsyncMediator(provider)
    -- else
        --- 触发引导系统中主基地升级的全屏对话流程
        -- g_Game.EventManager:TriggerEvent(EventConst.CITY_MAIN_BASE_FURNITURE_LEVEL_UP_FOR_GUIDE)
    -- end
end

return CityStateMainBaseUpgrade