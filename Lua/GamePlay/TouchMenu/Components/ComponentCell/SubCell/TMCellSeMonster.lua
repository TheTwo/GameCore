local BaseTableViewProCell = require ('BaseTableViewProCell')
local ShowVfxName = CS.FpAnimation.CommonTriggerType.Custom1
local HideVfxName = CS.FpAnimation.CommonTriggerType.Custom2

---@class TMCellSeMonster:BaseTableViewProCell
local TMCellSeMonster = class('TMCellSeMonster', BaseTableViewProCell)

function TMCellSeMonster:OnCreate()
    self._p_img_monster = self:Image("p_img_monster")
    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

---@param data TMCellSeMonsterDatum
function TMCellSeMonster:OnFeedData(data)
    self:LoadSprite(data.iconId, self._p_img_monster)
    if data.showVfx then
        self._vx_trigger:PlayAll(ShowVfxName)
    else
        self._vx_trigger:PlayAll(HideVfxName)
    end
end

return TMCellSeMonster
