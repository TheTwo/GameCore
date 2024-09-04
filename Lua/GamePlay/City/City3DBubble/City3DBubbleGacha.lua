---@class City3DBubbleGacha
local City3DBubbleGacha = class("City3DBubbleGacha")
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')

function City3DBubbleGacha:RefreshState()
    local isOpen = ModuleRefer.HeroCardModule:CheckIsOpenGacha()
    local freeTime = ModuleRefer.HeroCardModule:GetFreeTime()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local isFree = freeTime ~= 0 and curTime >= freeTime
    self.p_group_draw_free.gameObject:SetActive(isFree and isOpen)
    self.p_text_free.text = I18N.Get("gacha_freegacha")
    self.p_group_draw.gameObject:SetActive(false)
    if isOpen and not isFree then
        local curNum = ModuleRefer.HeroCardModule:GetTenDrawCostItemNum()
        self.p_group_draw.gameObject:SetActive(true)
        self.p_text_number.text = curNum
    end
end

return City3DBubbleGacha