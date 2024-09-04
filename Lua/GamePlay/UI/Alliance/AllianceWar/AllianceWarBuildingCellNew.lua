local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local I18N = require("I18N")
local AllianceWarTabHelper = require("AllianceWarTabHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceWarBuildingCellNew:BaseTableViewProCell
---@field new fun():AllianceWarBuildingCellNew
---@field super BaseTableViewProCell
local AllianceWarBuildingCellNew = class('AllianceWarBuildingCellNew', BaseTableViewProCell)

function AllianceWarBuildingCellNew:ctor()
    BaseTableViewProCell.ctor(self)
    self._isEventsAdd = false
    self._useTick = false
    self._isAttack = false
    self._needEscrowInfoUpdated = false
    self._requestBasicAllianceId = nil
end

function AllianceWarBuildingCellNew:OnCreate(param)
    self._p_base_attack_building = self:GameObject("p_base_attack_building")
    self._p_base_defence_building = self:GameObject("p_base_defence_building")

    self._p_league_info_my = self:GameObject("p_league_info_my")
    ---@type CommonAllianceLogoComponent
    self._child_league_logo = self:LuaObject("child_league_logo")
    self._p_text_league_name = self:Text("p_text_league_name")
    self._p_text_position_league_center = self:Text("p_text_position_league_center")
    self._p_text_position_league_center:SetVisible(false)
    self._p_click_left_pos = self:Button("p_click_left_pos", Delegate.GetOrCreate(self, self.OnClickLeftPos))

    self._p_building_info_my = self:GameObject("p_building_info_my")
    self._p_img_building_my = self:Image("p_img_building_my")
    self._p_distance_building_my = self:GameObject("p_distance_building_my")
    self._p_text_distance_building_my = self:Text("p_text_distance_building_my")
    self._p_text_lv_my = self:Text("p_text_lv_my")
    self._p_text_name_building_my = self:Text("p_text_name_building_my")
    self._p_text_position_building_my = self:Text("p_text_position_building_my")
    self._p_click_right_pos_my = self:Button("p_click_right_pos_my", Delegate.GetOrCreate(self, self.OnClickLeftPos))

    self._attack = self:GameObject("attack")
    self._p_appointment_league = self:GameObject("p_appointment_league")
    self._p_text_appointment_title = self:Text("p_text_appointment_title")
    self._p_icon_appointment_1 = self:Image("p_icon_appointment_1")
    self._p_quantity_appointment_1 = self:Text("p_quantity_appointment_1")
    self._p_icon_appointment_2 = self:Image("p_icon_appointment_2")
    self._p_quantity_appointment_2 = self:Text("p_quantity_appointment_2")
    self._p_btn_detail_appointment = self:Button("p_btn_detail_appointment", Delegate.GetOrCreate(self, self.OnClickEscrowTip))
    self._p_icon_attack_building = self:GameObject("p_icon_attack_building")
    self._p_progress_attack_building = self:Slider("p_progress_attack_building")

    self._defence = self:GameObject("defence")
    self._p_defence_league = self:GameObject("p_defence_league")
    self._p_text_defence_title = self:Text("p_text_defence_title")
    self._p_icon_defence_1 = self:Image("p_icon_defence_1")
    self._p_quantity_defence_1 = self:Text("p_quantity_defence_1")
    self._p_icon_defence_building = self:GameObject("p_icon_defence_building")
    self._p_progress_defence_building = self:Slider("p_progress_defence_building")

    self._p_text_status_war = self:Text("p_text_status_war")
    self._p_text_time_war = self:Text("p_text_time_war")

    self._p_league_info_enemy = self:GameObject("p_league_info_enemy")
    ---@type CommonAllianceLogoComponent
    self._child_league_logo_enemy = self:LuaObject("child_league_logo_enemy")
    self._p_text_league_name_enemy = self:Text("p_text_league_name_enemy")
    self._p_text_position_league_center_enemy = self:Text("p_text_position_league_center_enemy")
    self._p_text_position_league_center_enemy:SetVisible(false)
    self._p_click_left_pos_enemy = self:Button("p_click_left_pos_enemy", Delegate.GetOrCreate(self, self.OnClickRightPos))

    self._p_building_info_enemy = self:GameObject("p_building_info_enemy")
    self._p_img_building = self:Image("p_img_building")
    self._p_distance_building = self:GameObject("p_distance_building")
    self._p_text_distance_building = self:Text("p_text_distance_building")

    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_name_building = self:Text("p_text_name_building")
    self._p_text_position_building = self:Text("p_text_position_building")
    self._p_click_right_pos = self:Button("p_click_right_pos", Delegate.GetOrCreate(self, self.OnClickRightPos))

    self._p_btn_join = self:Button("p_btn_join", Delegate.GetOrCreate(self, self.OnClickJoin))

    self._p_appointment_player = self:GameObject("p_appointment_player")
    self._p_icon_appointment = self:Image("p_icon_appointment")
    self._p_text_appointment_player = self:Text("p_text_appointment_player")
end

---@param data AllianceWarBuildingCellData
function AllianceWarBuildingCellNew:OnFeedData(data)
    self._requestBasicAllianceId = nil
    self._useTick = false
    self:SetupEvents(true)
    self._data = data
    self._isAttack = data:IsAttack()
    self._attack:SetVisible(self._isAttack)
    self._defence:SetVisible(not self._isAttack)

    self._p_base_attack_building:SetVisible(self._isAttack)
    self._p_icon_attack_building:SetVisible(false)
    self._p_progress_attack_building:SetVisible(self._isAttack)
    self._p_base_defence_building:SetVisible(not self._isAttack)
    self._p_icon_defence_building:SetVisible(not self._isAttack)
    self._p_progress_defence_building:SetVisible(not self._isAttack)
    self._p_building_info_my:SetVisible(not self._isAttack)
    self._p_building_info_enemy:SetVisible(self._isAttack)
    self._p_league_info_my:SetVisible(self._isAttack)
    self._p_league_info_enemy:SetVisible(not self._isAttack)

    local logoComp,leagueName,bImg,bName,bLv,bPos,dRoot,dText = self:GetNeedProcessComps()

    local sourceAllianceInfo = data:GetSourceInfo()
    if sourceAllianceInfo then
        ---@type wrpc.AllianceBriefInfo
        local allianceInfo
        if sourceAllianceInfo.allianceId ~= 0 and sourceAllianceInfo.allianceId == ModuleRefer.AllianceModule:GetAllianceId() then
            allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceBriefInfo()
        elseif sourceAllianceInfo.allianceId ~= 0 then
            allianceInfo = ModuleRefer.AllianceModule:RequestAllianceBriefInfo(sourceAllianceInfo.allianceId)
        end
        if allianceInfo then
            logoComp:SetVisible(true)
            logoComp:FeedData(allianceInfo.Flag)
        else
            if sourceAllianceInfo.allianceId ~= 0 then
                self._requestBasicAllianceId = sourceAllianceInfo.allianceId
            end
            logoComp:SetVisible(false)
        end
        leagueName:SetVisible(true)
        if not string.IsNullOrEmpty(sourceAllianceInfo.abbr) then
            leagueName.text = ("[%s]%s"):format(sourceAllianceInfo.abbr, sourceAllianceInfo.name)
        else
            leagueName.text = sourceAllianceInfo.name
        end
    else
        logoComp:SetVisible(false)
        leagueName:SetVisible(false)
    end

    self._p_btn_join:SetVisible(data:ShowJoin())
    
    self._useTick = data:UseTick()
    g_Game.SpriteManager:LoadSprite(data:GetTargetIcon(), bImg)
    local distance = data:GetDistance()
    if distance then
        if distance > 1000 then
            dText.text = ("%dKM"):format(math.floor(distance / 1000 + 0.5))
        else
            dText.text = ("%dM"):format(math.floor(distance + 0.5))
        end
        dRoot:SetVisible(true)
    else
        dRoot:SetVisible(false)
    end
    local lv = data:GetLv()
    if lv then
        bLv.text = tostring(lv)
        bLv:SetVisible(true)
    else
        bLv:SetVisible(false)
    end
    bName.text = data:GetTargetName()
    local posX,posY = data:GetPos()
    if posX and posY then
        bPos.text = ("(%s,%s)"):format(posX, posY)
        bPos:SetVisible(true)
    else
        bPos:SetVisible(false)
    end
    self._needEscrowInfoUpdated = data:NeedEscrowInfoUpdated()
    self:UpdateEscrowInfo()
    if data:IsTargetBehemothCage() and data:IsAttack() then
        self._p_appointment_league:SetVisible(true)
        self._p_text_appointment_title.text = I18N.GetWithParams("alliance_behemoth_cage_power", ("R%s"):format(ModuleRefer.AllianceModule.HasbehemothCageEnterMinR))
        self._p_icon_appointment_2:SetVisible(false)
        self._p_quantity_appointment_2:SetVisible(false)
    end

    self._p_text_appointment_title:SetVisible(false)
    self._p_icon_appointment_1:SetVisible(false)
    self._p_quantity_appointment_1:SetVisible(false)
    self._p_btn_detail_appointment:SetVisible(false)

    self:Tick(0)
end

function AllianceWarBuildingCellNew:UpdateEscrowInfo()
    self._data:EscrowInfoUpdated()
    self._data:SetUpExtraInfo(self._p_appointment_league, self._p_text_appointment_title, self._p_icon_appointment_1, self._p_quantity_appointment_1, self._p_icon_appointment_2, self._p_quantity_appointment_2)
    self._data:SetUpEscrowPart(self._p_appointment_player, self._p_icon_appointment, self._p_text_appointment_player, self._p_btn_detail_appointment)
end

function AllianceWarBuildingCellNew:OnRecycle(param)
    self:SetupEvents(false)
    self._data = nil
end

function AllianceWarBuildingCellNew:OnClose(param)
    self:SetupEvents(false)
end

function AllianceWarBuildingCellNew:OnClickLeftPos()
    if not self._data then return end
    if self._isAttack then return end
    local posX,posY = self._data:GetPos()
    if posX and posY then
        self:GetParentBaseUIMediator():CloseSelf()
        AllianceWarTabHelper.GoToCoord(posX, posY, true)
    end
end

function AllianceWarBuildingCellNew:OnClickRightPos()
    if not self._data then return end
    if not self._isAttack then return end
    local posX,posY = self._data:GetPos()
    if posX and posY then
        self:GetParentBaseUIMediator():CloseSelf()
        AllianceWarTabHelper.GoToCoord(posX, posY, true)
    end
end

function AllianceWarBuildingCellNew:OnClickJoin()
    if not self._data then
        return
    end
    self._data:OnClickJoin()
end

function AllianceWarBuildingCellNew:OnClickEscrowTip()
    if not self._data then
        return
    end
    if self._data:IsAttack() and self._data:IsTargetBehemothCage() then
        ModuleRefer.ToastModule:SimpleShowTextToastTip(I18N.Get("alliance_behemoth_rule_declarecage"), self._p_btn_detail_appointment.transform)
        return
    end
    self._data:OnClickEscrowTip()
end

function AllianceWarBuildingCellNew:Tick(dt)
    if not self._useTick then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local progress = self._data:GetProgress(nowTime)
    self._p_text_status_war.text = self._data:GetStatusName(nowTime)
    self._p_text_time_war.text = self._data:GetProgressValueSting(nowTime)
    if self._isAttack then
        self._p_progress_attack_building.value = progress
    else
        self._p_progress_defence_building.value = progress
    end
end

function AllianceWarBuildingCellNew:SetupEvents(add)
    if self._isEventsAdd and not add then
        self._isEventsAdd = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceAssembleInfo.TargetAssembleInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceAssembleInfoChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
    elseif not self._isEventsAdd and add then
        self._isEventsAdd = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceAssembleInfo.TargetAssembleInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceAssembleInfoChanged))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_BASIC_INFO_CACHE_UPDATE, Delegate.GetOrCreate(self, self.OnAllianceBasicInfoUpdate))
    end
end

---@return CommonAllianceLogoComponent,CS.UnityEngine.UI.Text,CS.UnityEngine.UI.Image,CS.UnityEngine.UI.Text,CS.UnityEngine.UI.Text,CS.UnityEngine.UI.Text,CS.UnityEngine.GameObject,CS.UnityEngine.UI.Text
function AllianceWarBuildingCellNew:GetNeedProcessComps()
    local isMyAttack = self._isAttack
    local logoComp = isMyAttack and self._child_league_logo or self._child_league_logo_enemy
    local leagueNameComp = isMyAttack and self._p_text_league_name or self._p_text_league_name_enemy
    local buildingImg = isMyAttack and self._p_img_building or self._p_img_building_my
    local buildingName = isMyAttack and self._p_text_name_building or self._p_text_name_building_my
    local buildingLv = isMyAttack and self._p_text_lv or self._p_text_lv_my
    local buildingPos = isMyAttack and self._p_text_position_building or self._p_text_position_building_my
    local distanceRoot = isMyAttack and self._p_distance_building or self._p_distance_building_my
    local distanceComp = isMyAttack and self._p_text_distance_building or self._p_text_distance_building_my
    return logoComp,leagueNameComp,buildingImg,buildingName,buildingLv,buildingPos,distanceRoot,distanceComp
end

---@param entity wds.Alliance
function AllianceWarBuildingCellNew:OnAllianceAssembleInfoChanged(entity, changedData)
    if not self._needEscrowInfoUpdated then
        return
    end
    self:UpdateEscrowInfo()
end

---@param allianceId number
---@param allianceBasicInfo wrpc.AllianceBriefInfo
function AllianceWarBuildingCellNew:OnAllianceBasicInfoUpdate(allianceId, allianceBasicInfo)
    if allianceId ~= self._requestBasicAllianceId then
        return
    end
    if allianceBasicInfo then
        self._child_league_logo_enemy:SetVisible(true)
        self._child_league_logo_enemy:FeedData(allianceBasicInfo.Flag)
    end
end

return AllianceWarBuildingCellNew