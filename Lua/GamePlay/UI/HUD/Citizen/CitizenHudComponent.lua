local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local CityCitizenManageUIMediatorDefine = require("CityCitizenManageUIMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local CityCitizenNewManageUIParameter = require("CityCitizenNewManageUIParameter")
local BaseUIComponent = require("BaseUIComponent")

---@class CitizenHudComponent:BaseUIComponent
---@field new fun():CitizenHudComponent
---@field super BaseUIComponent
local CitizenHudComponent = class('CitizenHudComponent', BaseUIComponent)

function CitizenHudComponent:ctor()
    BaseUIComponent.ctor(self)
    self._uid = nil
    self._tickTriggerNewCitizenEffect = nil
end

function CitizenHudComponent:OnCreate(_)
    self._p_btn_resident = self:Button("p_btn_resident", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_progress = self:Image("p_progress")
    self._p_progress_infection = self:Image("p_progress_infection")
    self._p_icon_n = self:Image("p_icon_n")
    self._p_icon_free = self:Image("p_icon_free")
    self._p_icon_stop = self:Image("p_icon_stop")
    self._child_status_free = self:GameObject("child_status_free")
    self._vx_trigger_new = self:AnimTrigger("vx_trigger_new")
end

function CitizenHudComponent:OnShow(_)
    self:OnCityStateChanged(true)
    self:AddEvents()
    self:RefreshStatus()
end

function CitizenHudComponent:OnHide(_)
    self:RemoveEvents()
end

function CitizenHudComponent:AddEvents()
    g_Game.EventManager:AddListener(EventConst.CITY_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_FEEDBACK_END_TRIGGER_HUD_EFFECT, Delegate.GetOrCreate(self, self.OnReceiveNewCitizen))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CitizenHudComponent:RemoveEvents()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_FEEDBACK_END_TRIGGER_HUD_EFFECT, Delegate.GetOrCreate(self, self.OnReceiveNewCitizen))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChanged))
end

function CitizenHudComponent:OnClickSelf()
    local param = CityCitizenNewManageUIParameter.new()
    param:SetCityAndWorkId(ModuleRefer.CityModule.myCity)
    param:SetShowWorkingCiziten(true)
    param:SetShowMask(false)
    g_Game.UIManager:Open(UIMediatorNames.CityCitizenNewManageUIMediator, param)
end

function CitizenHudComponent:OnCityStateChanged(flag)
    local show = false
    if flag then
        local city = ModuleRefer.CityModule.myCity
        if city then
            self._uid = city.uid
            show = city.showed
        end
    end
    self._p_btn_resident.transform:SetVisible(show)
end

---@param entity wds.CastleBrief
function CitizenHudComponent:OnCitizenDataChanged(entity, changedData)
    if not self._uid or self._uid ~= entity.ID then
        return
    end
    self:RefreshStatus()
end

function CitizenHudComponent:RefreshStatus()
    local city = ModuleRefer.CityModule.myCity
    if not city then
        return
    end
    local citizenCount = 0
    local faintCount = 0
    local citizenWorkCount = 0
    local castle = city:GetCastle()
    local castleCitizens = castle.CastleCitizens
    if castleCitizens then
        for _, v in pairs(castleCitizens) do
            citizenCount = citizenCount + 1
            if v.WorkId ~= 0 then
                citizenWorkCount = citizenWorkCount + 1
            end
            if v.InfectionCapacity > 0 and v.InfectionCapacity <= v.InfectionProgress then
                faintCount = faintCount + 1
            end
        end
    end
    if citizenWorkCount <= 0 and faintCount <= 0 then
        self._p_progress_infection:SetVisible(false)
        self._p_progress:SetVisible(false)
        self._p_icon_free:SetVisible(true)
        self._p_icon_n:SetVisible(false)
        self._p_icon_stop:SetVisible(false)
        self._child_status_free:SetVisible(true)
    else
        self._child_status_free:SetVisible(false)
        self._p_progress_infection:SetVisible(faintCount > 0)
        self._p_progress:SetVisible(true)
        self._p_icon_free:SetVisible(false)
        self._p_icon_n:SetVisible(true)
        self._p_icon_stop:SetVisible(false)
        if citizenCount <= 0 then
            self._p_progress.fillAmount = 0
            self._p_progress_infection.fillAmount = 0
        else
            self._p_progress.fillAmount = math.clamp01(citizenWorkCount * 1.0 / citizenCount)
            self._p_progress_infection.fillAmount = math.clamp01((citizenWorkCount + faintCount) * 1.0 / citizenCount)
        end
    end
end

function CitizenHudComponent:Tick(dt)
    if not self._tickTriggerNewCitizenEffect then
        return
    end
    self._tickTriggerNewCitizenEffect = nil
    if self._vx_trigger_new then
        self._vx_trigger_new:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self._vx_trigger_new:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

function CitizenHudComponent:OnReceiveNewCitizen()
    self._tickTriggerNewCitizenEffect = true
end

return CitizenHudComponent

