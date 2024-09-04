local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class RadarPopupUpgradeMediator : BaseUIMediator
local RadarPopupUpgradeMediator = class('RadarPopupUpgradeMediator', BaseUIMediator)

function RadarPopupUpgradeMediator:OnCreate()
    self.luagoGroup = self:LuaObject('group_tips')
end

function RadarPopupUpgradeMediator:OnOpened()
    ---@type RadarPopupUpgradeCompParam
    local param = {}
    param.curlevel = ModuleRefer.RadarModule:GetRadarLv()
    param.type = 1
    param.levelTitleText = I18N.Get("bw_info_radarsystem_8")
    self.luagoGroup:FeedData(param)
end

function RadarPopupUpgradeMediator:OnClose()
    --TODO
end

return RadarPopupUpgradeMediator