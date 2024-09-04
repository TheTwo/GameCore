---Scene Name : scene_city_popup_gain
local BaseUIMediator = require ('BaseUIMediator')
---@class CityOfflineIncomeUIMediator:BaseUIMediator
local CityOfflineIncomeUIMediator = class('CityOfflineIncomeUIMediator', BaseUIMediator)
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local CastleGetStockRoomResParameter = require("CastleGetStockRoomResParameter")

function CityOfflineIncomeUIMediator:OnCreate()
    self._p_text_title = self:Text("p_text_title", "mobile_forces_offline_popup_01")
    self._p_text_time = self:Text("p_text_time", "mobile_forces_offline_popup_03")
    self._p_text_time_1 = self:Text("p_text_time_1")
    
    ---离线时间满收益进度条
    self._p_progress_time = self:Slider("p_progress_time")
    self._p_text_time_number = self:Text("p_text_time_number")
    
    self._p_text_gain = self:Text("p_text_gain", "mobile_forces_offline_popup_02")

    ---收益道具列表
    self._p_table_list = self:TableViewPro("p_table_list")
    self._p_text_hint = self:Text("p_text_hint", "gacha_result_next")
end

---@param param CityOfflineIncomeUIParameter
function CityOfflineIncomeUIMediator:OnOpened(param)
    self.param = param
    self._p_progress_time.value = param:GetOfflineIncomeProgress()
    self._p_text_time_number.text = param:GetOfflineIncomeTimeText()

    local maxTime = param:GetMaxOfflineIncomeTime()
    self._p_text_time_1.text = I18N.GetWithParams("mobile_forces_offline_popup_04", TimeFormatter.TimerStringFormat(maxTime))

    self._p_table_list:Clear()
    for i, v in ipairs(param:GetIncomeList()) do
        self._p_table_list:AppendData(v)
    end
    g_Game.SoundManager:Play("sfx_building_repair")
end

function CityOfflineIncomeUIMediator:OnClose()
    if self.param then
        self.param:RequestClaimOfflineIncome()
    end
end

return CityOfflineIncomeUIMediator