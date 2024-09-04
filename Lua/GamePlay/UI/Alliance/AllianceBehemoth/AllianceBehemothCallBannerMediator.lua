--- scene:scene_league_behemoth_call_banner

local I18N = require("I18N")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local Delegate = require("Delegate")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBehemothCallBannerMediatorParameter
---@field kMonsterConfig KmonsterDataConfigCell
---@field allianceName string
---@field abbr string
---@field level number

---@class AllianceBehemothCallBannerMediator:BaseUIMediator
---@field new fun():AllianceBehemothCallBannerMediator
---@field super BaseUIMediator
local AllianceBehemothCallBannerMediator = class('AllianceBehemothCallBannerMediator', BaseUIMediator)

function AllianceBehemothCallBannerMediator:OnCreate(param)
    self._p_icon_behemoth = self:Image("p_icon_behemoth")
    self._p_text_behemoth_name = self:Text("p_text_behemoth_name")
    self._p_text_behemoth_desc = self:Text("p_text_behemoth_desc")
end

function AllianceBehemothCallBannerMediator:OnShow()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function AllianceBehemothCallBannerMediator:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

---@param data AllianceBehemothCallBannerMediatorParameter
function AllianceBehemothCallBannerMediator:OnOpened(data)
    self._delayCloseTick = 1.73
    local name,_,_,_,_,bodyPaint = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(data.kMonsterConfig)
    self._p_text_behemoth_name.text = name
    self._p_text_behemoth_desc.text = I18N.GetWithParams("alliance_behemoth_summon_enter", ("[%s]%s"):format(data.abbr, data.allianceName) , data.level, name)
    g_Game.SpriteManager:LoadSprite(bodyPaint, self._p_icon_behemoth)
end

function AllianceBehemothCallBannerMediator:Tick(dt)
    if not self._delayCloseTick then
        return
    end
    self._delayCloseTick = self._delayCloseTick - dt
    if self._delayCloseTick <= 0 then
        self._delayCloseTick = nil
        self:CloseSelf()
    end
end

return AllianceBehemothCallBannerMediator