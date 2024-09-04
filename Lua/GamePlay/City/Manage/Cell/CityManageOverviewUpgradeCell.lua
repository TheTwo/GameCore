local BaseTableViewProCell = require ('BaseTableViewProCell')
local CityManageCenterI18N = require('CityManageCenterI18N')
local TimeFormatter = require('TimeFormatter')
local Delegate = require('Delegate')

---@class CityManageOverviewUpgradeCell:BaseTableViewProCell
local CityManageOverviewUpgradeCell = class('CityManageOverviewUpgradeCell', BaseTableViewProCell)

function CityManageOverviewUpgradeCell:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    self._p_btn_add = self:Button("p_btn_add", Delegate.GetOrCreate(self, self.OnClickAdd))

    self._p_icon_build = self:Image("p_icon_build")
    self._p_progress_working = self:Slider("p_progress_working")
    self._p_text_working_time = self:Text("p_text_working_time")
    
    self._p_text_obtain = self:Text("p_text_obtain", CityManageCenterI18N.UIHint_Obtain)
end

---@param data CityManageOverviewUpgradeCellData
function CityManageOverviewUpgradeCell:OnFeedData(data)
    self.data = data

    local status = self.data:GetStatus()
    self._statusRecord:ApplyStatusRecord(status)

    if status == 1 then
        g_Game.SpriteManager:LoadSprite(self.data:GetFurnitureIcon(), self._p_icon_build)
        self:UpdateProgress()
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdateProgress))
    end
end

function CityManageOverviewUpgradeCell:UpdateProgress()
    if self.dirty then
        self.dirty = nil
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdateProgress))
        self.data.param:UpdateBuildQueue()
        return
    end

    self._p_progress_working.value = self.data:GetFurnitureUpgradeProgress()
    local remainTime = self.data:GetFurnitureUpgradeRemainTime()
    self._p_text_working_time.text = TimeFormatter.SimpleFormatTime(remainTime)

    if remainTime <= 0 then
        self.dirty = true
    end
end

function CityManageOverviewUpgradeCell:OnClose()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.UpdateProgress))
end

function CityManageOverviewUpgradeCell:OnClickAdd()
    self.data.param:GotoUpgradeAny()
end

return CityManageOverviewUpgradeCell