local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class CityManageOverviewHatchEggCell:BaseTableViewProCell
local CityManageOverviewHatchEggCell = class('CityManageOverviewHatchEggCell', BaseTableViewProCell)

function CityManageOverviewHatchEggCell:OnCreate()
    self._status = self:StatusRecordParent("")

    self._status_free = self:Button("status_free", Delegate.GetOrCreate(self, self.OnClickEmpty))
    self._p_icon_egg = self:Image("p_icon_egg")
    self._p_progress_working = self:Slider("p_progress_working")
    self._p_text_working_time = self:Text("p_text_working_time")

    self._status_working = self:Button("status_working", Delegate.GetOrCreate(self, self.OnClickEgg))
end

---@param data CityManageOverviewHatchEggCellData
function CityManageOverviewHatchEggCell:OnFeedData(data)
    self.data = data
    local status = data:GetStatus()
    self._status:ApplyStatusRecord(status)

    self.needTick = status == 1
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    if status == 1 then
        g_Game.SpriteManager:LoadSprite(self.data:GetEggImage(), self._p_icon_egg)
        self._p_progress_working.value = self.data:GetWorkingProgress()
        self._p_text_working_time.text = self.data:GetWorkingTime()
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    end
end

function CityManageOverviewHatchEggCell:OnClose()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityManageOverviewHatchEggCell:OnTick()
    if not self.data then return end
    self._p_progress_working.value = self.data:GetWorkingProgress()
    self._p_text_working_time.text = self.data:GetWorkingTime()
end

function CityManageOverviewHatchEggCell:OnClickEmpty()
    if self.data then
        self.data:OnClickEmpty()
    end
end

function CityManageOverviewHatchEggCell:OnClickEgg()
    if self.data then
        self.data:OnClickEmpty()
    end
end

return CityManageOverviewHatchEggCell