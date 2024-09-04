--- scene:scene_construction_resident_manage

local CityCitizenManageUIMediatorDefine = require("CityCitizenManageUIMediatorDefine")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local CityConst = require("CityConst")
local ConfigRefer = require("ConfigRefer")
---@type CS.UnityEngine.RectTransformUtility
local RectTransformUtility = CS.UnityEngine.RectTransformUtility
local Utils = require("Utils")
local OnChangeHelper = require("OnChangeHelper")
local ArtResourceUtils = require("ArtResourceUtils")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class CityCitizenManageUIMediatorParam
---@field mode CityCitizenManageUIMediatorDefine.Mode
---@field targetId number
---@field targetType number
---@see CityWorkTargetType

---@class CityCitizenManageUIMediator:BaseUIMediator
---@field new fun():CityCitizenManageUIMediator
---@field super BaseUIMediator
local CityCitizenManageUIMediator = class('CityCitizenManageUIMediator', BaseUIMediator)

---@type table<CityCitizenManageUIMediatorDefine.Mode, CityCitizenManageUIState>
CityCitizenManageUIMediator._factory = {
    [CityCitizenManageUIMediatorDefine.Mode.AssignHouse] = require("CityCitizenManageUIStateAssignHouse"),
    [CityCitizenManageUIMediatorDefine.Mode.AssignWork] = require("CityCitizenManageUIStateAssignWork"),
    [CityCitizenManageUIMediatorDefine.Mode.DragAssign] = require("CityCitizenManageUIStateDragAssign"),
}

function CityCitizenManageUIMediator:ctor()
    BaseUIMediator.ctor(self)
    
    ---@type City
    self._city = nil
    ---@type CityCitizenManageUIState
    self._uiState = nil
    ---@type CityCitizenManageUIMediatorDefine.Mode
    self._mode = nil
    ---@type CityCitizenManageUIMediatorParam
    self._param = nil

    ---@type ZoomToWithFocusStackStatus[]
    self._cameraStack = {}
    
    self._lineBaseLength = nil
end

function CityCitizenManageUIMediator:OnCreate(param)
    
    self._p_background_base = self:RectTransform("p_background_base")
    self._p_btn_title_resident = self:Button("p_btn_title_resident", Delegate.GetOrCreate(self, self.OnClickTitleResident))
    self._p_text_title = self:Text("p_text_title", "citizen_select")
    self._p_text_number = self:Text("p_text_number")
    self._p_group_table = self:Transform("p_group_table")
    self._p_table_btn = self:TableViewPro("p_table_btn")
    self._p_table_detail = self:TableViewPro("p_table_detail")
    self._p_btn_title_vagrant = self:Button("p_btn_title_vagrant", Delegate.GetOrCreate(self, self.OnClickTitleVagrant))
    self._p_text_title_vagrant = self:Text("p_text_title_vagrant", "citizen_information")
    self._p_text_number_vagrant = self:Text("p_text_number_vagrant")
    self._p_table_vagrant = self:TableViewPro("p_table_vagrant")
    self._p_btn_checkin = self:Transform("p_btn_checkin")
    self._p_comp_btn_a_l = self:Button("p_comp_btn_a_l", Delegate.GetOrCreate(self, self.OnClickCheckIn))
    self._p_comp_btn_d_m = self:Button("p_comp_btn_d_m")
    self._p_text_m = self:Text("p_text_m")
    self._p_text = self:Text("p_text")
    self._p_line_root = self:Transform("p_line_root")
    self._p_handlePos = self:Transform("p_handlePos")
    self._p_line_a = self:Image("p_line_a")
    self._p_line_b = self:Image("p_line_b")
    ---@type CS.Empty4Raycast
    self._p_gesture_pad = self:BindComponent("p_gesture_pad", typeof(CS.Empty4Raycast))
    self._p_btn_back = self:PointerClick("p_gesture_pad", Delegate.GetOrCreate(self, self.OnClickClose))
    self._p_scroll_rect = self:RectTransform("p_scroll_rect")
    self._p_text_management = self:Transform("p_text_management")
    self._p_text_desc = self:Text("p_text_desc", "citizen_amount")
    self._p_text_amount = self:Text("p_text_amount")
    self._p_text_house = self:Text("p_text_house", "citizen_capacity")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_empty = self:GameObject("p_empty")
    self._p_empty:SetVisible(false)
    self._p_text_no = self:Text("p_text_no", "citizen_blank")
    self._p_group_tips = self:GameObject("p_group_tips")
    self._p_text_tips = self:Text("p_text_tips", I18N.Temp().text_creep_polluted)
    self._p_text_tips_yield = self:Text("p_text_tips_yield", I18N.Temp().text_efficient_low)
    
    self._p_vx_trigger_toast = self:AnimTrigger("p_vx_trigger_toast")
    self._p_img_head = self:Image("p_img_head")
    self._p_text_content = self:Text("p_text_content")
    self._p_text_hint = self:Text("p_text_content")

    local t = self._p_handlePos.parent
    local w = t:TransformPoint(self._p_handlePos.localPosition)
    local w2 = t:TransformPoint(CS.UnityEngine.Vector3.zero)
    self._lineBaseLength = (w2 - w).magnitude
    if Utils.IsNotNull(self._p_group_tips) then
        self._p_group_tips:SetVisible(false)
    end
end

---@param param CityCitizenManageUIMediatorParam
function CityCitizenManageUIMediator:OnShow(param)
    
    self._city = ModuleRefer.CityModule.myCity
    
    self._param = param
    self._mode = param.mode
    self:InitUiStatus()
    
    self._uiState = CityCitizenManageUIMediator._factory[param.mode].new(self)
    self._uiState:OnShow()
    
    self:UpdateCitizenNumberStatus()
    self:AddEvents()
end

function CityCitizenManageUIMediator:OnHide(param)
    self:RemoveEvents()
    self._uiState:OnHide()
end

function CityCitizenManageUIMediator:InitUiStatus()
    if self._mode == CityCitizenManageUIMediatorDefine.Mode.AssignHouse then
        self._p_line_a:SetVisible(false)
        self._p_line_b:SetVisible(false)
        self._p_btn_title_resident:SetVisible(false)
        self._p_group_table:SetVisible(false)
        self._p_btn_title_vagrant:SetVisible(true)
        self._p_table_vagrant:SetVisible(true)
        self._p_btn_checkin:SetVisible(true)
    elseif self._mode == CityCitizenManageUIMediatorDefine.Mode.AssignWork then
        self._p_line_a:SetVisible(false)
        self._p_line_b:SetVisible(false)
        self._p_btn_title_resident:SetVisible(true)
        self._p_group_table:SetVisible(true)
        self._p_btn_title_vagrant:SetVisible(false)
        self._p_table_vagrant:SetVisible(false)
        self._p_btn_checkin:SetVisible(false)
    elseif self._mode == CityCitizenManageUIMediatorDefine.Mode.DragAssign then
        self._p_line_a:SetVisible(true)
        self._p_line_b:SetVisible(true)
        self._p_btn_title_resident:SetVisible(true)
        self._p_group_table:SetVisible(true)
        self._p_btn_title_vagrant:SetVisible(true)
        self._p_table_vagrant:SetVisible(true)
        self._p_btn_checkin:SetVisible(false)
    else
        g_Logger.Error("Unsupported mode:%d", self._mode)
    end
end

function CityCitizenManageUIMediator:AddEvents()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
end

function CityCitizenManageUIMediator:RemoveEvents()
    g_Game.UIManager:RemoveOnAnyPointDown(Delegate.GetOrCreate(self, self.OnAnyPointDown))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
end

function CityCitizenManageUIMediator:OnClickClose()
    self._uiState:OnClickClose()
end

function CityCitizenManageUIMediator:OnClickTitleResident()
    self._uiState:OnClickTitleResident()
end

function CityCitizenManageUIMediator:OnClickTitleVagrant()
    self._uiState:OnClickTitleVagrant()
end

function CityCitizenManageUIMediator:OnClickCheckIn()
    self._uiState:OnClickCheckIn(self._p_comp_btn_a_l.transform)
end

function CityCitizenManageUIMediator:OnCityStateChanged(flag)
    if not flag then
        self:OnClickClose()
    end
end

---@param entity wds.CastleBrief
---@param changedData table
function CityCitizenManageUIMediator:OnCitizenDataChanged(entity, changedData)
    if not self._city or self._city.uid ~= entity.ID then
        return
    end
    self:UpdateCitizenNumberStatus()
    local _,_,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.Citizen)
    if changed then
        for citizenId, v in pairs(changed) do
            local old = v[1]
            local new = v[2]
            if (not old.HouseId or old.HouseId <= 0) and new.HouseId and new.HouseId > 0 then
                self:OnCitizenAssigned(citizenId, new.ConfigId)
                break
            end
        end
    end
end

function CityCitizenManageUIMediator:UpdateCitizenNumberStatus()
    local castle = self._city:GetCastle()
    local idleCitizenCount = 0
    local idleHomelessCount = 0
    local totalCount = 0
    local unassignedCitizenCount = 0
    local withHouseCount = 0
    if castle and castle.CastleCitizens then
        for _, data in pairs(castle.CastleCitizens) do
            if not data.HouseId or data.HouseId == 0 then
                unassignedCitizenCount = unassignedCitizenCount + 1
                if not data.WorkId or data.WorkId == 0 then
                    idleHomelessCount = idleHomelessCount + 1
                end
            else
                withHouseCount = withHouseCount + 1
                if not data.WorkId or data.WorkId == 0 then
                    idleCitizenCount = idleCitizenCount + 1
                end
            end
            totalCount = totalCount + 1
        end
    end
    local usage,total = self._city.cityCitizenManager:GetCitizenPopulationAndCapacity()
    self._p_text_quantity.text = string.format("%d/%d", usage, total)
    if self._mode == CityCitizenManageUIMediatorDefine.Mode.AssignHouse then
        self._p_text_number_vagrant.text = tostring(unassignedCitizenCount)
    elseif self._mode == CityCitizenManageUIMediatorDefine.Mode.AssignWork then
        self._p_text_number.text = string.format("%d/%d", idleCitizenCount + idleHomelessCount, totalCount)
    elseif self._mode == CityCitizenManageUIMediatorDefine.Mode.DragAssign then
        self._p_text_number_vagrant.text = tostring(unassignedCitizenCount)
        local bedCount = self._city.cityCitizenManager:GetTotalCitizenSlotInCity()
        self._p_text_amount.text = string.format("%d/%d", withHouseCount, bedCount)
    else
        g_Logger.Error("Unsupported mode:%d", self._mode)
    end
end

function CityCitizenManageUIMediator:FocusOnCitizen(citizenId, needSelectedShow,notMoveCamera)
    local pos = self._city.cityCitizenManager:GetCitizenPosition(citizenId)
    if pos then
        if needSelectedShow then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, citizenId)
        end
        if notMoveCamera then
            return
        end
        ---@type CS.UnityEngine.Vector3
        local viewPortPos = CS.UnityEngine.Vector3(0.45, 0.5, 0.0)
        self._city.camera:ForceGiveUpTween()
        self._city.camera:ZoomToWithFocusBySpeed(CityConst.CITY_RECOMMEND_CAMERA_SIZE, viewPortPos, pos)
    end
end

function CityCitizenManageUIMediator:TitleResidentMode()
    self._p_btn_title_vagrant:SetVisible(false)
    self._p_table_vagrant:SetVisible(false)
    self._p_btn_checkin:SetVisible(false)
    self._p_text_management:SetVisible(true)
end

function CityCitizenManageUIMediator:PushCameraStatus(recoverTime)
    recoverTime = recoverTime or 0.5
    local status = self._city:GetCamera():RecordCurrentCameraStatus(recoverTime)
    table.insert(self._cameraStack, status)
end

function CityCitizenManageUIMediator:ClearCameraStatus()
    table.clear(self._cameraStack)
end

function CityCitizenManageUIMediator:PopCameraStatus()
    if #self._cameraStack > 0 then
        local status = table.remove(self._cameraStack)
        status:back()
    end
end

function CityCitizenManageUIMediator:SetCameraStatusFromConfig()
    local config = ConfigRefer.CityConfig:CitizenOpenControlCamera()
    if not config then
        return
    end
    local v = ConfigRefer.CityConfig:CameraParam()
    if string.IsNullOrEmpty(v) then
        return
    end
    local size = tonumber(v)
    if size then
        local delta = size - self._city:GetCamera():GetSize()
        self._city:GetCamera():ForceGiveUpTween()
        self._city:GetCamera():Zoom(delta, 0.2)
    end
end

function CityCitizenManageUIMediator:SetTableShowNoCitizens(noCitizen)
    self._p_empty:SetVisible(noCitizen)
end

function CityCitizenManageUIMediator:OnCitizenAssigned(citizenId, citizenConfigId)
    self._p_vx_trigger_toast:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    local citizenConfig = ConfigRefer.Citizen:Find(citizenConfigId)
    --local heroConfig = ConfigRefer.Heroes:Find(citizenConfig:HeroId())
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(citizenConfig:Icon()), self._p_img_head)
    self._p_text_content.text = I18N.GetWithParams("hero_city_settled", I18N.Get(citizenConfig:Name()))
    self._p_text_hint.text = I18N.Get("hero_new_skill_unlock")
    self._p_vx_trigger_toast:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    --for i = 1, heroConfig:CitizenSkillCfgLength() do
    --    local skill = heroConfig:CitizenSkillCfg(i)
    --    local skillConfig = ConfigRefer.CitizenSkillInfo:Find(skill)
    --    if skillConfig then
    --        
    --        break
    --    end
    --end
end

return CityCitizenManageUIMediator

