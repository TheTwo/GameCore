local CommonPetIconBase = require("CommonPetIconBase")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
---@class LeaderboardUIPetCircle : CommonPetIconBase
local LeaderboardUIPetCircle = class("LeaderboardUIPetCircle", CommonPetIconBase)

---@class LeaderboardUIPetCircleData : CommonPetIconBase
---@field type number @LeaderboardUIPetCircleType
---@field cfgId number
---@field level number

local LeaderboardUIPetCircleType = {
    Pet = 1,
    Behemoth = 2
}

LeaderboardUIPetCircle.Type = LeaderboardUIPetCircleType

---@param param LeaderboardUIPetCircleData
function LeaderboardUIPetCircle:OnFeedData(param)
    if (param or {}).type == LeaderboardUIPetCircleType.Behemoth then
        self.cfgId = param.cfgId
        self.level = param.level
        self.data = param
        self:RefreshUI()
    else
        self.super.OnFeedData(self, param)
    end
end

function LeaderboardUIPetCircle:RefreshUI()
    if self.data.type == LeaderboardUIPetCircleType.Behemoth then
        self:RefreshBehemothUI()
    else
        self.super.RefreshUI(self)
    end
end

function LeaderboardUIPetCircle:RefreshBehemothUI()
    local behemothCfg = ConfigRefer.KmonsterData:Find(self.cfgId)
    local _, icon = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(behemothCfg)
    g_Game.SpriteManager:LoadSprite(icon, self._icon)
    self._txtLevel.text = self.level
    self._goStarLevel:SetActive(false)
end

return LeaderboardUIPetCircle