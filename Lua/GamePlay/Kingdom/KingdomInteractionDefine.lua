---@class KingdomInteractionDefine
local KingdomInteractionDefine = {}

---@class KingdomInteractionDefine.InteractionPriority
KingdomInteractionDefine.InteractionPriority = {
    RadarBubble = -3,
    WorldEvent = -2,
    SLGTouchManager = -1,
    KingdomMediator = 1,
    KingdomView = 3,
}

return KingdomInteractionDefine