--- scene:scene_league_tips_behemoth_war

local Delegate = require("Delegate")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBehemothWarTipMediatorParameter
---@field icon string
---@field content string
---@field btnText string
---@field onGoto fun()

---@class AllianceBehemothWarTipMediator:BaseUIMediator
---@field new fun():AllianceBehemothWarTipMediator
---@field super BaseUIMediator
local AllianceBehemothWarTipMediator = class('AllianceBehemothWarTipMediator', BaseUIMediator)

function AllianceBehemothWarTipMediator:OnCreate(param)
    self._p_icon = self:Image("p_icon")
    self._p_text = self:Text("p_text")
    ---@see BistateButtonSmall
    self._child_comp_btn_b_s = self:LuaBaseComponent("child_comp_btn_b_s")
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
end

---@param param AllianceBehemothWarTipMediatorParameter
function AllianceBehemothWarTipMediator:OnOpened(param)
    self._param = param
    self._leftTime = 6
    ---@type BistateButtonSmallParam
    local btnParam = {}
    btnParam.onClick = Delegate.GetOrCreate(self, self.OnClickGoto)
    btnParam.buttonText = param.btnText
    self._child_comp_btn_b_s:FeedData(btnParam)
    g_Game.SpriteManager:LoadSprite(param.icon, self._p_icon)
    self._p_text.text = param.content
end

function AllianceBehemothWarTipMediator:OnShow(param)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
end

function AllianceBehemothWarTipMediator:OnHide(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
end

function AllianceBehemothWarTipMediator:SecTick(dt)
    if not self._leftTime then return end
    self._leftTime = self._leftTime - dt
    if self._leftTime < 0 then
        self:CloseSelf()
    end
end

function AllianceBehemothWarTipMediator:OnClickGoto()
    if self._param and self._param.onGoto then
        self._param.onGoto()
    end
end

return AllianceBehemothWarTipMediator