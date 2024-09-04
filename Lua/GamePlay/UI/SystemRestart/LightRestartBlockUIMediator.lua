---Scene Name : non; Prefab Name : LoadingFlag_3
local BaseUIMediator = require ('BaseUIMediator')

---@class LightRestartBlockUIMediator:BaseUIMediator
local LightRestartBlockUIMediator = class('LightRestartBlockUIMediator', BaseUIMediator)

function LightRestartBlockUIMediator:OnCreate()
    self._p_text_tips = self:Text("p_text_tips", "reconnect_tip")
end

return LightRestartBlockUIMediator