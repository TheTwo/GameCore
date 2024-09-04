---@class KingdomTouchInfoProvider
local KingdomTouchInfoProvider = class("KingdomTouchInfoProvider")

function KingdomTouchInfoProvider:ctor()
    ---@protected
    self.__context = nil
end

function KingdomTouchInfoProvider:SetContext(context)
    self.__context = context
end

---@param tile MapRetrieveResult
function KingdomTouchInfoProvider:CreateBasicInfo(tile)

end

---@param tile MapRetrieveResult
function KingdomTouchInfoProvider:CreateDetailInfo(tile)

end

---@param tile MapRetrieveResult
---@return TouchMenuButtonTipsData
function KingdomTouchInfoProvider:CreateTipData(tile)

end

---@param tile MapRetrieveResult
function KingdomTouchInfoProvider:CreateButtonInfo(tile)

end

return KingdomTouchInfoProvider