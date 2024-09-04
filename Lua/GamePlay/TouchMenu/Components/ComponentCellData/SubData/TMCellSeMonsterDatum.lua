---@class TMCellSeMonsterDatum
---@field new fun():TMCellSeMonsterDatum
local TMCellSeMonsterDatum = class("TMCellSeMonsterDatum")

function TMCellSeMonsterDatum:ctor(iconId, showVfx)
    self.iconId = iconId
    self.showVfx = showVfx
end

function TMCellSeMonsterDatum:SetIconId(iconId)
	self.iconId = iconId
    return self
end

function TMCellSeMonsterDatum:SetShowVfx(showVfx)
    self.showVfx = showVfx
    return self
end

return TMCellSeMonsterDatum
