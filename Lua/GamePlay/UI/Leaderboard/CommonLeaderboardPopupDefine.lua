---@class CommonLeaderboardPopupDefine
local CommonLeaderboardPopupDefine = {}

local STYLE_MASK = {
    SHOW_BOARD = 1 << 0,
    SHOW_REWARD = 1 << 1,
    SHOW_CONTRIBUTION = 1 << 2,
    SHOW_TOP_PAGINATOR = 1 << 3,
}

CommonLeaderboardPopupDefine.STYLE_MASK = STYLE_MASK

return CommonLeaderboardPopupDefine