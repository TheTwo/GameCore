local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local Utils = require("Utils")
local I18N = require("I18N")
local ProtocolId = require("ProtocolId")
local NotificationType = require("NotificationType")
local LandformTaskModule = require("LandformTaskModule")

local Vector2 = CS.UnityEngine.Vector2
local Vector2Short = CS.DragonReborn.Vector2Short
local Vector3Short = CS.DragonReborn.Vector3Short

---@class LandformIntroUIMediatorParam
---@field entryLandCfgId number

---@class LandformIntroUIMediator : BaseUIMediator
---@field landformLayers table<number, CS.UnityEngine.UI.Image>
---@field infoPanel LandformInfoPanel
---@field tilesPerMapX number
---@field tilesPerMapZ number
---@field currentLandformID number
---@field currentTab number
local LandformIntroUIMediator = class("LandformIntroUIMediator", BaseUIMediator)

local TabInfo = 1
local TabTask = 2

function LandformIntroUIMediator:OnCreate(param)
    ---@type LandformMap
    self.p_landform_map = self:LuaObject("p_landform_map")
    ---@type LandformInfoPanel
    self.p_group_basic = self:LuaObject("p_group_basic")
    ---@type LandformTaskPanel
    self.p_group_task = self:LuaObject("p_group_task")

    self.p_text_title = self:Text("p_text_title")
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClicked))
    self.p_text_goto = self:Text("p_text_goto", "world_qianwang")
    self.p_text_hint = self:Text("p_text_hint")
    self.p_on_basic = self:GameObject("p_on_basic")
    self.p_off_basic = self:GameObject("p_off_basic")
    self.p_text_on_basic = self:Text("p_text_on_basic", "landtask_info_information")
    self.p_text_off_basic = self:Text("p_text_off_basic", "landtask_info_information")
    self.p_on_task = self:GameObject("p_on_task")
    self.p_off_task = self:GameObject("p_off_task")
    self.p_lock_task = self:GameObject("p_lock_task")
    self.p_text_on_task = self:Text("p_text_on_task", "landtask_info_task")
    self.p_text_off_task = self:Text("p_text_off_task", "landtask_info_task")
    self.p_text_lock_task = self:Text("p_text_lock_task", "landtask_info_task")
    self.p_btn_basic = self:Button("p_btn_basic", Delegate.GetOrCreate(self, self.OnInfoClicked))
    self.p_btn_task = self:Button("p_btn_task", Delegate.GetOrCreate(self, self.OnTaskClicked))
    self.p_table_landform = self:TableViewPro("p_table_landform")
    ---@type NotificationNode
    self.child_reddot_default = self:LuaObject("child_reddot_default")
end

---@param param LandformIntroUIMediatorParam
function LandformIntroUIMediator:OnShow(param)
    local landformConfigID
    if param and param.entryLandCfgId then
        landformConfigID = param.entryLandCfgId
    else
        local castle = ModuleRefer.PlayerModule:GetCastle()
        local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(castle.MapBasics.Position)
        landformConfigID = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
    end
    
    local index = 0 
    local selectedIndex = 0
    local baseID = KingdomMapUtils.GetStaticMapData():GetBaseId()
    self.p_table_landform:Clear()
    for _, config in ConfigRefer.Land:ipairs() do
        local id = config:Id()
        if not KingdomMapUtils.CheckMapID(id, baseID) then
            goto continue
        end
        if not ModuleRefer.LandformModule:IsValidLandform(id) then
            goto continue
        end
        ---@type LandformSelectCellData
        local data = 
        {
            landformConfigID = id,
            isLocked = not ModuleRefer.LandformModule:IsLandformSystemUnlock(id),
            clickCallback = Delegate.GetOrCreate(self, self.OnLandformCellSelected),
        }
        self.p_table_landform:AppendData(data)
        if id == landformConfigID then
            selectedIndex = index
        end
        index = index + 1
        ::continue::
    end
    self.p_table_landform:RefreshAllShownItem()
    self.p_table_landform:SetToggleSelectIndex(selectedIndex)
    
    ModuleRefer.LandformTaskModule:RefreshNotifications()

    self.currentTab = TabInfo
    self:SelectLandform(landformConfigID)
    
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.LandActivityGetReward, Delegate.GetOrCreate(self, self.OnResponseClaimReward))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self,self.OnSecond))
end

function LandformIntroUIMediator:OnHide(param)
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.LandActivityGetReward, Delegate.GetOrCreate(self, self.OnResponseClaimReward))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self,self.OnSecond))

    local landformConfig = ConfigRefer.Land:Find(self.currentLandformID)
    if landformConfig then
        ModuleRefer.NotificationModule:RemoveFromGameObject(self.child_reddot_default.go, false)
    end
end

function LandformIntroUIMediator:OnSecond()
    local ok, tip = ModuleRefer.LandformModule:GetLandformOpenHint(self.currentLandformID, true)
    self.p_text_hint.text = tip
end

function LandformIntroUIMediator:SelectLandform(landformConfigID)
    local lastLandformConfig = self.currentLandformID and ConfigRefer.Land:Find(self.currentLandformID)
    self.currentLandformID = landformConfigID
    local landformConfig = ConfigRefer.Land:Find(landformConfigID)
    self.p_text_title.text = I18N.Get(landformConfig:Name())

    local ok, tip = ModuleRefer.LandformModule:GetLandformOpenHint(self.currentLandformID, true)
    self.p_text_hint.text = tip

    self:RefreshMap(landformConfigID)
    if self.currentTab == TabInfo then
        self:OnInfoClicked()
    else
        if ModuleRefer.LandformModule:IsLandformSystemUnlock(landformConfigID) then
            self:OnTaskClicked()
        else
            self:OnInfoClicked()
        end
    end

    --if lastLandformConfig then
    --    ModuleRefer.NotificationModule:RemoveFromGameObject(self.child_reddot_default.go, false)
    --end
    local layer = landformConfig:LayerNum()
    local currentNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(LandformTaskModule.NotifyTabUniqueName .. layer, NotificationType.LANDFORM_TASK_MAIN)
    ModuleRefer.NotificationModule:AttachToGameObject(currentNode, self.child_reddot_default.go, self.child_reddot_default.redDot)
end

function LandformIntroUIMediator:OnLandformCellSelected(landformConfigID)
    self:SelectLandform(landformConfigID)
end

function LandformIntroUIMediator:OnGotoClicked()
    ModuleRefer.LandformModule:GotoLandform(self.currentLandformID)
end

function LandformIntroUIMediator:OnInfoClicked()
    local landformUnlocked = ModuleRefer.LandformModule:IsLandformSystemUnlock(self.currentLandformID)
    self.currentTab = TabInfo
    self:SelectInfo(true)
    self:SelectTask(false, landformUnlocked)
    self:RefreshInfo(self.currentLandformID)
end

function LandformIntroUIMediator:OnTaskClicked()
    local landformUnlocked = ModuleRefer.LandformModule:IsLandformSystemUnlock(self.currentLandformID)
    if landformUnlocked then
        self.currentTab = TabTask
        self:SelectInfo(false)
        self:SelectTask(true, landformUnlocked)
        self:RefreshTask(self.currentLandformID)
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("land_toast_task_unlock"))
    end
end

function LandformIntroUIMediator:SelectInfo(state)
    self.p_on_basic:SetVisible(state)
    self.p_off_basic:SetVisible(not state)
    self.p_group_basic:SetVisible(state)
end

function LandformIntroUIMediator:SelectTask(state, unlocked)
    self.p_lock_task:SetVisible(not unlocked)
    self.p_on_task:SetVisible(state and unlocked)
    self.p_off_task:SetVisible(not state and unlocked)
    self.p_group_task:SetVisible(state and unlocked)
end

function LandformIntroUIMediator:RefreshMap(landformConfigID)
    --local startDistrictID = ModuleRefer.PlayerModule:GetBornDistrictId()
    --local unlockedDistricts = ModuleRefer.TerritoryModule:GetOpenedDistrictsForMe(startDistrictID)
    ----local unlockedDistricts = {200001,200006,200008}
    -----@type CS.DragonReborn.Range2Int
    --local range
    --for _, districtID in ipairs(unlockedDistricts) do
    --    if not range then
    --        range = ModuleRefer.TerritoryModule:GetDistrictRange(districtID)
    --    else
    --        local other = ModuleRefer.TerritoryModule:GetDistrictRange(districtID)
    --        range:Encapsulate(other)
    --    end
    --end
    --
    -----@type LandformMapParameter
    --local landMapParam =
    --{
    --    startSelectLandformConfigID = landformConfigID,
    --    showMyCastle = true,
    --    unlockedDistricts = unlockedDistricts,
    --    rectXMin = range.xMin,
    --    rectXMax = range.xMax,
    --    rectYMin = range.yMin,
    --    rectYMax = range.yMax,
    --}

    
    local startDistrictID = ModuleRefer.PlayerModule:GetBornDistrictId()
    local unlockedDistricts = ModuleRefer.TerritoryModule:GetOpenedDistrictsForMe(startDistrictID)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    ---@type LandformMapParameter
    local landMapParam =
    {
        startSelectLandformConfigID = landformConfigID,
        showMyCastle = true,
        unlockedDistricts = unlockedDistricts,
        rectXMin = 0,
        rectXMax = staticMapData.TilesPerMapX,
        rectYMin = 0,
        rectYMax = staticMapData.TilesPerMapZ,
    }
    self.p_landform_map:FeedData(landMapParam)
end

function LandformIntroUIMediator:RefreshInfo(landformConfigID)
    ---@type LandformInfoPanelParameter
    local landformInfoData = 
    {
        landCfgId = landformConfigID,
    }
    self.p_group_basic:FeedData(landformInfoData)
end

function LandformIntroUIMediator:RefreshTask(landformConfigID)
    local activityInfo = ModuleRefer.LandformTaskModule:GetActivityInfo(landformConfigID)
    ---@type LandformTaskParameter
    local parameter = 
    {
        landformConfigID = landformConfigID,
        activityInfo = activityInfo,
    }
    self.p_group_task:FeedData(parameter)
end

function LandformIntroUIMediator:OnResponseClaimReward()
    if self.currentTab == TabInfo then
        self:RefreshInfo(self.currentLandformID)
    else
        self:RefreshTask(self.currentLandformID)
    end
end

return LandformIntroUIMediator