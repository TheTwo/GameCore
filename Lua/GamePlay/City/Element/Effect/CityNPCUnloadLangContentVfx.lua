local I18N = require("I18N")

---@class CityNPCUnloadLangContentVfx
---@field new fun():CityNPCUnloadLangContentVfx
---@field textContent CS.U2DTextMesh
local CityNPCUnloadLangContentVfx = class('CityNPCUnloadLangContentVfx')

function CityNPCUnloadLangContentVfx:SetLangContent(langKey)
    self.textContent.text = I18N.Get(langKey)
end

return CityNPCUnloadLangContentVfx