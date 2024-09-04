local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local UIMediatorNames = require("UIMediatorNames")
local TimeFormatter = require("TimeFormatter")
local KingdomMapUtils = require("KingdomMapUtils")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryAllianceCenterCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryAllianceCenterCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryAllianceCenterCell = class('AllianceTerritoryMainSummaryAllianceCenterCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryAllianceCenterCell:ctor()
    AllianceTerritoryMainSummaryAllianceCenterCell.super.ctor(self)
    ---@type wds.MapBuildingBrief
    self._targetVillage = nil
    self._tabStatus = 0
    self._setAllianceCenterCDEndTime = nil
    self._needTriggerRefershUI = false
    self._inSecTick = false
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnCreate()
    self._p_text_league_center = self:Text("p_text_league_center", "alliance_center_title")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetailTip))
    self._p_text_power = self:Text("p_text_power")
    self._p_status_lock = self:GameObject("p_status_lock")
    self._p_text_lock = self:Text("p_text_lock", "alliance_center_lock")
    self._p_status_not_transform = self:GameObject("p_status_not_transform")
    self._p_text_lock_1 = self:Text("p_text_lock_1", "alliance_center_unlocked_nonecenter")
    ---@type BistateButton
    self._p_btn_transform = self:LuaObject("p_btn_transform")
    self._p_status_info = self:GameObject("p_status_info")
    self._p_text_cd_1 = self:Text("p_text_cd_1")

    self._p_icon_territory = self:Image("p_icon_territory")
    self._p_text_lv_territory = self:Text("p_text_lv_territory")
    self._p_text_name_new = self:Text("p_text_name_new", "alliance_center_title")
    self._p_text_name_old = self:Text("p_text_name_old")
    self._p_btn_click_go = self:Button("p_btn_click_go", Delegate.GetOrCreate(self, self.OnClickGoto))
    self._p_progress = self:Slider("p_progress")
    self._p_text_change = self:Text("p_text_change", "alliance_center_building")
    self._p_text_time = self:Text("p_text_time")
    self._p_text_position = self:Text("p_text_position")
    self._p_table_addtion = self:TableViewPro("p_table_addtion")
    self._p_text_hint = self:Text("p_text_hint", "alliance_center_buffoff")
    self._p_text = self:Text("p_text", "world_qiancheng")
    self._p_btn_move = self:Button("p_btn_move", Delegate.GetOrCreate(self, self.OnClickBtnMove))
    self._p_btn_change_another = self:Button("p_btn_change_another", Delegate.GetOrCreate(self, self.OnClickTransform))
    self._p_text_cd = self:Text("p_text_cd")
    ---@type NotificationNode
    self.child_reddot_move = self:LuaObject("child_reddot_move")
    self.p_btn_search = self:Button("p_btn_search", Delegate.GetOrCreate(self, self.OnClickSearchOrMoveVillage))
    self.p_text_search = self:Text('p_text_search')
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnFeedData(data)
    self:RefreshUI()
    self:CheckTriggerGuide()
    if Utils.IsNotNull(self.child_reddot_move) then
        local nm = ModuleRefer.NotificationModule
        nm:RemoveFromGameObject(self.child_reddot_move.go, false)
        local node = nm:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.TerritoryMoveCity, NotificationType.ALLIANCE_TERRITORY_CENTER_MOVE)
        nm:AttachToGameObject(node, self.child_reddot_move.go, self.child_reddot_move.redDot)
    end

    if self._p_status_lock.activeSelf then
        local isR4Above = ModuleRefer.AllianceModule:IsAllianceR4Above()
        if isR4Above then
            -- R4以上显示搜寻
            self.isR4Above = true
            self.p_btn_search:SetVisible(true)
            self.p_text_search.text = I18N.Get("Radar_info_search")
        else
            -- 普通玩家显示迁城
            self.isR4Above = false
            self.p_btn_search:SetVisible(true)
            self.p_text_search.text = I18N.Get("迁城")
        end
    end
end

function AllianceTerritoryMainSummaryAllianceCenterCell:RefreshUI()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self._setAllianceCenterCDEndTime = ModuleRefer.VillageModule:GetTransformAllianceCenterCdEndTime()
    if self._setAllianceCenterCDEndTime <= nowTime then
        self._setAllianceCenterCDEndTime = nil
    end
    self._p_text_cd:SetVisible(false)
    self._p_text_cd_1:SetVisible(false)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnMapBuildingChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnMapBuildingChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.BasicInfo.IsInAllianceCenter.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerInAllianceCenterStatusChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.BasicInfo.IsInAllianceCenter.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerInAllianceCenterStatusChanged))
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local hasAnyVillage = ModuleRefer.VillageModule:AllianceHasAnyVillage()
    if not hasAnyVillage then
        if allianceData.AllianceVillageWar.MaxLevel <= 0 then
            self._tabStatus = 0
            self._p_status_lock:SetVisible(true)
            self._p_status_not_transform:SetVisible(false)
            self._p_status_info:SetVisible(false)
            return
        end
    end
    self._p_text_lock_1.text = I18N.Get("alliance_center_unlocked_nonecenter")
    self._targetVillage = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    self._p_status_not_transform:SetVisible(self._targetVillage == nil)
    self._p_status_info:SetVisible(self._targetVillage ~= nil)
    self._p_status_lock:SetVisible(false)
    if not self._targetVillage then
        self._tabStatus = 1
        ---@type BistateButtonParameter
        local btnParam = {}
        if not hasAnyVillage then
            self._p_text_lock_1.text = I18N.Get("alliance_center_lock")
        end
        btnParam.buttonText = I18N.Get("alliance_center_unlocked_nonecenter_buildbtn")
        btnParam.onClick = Delegate.GetOrCreate(self, self.OnClickTransform)
        btnParam.disableClick = Delegate.GetOrCreate(self, self.OnClickTransformDisabled)
        self._p_btn_transform:FeedData(btnParam)
        self._p_btn_transform:SetEnabled(ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MakeOverAllianceCenter) and not self._setAllianceCenterCDEndTime and hasAnyVillage)
        if self._setAllianceCenterCDEndTime then
            self._p_text_cd:SetVisible(true)
            self._p_text_cd_1:SetVisible(true)
            g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
            if not self._inSecTick then
                self:OnSecTick(0)
            end
        end
        return
    end
    self._tabStatus = 2
    local fixedMapBuilding = ConfigRefer.FixedMapBuilding:Find(self._targetVillage.ConfigId)
    g_Game.SpriteManager:LoadSprite(fixedMapBuilding:Image(), self._p_icon_territory)
    self._p_text_lv_territory.text = tostring(fixedMapBuilding:Level())
    self._p_text_name_old.text = I18N.Get(fixedMapBuilding:Name())
    self._p_text_position.text = ("X:%d,Y:%d"):format(math.floor(self._targetVillage.Pos.X + 0.5), math.floor(self._targetVillage.Pos.Y + 0.5))

    self._p_table_addtion:Clear()
    local centerConfig = ConfigRefer.AllianceCenter:Find(fixedMapBuilding:BuildAllianceCenter())
    local addAttrGroup = ConfigRefer.AttrGroup:Find(centerConfig:AllianceAttrGroup())
    if not addAttrGroup or addAttrGroup:AttrListLength() <= 0 then
        return
    end
    ---@type {prefabIdx:number, cellData:{strLeft:string,strRight:string,icon:string}}[]
    local allianceGainAttr = {}
    for i = 1, addAttrGroup:AttrListLength() do
        local attrTypeAndValue = addAttrGroup:AttrList(i)
        ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, allianceGainAttr, true)
        local v = allianceGainAttr[1]
        allianceGainAttr[1] = nil
        self._p_table_addtion:AppendData(v.cellData)
    end
    local hasChangeAllianceCenterAuthority = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MakeOverAllianceCenter)
    local isUpgradeDone = self._targetVillage.AllianceCenterStatus >= wds.VillageTransformStatus.VillageTransformStatusDone
    if isUpgradeDone and self._targetVillage.Status ~= wds.BuildingStatus.BuildingStatus_GiveUping then
        self._p_btn_change_another:SetVisible(hasChangeAllianceCenterAuthority)
        if hasChangeAllianceCenterAuthority then
            if self._setAllianceCenterCDEndTime then
                UIHelper.SetGray(self._p_btn_change_another.gameObject, true)
                self._p_text_cd:SetVisible(true)
                self._p_text_cd_1:SetVisible(true)
                g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
                if not self._inSecTick then
                    self:OnSecTick(0)
                end
            else
                UIHelper.SetGray(self._p_btn_change_another.gameObject, false)
            end
        end
        self._p_progress:SetVisible(false)
        self._p_text_change:SetVisible(false)
        self._p_text_time:SetVisible(false)
        self._p_text_hint:SetVisible(true)
        self._p_btn_move:SetVisible(not self:IsOnAllianceCenterTerritory())
        if self:IsOnAllianceCenterTerritory() then
            self._p_text_hint.text = I18N.Get("alliance_center_buffon")
        else
            self._p_text_hint.text = I18N.Get("alliance_center_buffoff")
        end
    else
        if self._targetVillage.Status ~= wds.BuildingStatus.BuildingStatus_GiveUping then
            self._p_text_change.text = I18N.Get("alliance_center_building")
            self._p_btn_move:SetVisible(false)
            self._p_text.text = I18N.Get("world_qiancheng")
        else
            self._p_text_change.text = I18N.GetWithParams("village_info_giving_up", string.Empty)
            self._p_btn_move:SetVisible(ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.DeclareWarOnVillage))
            self._p_text.text = I18N.Get("cancle")
        end
        self._p_btn_change_another:SetVisible(hasChangeAllianceCenterAuthority)
        if hasChangeAllianceCenterAuthority then
            UIHelper.SetGray(self._p_btn_change_another.gameObject, true)
            self._p_text_cd:SetVisible(true)
            self._p_text_cd_1:SetVisible(true)
        end
        self._p_text_hint:SetVisible(false)
        self._p_progress:SetVisible(true)
        self._p_text_change:SetVisible(true)
        self._p_text_time:SetVisible(true)
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
        if not self._inSecTick then
            self:OnSecTick(0)
        end
    end
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnRecycle()
    self._tabStatus = 0
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnMapBuildingChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.BasicInfo.IsInAllianceCenter.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerInAllianceCenterStatusChanged))
    if Utils.IsNotNull(self.child_reddot_move) then
        local nm = ModuleRefer.NotificationModule
        nm:RemoveFromGameObject(self.child_reddot_move.go, false)
    end
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClose(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecTick))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.MapBuildingBriefs.MapBuildingBriefs.MsgPath, Delegate.GetOrCreate(self, self.OnMapBuildingChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.BasicInfo.IsInAllianceCenter.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerInAllianceCenterStatusChanged))
    if Utils.IsNotNull(self.child_reddot_move) then
        local nm = ModuleRefer.NotificationModule
        nm:RemoveFromGameObject(self.child_reddot_move.go, false)
    end
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClickDetailTip()
    ---@type TextToastMediatorParameter
    local param = {}
    param.title = I18N.Get("alliance_center_tips_title")
    param.content = I18N.Get("alliance_center_tips_content")
    param.clickTransform = self._p_btn_detail.transform
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClickGoto()
    AllianceWarTabHelper.GoToCoord(self._targetVillage.Pos.X, self._targetVillage.Pos.Y, true)
    self:GetParentBaseUIMediator():CloseSelf()
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClickBtnMove()
    if self._targetVillage.Status == wds.BuildingStatus.BuildingStatus_GiveUping then
        UIHelper.ShowConfirm(I18N.Get("village_check_cancel_waiver"), nil, function()
            ModuleRefer.VillageModule:DoCancelDropVillage(nil, self._targetVillage.EntityID)
        end)
        return
    end
    local layoutConfigId = ConfigRefer.FixedMapBuilding:Find(self._targetVillage.ConfigId):Layout()
    local coord = CS.DragonReborn.Vector2Short(math.floor(self._targetVillage.Pos.X + 0.5), math.floor(self._targetVillage.Pos.Y + 0.5))
    AllianceWarTabHelper.GoToCoord(self._targetVillage.Pos.X, self._targetVillage.Pos.Y, false, nil, nil, nil, function()
        local relocateCallBack = function()
            local relocateOffset = ConfigRefer.AllianceConsts:RelocateOffset()
            local sizeX, sizeY = KingdomMapUtils.GetLayoutSize(layoutConfigId)
            ModuleRefer.KingdomPlacingModule:SearchForAvailableRect(coord.X, coord.Y, 100, relocateOffset, sizeX, sizeY, function(ret, x, y)
                if ret then
                    local position = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x, y, KingdomMapUtils.GetMapSystem())
                    KingdomMapUtils.GetBasicCamera():LookAt(position)
                end
            end)
        end
        ModuleRefer.KingdomPlacingModule:StartRelocate(ModuleRefer.PlayerModule:GetCastle().MapBasics.ConfID, ModuleRefer.RelocateModule.CanRelocate, coord, relocateCallBack)
    end)
    self:GetParentBaseUIMediator():CloseSelf()
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnSecTick(dt)
    self._inSecTick = true
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if self._setAllianceCenterCDEndTime then
        local leftTime = self._setAllianceCenterCDEndTime - nowTime
        if leftTime <= 0 then
            self._setAllianceCenterCDEndTime = nil
            self._needTriggerRefershUI = true
        else
            local leftTimeLang = I18N.GetWithParams("alliance_center_cooldown_countdown", TimeFormatter.SimpleFormatTime(leftTime))
            self._p_text_cd.text = leftTimeLang
            self._p_text_cd_1.text = leftTimeLang
        end
    end
    if self._targetVillage then
        local start
        local endTime
        if self._targetVillage.Status == wds.BuildingStatus.BuildingStatus_GiveUping then
            start = self._targetVillage.StartTime.ServerSecond
            endTime = self._targetVillage.OKTime.ServerSecond
        else
            start = self._targetVillage.AllianceCenterTransformStartTime.ServerSecond
            endTime = self._targetVillage.AllianceCenterTransformEndTime.ServerSecond
        end
        local leftTime = math.max(0, endTime - nowTime)
        self._p_progress.value = math.inverseLerp(start, endTime, nowTime)
        self._p_text_time.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
    end
    if self._needTriggerRefershUI then
        self._needTriggerRefershUI = false
        self:RefreshUI()
    end
    self._inSecTick = false
end

function AllianceTerritoryMainSummaryAllianceCenterCell:IsOnAllianceCenterTerritory()
    if not self._targetVillage then
        return false
    end
    return ModuleRefer.PlayerModule:GetCastle().BasicInfo.IsInAllianceCenter
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClickTransform()
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MakeOverAllianceCenter) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_center_unlocked_needleader_tips"))
        return
    end
    if self._setAllianceCenterCDEndTime and self._setAllianceCenterCDEndTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
        local leftime = self._setAllianceCenterCDEndTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_center_cooldown_countdown", TimeFormatter.SimpleFormatTime(leftime)))
        return
    end
    if not ModuleRefer.VillageModule:AllianceHasAnyVillage() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_center_unlocked_needcity_tips"))
    end
    local current = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    if current and current.AllianceCenterStatus ~= wds.VillageTransformStatus.VillageTransformStatusDone then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.AllianceCenterTransformMediator)
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClickTransformDisabled()
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MakeOverAllianceCenter) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_center_unlocked_needleader_tips"))
        return
    end
    if self._setAllianceCenterCDEndTime and self._setAllianceCenterCDEndTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
        local leftime = self._setAllianceCenterCDEndTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_center_cooldown_countdown", TimeFormatter.SimpleFormatTime(leftime)))
        return
    end
    if not ModuleRefer.VillageModule:AllianceHasAnyVillage() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_center_unlocked_needcity_tips"))
    end
end

---@param entity wds.CastleBrief
function AllianceTerritoryMainSummaryAllianceCenterCell:OnPlayerInAllianceCenterStatusChanged(entity, _)
    if not entity or entity.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then
        return
    end
    self:RefreshUI()
end

---@param entity wds.Alliance
function AllianceTerritoryMainSummaryAllianceCenterCell:OnMapBuildingChanged(entity, changed)
    if ModuleRefer.AllianceModule:GetAllianceId() ~= entity.ID then
        return
    end
    if self._tabStatus == 0 then
        if ModuleRefer.VillageModule:AllianceHasAnyVillage() then
            self:RefreshUI()
            return
        end
    end
    if self._tabStatus == 1 then
        self._targetVillage = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
        if self._targetVillage then
            self:RefreshUI()
            return
        end
    end
    if not self._targetVillage then
        return
    end
    local _, remove, change = OnChangeHelper.GenerateMapFieldChangeMap(changed, wds.MapBuildingBrief)
    if remove and remove[self._targetVillage.EntityID] then
        self:RefreshUI()
        return
    end
    if change and change[self._targetVillage.EntityID] then
        self:RefreshUI()
        return
    end
end

function AllianceTerritoryMainSummaryAllianceCenterCell:CheckTriggerGuide()
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MakeOverAllianceCenter) then
        return
    end
    local current = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
    if not current and ModuleRefer.VillageModule:AllianceHasAnyVillage() then
        if g_Game.PlayerPrefsEx:GetIntByUid("GUIDE_5241", 0) == 0 then
            g_Game.PlayerPrefsEx:SetIntByUid("GUIDE_5241", 1)
            g_Game.PlayerPrefsEx:Save()
            ModuleRefer.GuideModule:CallGuide(5241)
            return
        end
    end
    if current and current.AllianceCenterStatus == wds.VillageTransformStatus.VillageTransformStatusDone then
        if g_Game.PlayerPrefsEx:GetIntByUid("GUIDE_5242", 0) ~= 0 then
            return
        end
        local lv = ConfigRefer.FixedMapBuilding:Find(current.ConfigId):Level()
        for i, v in pairs(ModuleRefer.VillageModule:GetAllVillageMapBuildingBrief()) do
            local lv2 = ConfigRefer.FixedMapBuilding:Find(v.ConfigId):Level()
            if lv2 > lv then
                g_Game.PlayerPrefsEx:SetIntByUid("GUIDE_5242", 1)
                g_Game.PlayerPrefsEx:Save()
                ModuleRefer.GuideModule:CallGuide(5242)
                return
            end
        end
    end
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClickSearchVillage()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.AllianceMainMediator)
    ModuleRefer.VillageModule:GotoNeareastCanDeclareVillage()
end

function AllianceTerritoryMainSummaryAllianceCenterCell:OnClickSearchOrMoveVillage()
    if self.isR4Above then
        self:OnClickSearchVillage()
    else
        -- 前往汇聚点
        local conveneLabelId = ConfigRefer.AllianceConsts:AllianceConveneLabel()
        local label = ModuleRefer.AllianceModule:GetMyAllianceMapLabelByCfgId(conveneLabelId)
        local x, z
        local coord

        if label then
            x, z = KingdomMapUtils.ParseCoordinate(label.X, label.Y)
        else
            --无汇聚点，前往盟主主堡
            local leaderInfo = ModuleRefer.AllianceModule:GetAllianceLeaderInfo()
            x, z  = KingdomMapUtils.ParseBuildingPos(leaderInfo.BigWorldPosition)
        end
        coord = {X = x, Y = z}

         g_Game.UIManager:CloseByName(UIMediatorNames.AllianceMainMediator)
        local scene = g_Game.SceneManager.current
        if scene:IsInCity() then
            local callback = function()
                ModuleRefer.KingdomPlacingModule:StartRelocate(ModuleRefer.PlayerModule:GetCastle().MapBasics.ConfID, ModuleRefer.RelocateModule.CanRelocate, coord)
            end
            scene:LeaveCity(callback)
        else
            ModuleRefer.KingdomPlacingModule:StartRelocate(ModuleRefer.PlayerModule:GetCastle().MapBasics.ConfID, ModuleRefer.RelocateModule.CanRelocate, coord)
        end
    end
end

return AllianceTerritoryMainSummaryAllianceCenterCell
