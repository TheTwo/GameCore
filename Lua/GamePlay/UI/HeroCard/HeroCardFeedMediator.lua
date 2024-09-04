local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local HeroCardFeedMediator = class('HeroCardFeedMediator',BaseUIMediator)

function HeroCardFeedMediator:OnCreate()
    BaseUIMediator.OnCreate(self)
    self.tableviewproTable = self:TableViewPro('p_table')
    self.aniTrigger = self:AnimTrigger('vx_trigger')
end

function HeroCardFeedMediator:OnOpened(param)
    self.curSelectType = param.selectType
    self.isOne = param.isOne
    self.gachaCfg = ConfigRefer.GachaType:Find(self.curSelectType)
    local icons = self:RandomIcons()
    self.tableviewproTable:Clear()
    for index, icon in ipairs(icons) do
        self.tableviewproTable:AppendData({index = index - 1, icon = icon, isOne = self.isOne})
    end
    ModuleRefer.ToastModule:BlockToast()
end

function HeroCardFeedMediator:OnClose(param)

end

function HeroCardFeedMediator:PlayHide()
    self.aniTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
end

function HeroCardFeedMediator:RandomIcons()
    local needNum = self.gachaCfg:UseItemNum()
    local results = {}
    local icons = {}
    for i = 1, needNum do
        local randomIndex = self:RandomIndex(results)
        results[randomIndex] = true
        icons[i] = self.gachaCfg:UseItemIcon(randomIndex)
    end
    if ModuleRefer.HeroCardModule:CheckIsFirstGacha() then
        icons[1] = "sp_icon_item_tie"
    end
    return icons
end

function HeroCardFeedMediator:RandomIndex(results)
    local iconCount = self.gachaCfg:UseItemIconLength()
    local randomNum = math.random(1, iconCount)
    if results[randomNum] then
        return self:RandomIndex(results)
    else
        return randomNum
    end
end



return HeroCardFeedMediator