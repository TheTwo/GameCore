local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityCitizenChooseCitizenCellData
---@field index number
---@field citizenData CityCitizenData
---@field citizenWork CityCitizenWorkData
---@field onSelected fun(index:number)

---@class CityCitizenChooseCitizenCell:BaseTableViewProCell
---@field new fun():CityCitizenChooseCitizenCell
---@field super BaseUIMediator
local CityCitizenChooseCitizenCell = class('CityCitizenChooseCitizenCell', BaseTableViewProCell)

function CityCitizenChooseCitizenCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._needTick = false
end

function CityCitizenChooseCitizenCell:OnCreate(_)
    self._p_img_select = self:Image("p_img_select")
    self._p_text_name_resident = self:Text("p_text_name_resident")
    self._p_text_time = self:Text("p_text_time")
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    
    self._p_status_a = self:Transform("p_status_a")
    self._p_status_b = self:Transform("p_status_b")
    self._p_status_c = self:Transform("p_status_c")
    
    self._p_img_resident_a = self:Image("p_img_resident_a")
    self._p_img_resident_b = self:Image("p_img_resident_b")
    self._p_img_resident_c = self:Image("p_img_resident_c")
    
    self._p_progress_time_b = self:Slider("p_progress_time_b")
    self._p_progress_time_c = self:Slider("p_progress_time_c")

    self._p_status_c:SetVisible(false)
    self._p_img_select:SetVisible(false)
end

---@param data CityCitizenChooseCitizenCellData
function CityCitizenChooseCitizenCell:OnFeedData(data)
    self._data = data

    local config = self._data.citizenData._config
    self._p_text_name_resident.text = I18N.Get(config:Name())
    
    if data.citizenWork then
        self._needTick = true
        self._p_status_a:SetVisible(false)
        self._p_status_b:SetVisible(true)
        self._p_text_time:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(config:Icon()), self._p_img_resident_b)
    else
        self._needTick = false
        self._p_status_a:SetVisible(true)
        self._p_status_b:SetVisible(false)
        self._p_text_time:SetVisible(false)
        g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(config:Icon()), self._p_img_resident_a)
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
end

function CityCitizenChooseCitizenCell:OnRecycle(_)
    self._needTick = false
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
end

function CityCitizenChooseCitizenCell:OnClose()
    self._needTick = false
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
end

function CityCitizenChooseCitizenCell:TickSecond(delta)
    if not self._needTick then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local rate,leftTime = self._data.citizenWork:GetMakeProgress(nowTime)
    self._p_progress_time_b.value = rate
    self._p_text_time.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
end

function CityCitizenChooseCitizenCell:Select(_)
    self._p_img_select:SetVisible(true)
end

function CityCitizenChooseCitizenCell:UnSelect(_)
    self._p_img_select:SetVisible(false)
end

function CityCitizenChooseCitizenCell:OnClickSelf()
    self._data.onSelected(self._data.index)
end

return CityCitizenChooseCitizenCell

