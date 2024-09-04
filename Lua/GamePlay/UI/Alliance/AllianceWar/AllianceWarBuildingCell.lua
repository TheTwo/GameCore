local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath= require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceWarBuildingCell:BaseTableViewProCell
---@field new fun():AllianceWarBuildingCell
---@field super BaseTableViewProCell
local AllianceWarBuildingCell = class('AllianceWarBuildingCell', BaseTableViewProCell)

function AllianceWarBuildingCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._isEventsAdd = false
    self._useTick = false
    self._isAttack = false
    self._needEscrowInfoUpdated = false
end

function AllianceWarBuildingCell:OnCreate(param)
    self._p_base_attack_building = self:GameObject("p_base_attack_building")
    self._p_base_defence_building = self:GameObject("p_base_defence_building")
    self._p_img_building = self:Image("p_img_building")
    
    self._p_distance_building = self:GameObject("p_distance_building")
    self._p_text_distance_building = self:Text("p_text_distance_building")
    
    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_name_building = self:Text("p_text_name_building")
    self._p_text_position_building = self:Text("p_text_position_building")
    
    self._p_icon_attack_building = self:GameObject("p_icon_attack_building")
    self._p_icon_defence_building = self:GameObject("p_icon_defence_building")
    
    self._p_text_status_war = self:Text("p_text_status_war")
    self._p_text_time_war = self:Text("p_text_time_war")

    self._p_btn_join = self:Button("p_btn_join", Delegate.GetOrCreate(self, self.OnClickJoin))
    self._p_btn_quit = self:Button("p_btn_quit", Delegate.GetOrCreate(self, self.OnClickQuit))
    
    self._p_progress_attack_building = self:Slider("p_progress_attack_building")
    self._p_progress_defence_building = self:Slider("p_progress_defence_building")
    
    self._p_appointment_league = self:GameObject("p_appointment_league")
    self._p_text_appointment_title = self:Text("p_text_appointment_title")
    self._p_icon_appointment_1 = self:Image("p_icon_appointment_1")
    self._p_quantity_appointment_1 = self:Text("p_quantity_appointment_1")
    self._p_icon_appointment_2 = self:Image("p_icon_appointment_2")
    self._p_quantity_appointment_2 = self:Text("p_quantity_appointment_2")
    
    self._p_appointment_player = self:GameObject("p_appointment_player")
    self._p_icon_appointment = self:Image("p_icon_appointment")
    self._p_text_appointment_player = self:Text("p_text_appointment_player")
    self._p_btn_detail_appointment = self:Button("p_btn_detail_appointment", Delegate.GetOrCreate(self, self.OnClickEscrowTip))

    self._p_condition_behemoth = self:GameObject("p_condition_behemoth")
    self._p_text_condition = self:Text("p_text_condition")
    self._p_btn_detail_1 = self:Button("p_btn_detail_1", Delegate.GetOrCreate(self, self.OnClickBhehemothDetailInfo))
end

---@param data AllianceWarBuildingCellData
function AllianceWarBuildingCell:OnFeedData(data)
    self._useTick = false
    self:SetupEvents(true)
    self._data = data
    self._isAttack = data:IsAttack()
    self._p_base_attack_building:SetVisible(self._isAttack)
    self._p_icon_attack_building:SetVisible(self._isAttack)
    self._p_progress_attack_building:SetVisible(self._isAttack)
    self._p_base_defence_building:SetVisible(not self._isAttack)
    self._p_icon_defence_building:SetVisible(not self._isAttack)
    self._p_progress_defence_building:SetVisible(not self._isAttack)

    self._p_btn_join:SetVisible(data:ShowJoin())
    self._p_btn_quit:SetVisible(data:ShowQuit())
    
    self._useTick = data:UseTick()
    self._p_condition_behemoth:SetVisible(data:IsTargetBehemothCage())
    self._p_text_condition.text = I18N.GetWithParams("alliance_behemoth_cage_power", ("R%s"):format(ModuleRefer.AllianceModule.HasbehemothCageEnterMinR))
    g_Game.SpriteManager:LoadSprite(data:GetTargetIcon(), self._p_img_building)
    local distance = data:GetDistance()
    if distance then
        if distance > 1000 then
            self._p_text_distance_building.text = ("%dKM"):format(math.floor(distance / 1000 + 0.5))
        else
            self._p_text_distance_building.text = ("%dM"):format(math.floor(distance + 0.5))
        end
        self._p_distance_building:SetVisible(true)
    else
        self._p_distance_building:SetVisible(false)
    end
    local lv = data:GetLv()
    if lv then
        self._p_text_lv.text = tostring(lv)
        self._p_text_lv:SetVisible(true)
    else
        self._p_text_lv:SetVisible(false)
    end
    self._p_text_name_building.text = data:GetTargetName()
    local posX,posY = data:GetPos()
    if posX and posY then
        self._p_text_position_building.text = ("(%s,%s)"):format(posX, posY)
        self._p_text_position_building:SetVisible(true)
    else
        self._p_text_position_building:SetVisible(false)
    end
    self._needEscrowInfoUpdated = data:NeedEscrowInfoUpdated()
    self:UpdateEscrowInfo()
    self:Tick(0)
end

function AllianceWarBuildingCell:UpdateEscrowInfo()
    self._data:EscrowInfoUpdated()
    self._data:SetUpExtraInfo(self._p_appointment_league, self._p_text_appointment_title, self._p_icon_appointment_1, self._p_quantity_appointment_1, self._p_icon_appointment_2, self._p_quantity_appointment_2)
    self._data:SetUpEscrowPart(self._p_appointment_player, self._p_icon_appointment, self._p_text_appointment_player, self._p_btn_detail_appointment)
end

function AllianceWarBuildingCell:OnRecycle(param)
    self:SetupEvents(false)
    self._data = nil
end

function AllianceWarBuildingCell:OnClose(param)
    self:SetupEvents(false)
end

function AllianceWarBuildingCell:OnClickJoin()
    if not self._data then
        return
    end
    self._data:OnClickJoin()
end

function AllianceWarBuildingCell:OnClickQuit()
    if not self._data then
        return
    end
    self._data:OnClickQuit()
end

function AllianceWarBuildingCell:OnClickEscrowTip()
    if not self._data then
        return
    end
    self._data:OnClickEscrowTip()
end

function AllianceWarBuildingCell:Tick(dt)
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

function AllianceWarBuildingCell:SetupEvents(add)
    if self._isEventsAdd and not add then
        self._isEventsAdd = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceAssembleInfo.TargetAssembleInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceAssembleInfoChanged))
    elseif not self._isEventsAdd and add then
        self._isEventsAdd = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceAssembleInfo.TargetAssembleInfo.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceAssembleInfoChanged))
    end
end

---@param entity wds.Alliance
function AllianceWarBuildingCell:OnAllianceAssembleInfoChanged(entity, changedData)
    if not self._needEscrowInfoUpdated then
        return
    end
    self:UpdateEscrowInfo()
end

function AllianceWarBuildingCell:OnClickBhehemothDetailInfo()
    ModuleRefer.ToastModule:SimpleShowTextToastTip(I18N.Get("alliance_behemoth_rule_declarecage"), self._p_btn_detail_1.transform)
end

return AllianceWarBuildingCell