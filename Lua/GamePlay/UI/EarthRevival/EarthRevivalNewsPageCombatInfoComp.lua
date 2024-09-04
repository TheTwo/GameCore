local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class EarthRevivalNewsPageCombatInfoComp : BaseUIComponent
local EarthRevivalNewsPageCombatInfoComp = class('EarthRevivalNewsPageCombatInfoComp', BaseUIComponent)

---@class EarthRevivalNewsPageCombatInfoCompParam
---@field damageInfo wds.DamagePlayerInfo
---@field title string

function EarthRevivalNewsPageCombatInfoComp:OnCreate()
    self.luagoPortrait = self:LuaObject('p_head_player_leader')
    self.textTitle = self:Text('p_text_title')
    self.textName = self:Text('p_text_name')
end

---@param param EarthRevivalNewsPageCombatInfoCompParam
function EarthRevivalNewsPageCombatInfoComp:OnFeedData(param)
    if not param then
        return
    end
    self.luagoPortrait:FeedData(param.damageInfo.PortraitInfo)
    self.textTitle.text = param.title
    self.textName.text = I18N.Get(param.damageInfo.Name)
end

return EarthRevivalNewsPageCombatInfoComp