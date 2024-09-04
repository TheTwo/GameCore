local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local NpcServiceObjectType = require('NpcServiceObjectType')
local NpcServiceType = require('NpcServiceType')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityWorkUICostItemData = require("CityWorkUICostItemData")
local Delegate = require("Delegate")
local CityLegoI18N = require("CityLegoI18N")
local EventConst = require("EventConst")
local NpcServiceUnlockCondType = require("NpcServiceUnlockCondType")

local I18N = require("I18N")

---@class CityLegoBuildingUIPage_Repair:BaseUIComponent
local CityLegoBuildingUIPage_Repair = class('CityLegoBuildingUIPage_Repair', BaseUIComponent)

function CityLegoBuildingUIPage_Repair:OnCreate()
    self._p_building_name = self:GameObject("p_building_name")
    self._p_text_building_name = self:Text("p_text_building_name")

    self._p_scroll_content = self:GameObject("p_scroll_content")
    self._p_text_detail = self:Text("p_text_detail")

    self._p_title_need = self:GameObject("p_title_need")
    self._p_text_need = self:Text("p_text_need")

    self._p_resource_grid = self:Transform("p_resource_grid")
    self._p_item = self:LuaBaseComponent("p_item")
    self._cost_pool = LuaReusedComponentPool.new(self._p_item, self._p_resource_grid)

    ---@type BistateButtonSmall
    self._p_comp_btn_a_l_u2 = self:LuaObject("p_comp_btn_a_l_u2")

    self._p_condition_vertical = self:Transform("p_condition_vertical")
    self._p_title_condition = self:GameObject("p_title_condition")
    self._p_text_condition = self:Text("p_text_condition", "ui_service_con")
    ---@type CityWorkUIConditionItem
    self._p_conditions = self:LuaBaseComponent("p_conditions")
    self._condition_pool = LuaReusedComponentPool.new(self._p_conditions, self._p_condition_vertical)

    ---@type CityWorkUICostItemData[]
    self.inputDataList = {}
    ---@type CityWorkUICostItem[]
    self.inputItemList = {}
end

---@param furniture CityFurniture
function CityLegoBuildingUIPage_Repair:OnFeedData(furniture)
    self.furniture = furniture
    
    self._p_text_building_name.text = I18N.Get(ConfigRefer.CityFurnitureTypes:Find(furniture.furType):Name())
    self._p_text_detail.text = I18N.Get(ConfigRefer.CityFurnitureTypes:Find(furniture.furType):Description())

    self._cost_pool:HideAll()
    self.inputItemList = {}
    self:ReleaseAllItemCountListeners()
    local hasFixService, serviceId = self:HasFixService()
    if hasFixService then
        local commitItemMap = ModuleRefer.StoryPopupTradeModule:GetServicesInfo(NpcServiceObjectType.Furniture, self.furniture.singleId, serviceId)
        local needItemMap = ModuleRefer.StoryPopupTradeModule:GetNeedItems(serviceId)

        for i, v in ipairs(needItemMap) do
            local commitCount = commitItemMap[v.id] or 0
            local lackCount =  v.count - commitCount
            self.inputDataList[i] = CityWorkUICostItemData.new(v.id, lackCount)
            self.inputDataList[i]:AddCountListener(Delegate.GetOrCreate(self, self.OnItemCountChange))

            local item = self._cost_pool:GetItem()
            item:FeedData(self.inputDataList[i])
            self.inputItemList[i] = item
        end
    end
    self.hasFixServer = hasFixService

    local disableButtonText = I18N.Get(CityLegoI18N.UI_ButtonCantRepair)
    if serviceId ~= nil then
        local serviceCfg = ConfigRefer.NpcService:Find(serviceId)
        if serviceCfg then
            disableButtonText = I18N.Get(serviceCfg:Content())
        end
    end

    self._p_condition_vertical:SetVisible(not hasFixService)
    if not hasFixService then
        self._condition_pool:HideAll()
        local allMap = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.Furniture)
        local furnitureNpcServices = allMap[self.furniture.singleId] or {}
        local playerNpcService = furnitureNpcServices.Services or {}
        local NpcService = ConfigRefer.NpcService
        for serviceId, vStruct in pairs(playerNpcService) do
            local v = vStruct.State
            if wds.NpcServiceState.NpcServiceStateFinished == v then
                goto continue
            end
            if wds.NpcServiceState.NpcServiceStateBeLocked == v then
                local config = NpcService:Find(serviceId)
                if not config then
                    goto continue
                end
                local unlockCondCount = config:UnlockCondLength()
                for i = 1, unlockCondCount do
                    local unlockCond = config:UnlockCond(i)
                    local unlockType = unlockCond:UnlockCondType()
                    local condTask = unlockCond:UnlockCondParam()
                    if unlockType == NpcServiceUnlockCondType.FinishTask and condTask > 0 then
                        local preTaskConfig = ConfigRefer.Task:Find(condTask)
                        if preTaskConfig then
                            local item = self._condition_pool:GetItem()
                            item:FeedData({cfg = preTaskConfig, furniture = self.furniture})
                        end
                    end
                end
            end
            ::continue::
        end
    end
    
    if not self:IsItemEnough() then
        disableButtonText = I18N.Get(CityLegoI18N.UI_ButtonCantRepair)
    end

    ---@type BistateButtonSmallParam
    self.buttonData = self.buttonData or {}
    self.buttonData.buttonText = I18N.Get(CityLegoI18N.UI_ButtonRepair)
    self.buttonData.disableButtonText = disableButtonText
    self.buttonData.onClick = Delegate.GetOrCreate(self, self.OnClick)
    self.buttonData.disableClick = Delegate.GetOrCreate(self, self.OnClickDisable)
    self._p_comp_btn_a_l_u2:FeedData(self.buttonData)
    self._p_comp_btn_a_l_u2:SetEnabled(self.hasFixServer and self:IsItemEnough())
end

function CityLegoBuildingUIPage_Repair:OnShow()
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnUnlockChanged))
end

function CityLegoBuildingUIPage_Repair:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LOCK_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnUnlockChanged))
    self:ReleaseAllItemCountListeners()
end

function CityLegoBuildingUIPage_Repair:OnClose()
    self:OnHide()
end

function CityLegoBuildingUIPage_Repair:HasFixService()
    local serviceMap = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.Furniture)
    local serviceGroup = serviceMap[self.furniture.singleId]
    if not serviceGroup then return false, 0 end

    local isOnlyCommit, serviceId, _, _  = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(serviceGroup, NpcServiceType.CommitItem)
    return isOnlyCommit, serviceId
end

function CityLegoBuildingUIPage_Repair:ReleaseAllItemCountListeners()
    if not self.inputDataList then return end
    for _, v in ipairs(self.inputDataList) do
        v:ReleaseCountListener()
    end
end

function CityLegoBuildingUIPage_Repair:OnItemCountChange()
    for i, v in ipairs(self.inputItemList) do
        if self.inputDataList[i] then
            v:FeedData(self.inputDataList[i])
        end
    end

    self._p_comp_btn_a_l_u2:SetEnabled(self.hasFixServer)
end

function CityLegoBuildingUIPage_Repair:IsItemEnough()
    local enough = true
    for _, v in ipairs(self.inputDataList) do
        if v:GetCountNeed() > v:GetCountOwn() then
            enough = false
            break
        end
    end
    return enough
end

function CityLegoBuildingUIPage_Repair:OnClick()
    if self:IsItemEnough() then
        self.furniture:RequestToRepair(true)
    else
        local getmoreList = {}
        for i, v in ipairs(self.inputDataList) do
            if v:GetCountOwn() < v:GetCountNeed() then
                table.insert(getmoreList, {id = v.id, num = v:GetCountNeed() - v:GetCountOwn()})
            end
        end
        ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
    end
end

function CityLegoBuildingUIPage_Repair:OnClickDisable()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CityLegoI18N.UI_HintToastCantFix))
end

function CityLegoBuildingUIPage_Repair:OnUnlockChanged(city, batchEvt)
    if not self.furniture then return end
    if batchEvt.Change and batchEvt.Change[self.furniture.singleId] ~= nil then
        local uiMediator = self:GetParentBaseUIMediator()
        if uiMediator then
            uiMediator:ShowFurniturePage(self.furniture.singleId)
        end
    end
end

return CityLegoBuildingUIPage_Repair