local KingdomView = require("KingdomView")

local LuaKingdomView = CS.Grid.LuaKingdomView

---@class KingdomViewFactory
local KingdomViewFactory = class("KingdomViewFactory")

function KingdomViewFactory:Create(version)
    return LuaKingdomView(KingdomView.new())
end

return KingdomViewFactory