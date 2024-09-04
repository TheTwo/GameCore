local I18N = require("I18N")
local AllianceModuleDefine = require("AllianceModuleDefine")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceAuthorityPositionTitleComponentData
---@field title AllianceTitleConfigCell
---@field player wds.AllianceMember

---@class AllianceAuthorityPositionTitleComponent:BaseUIComponent
---@field new fun():AllianceAuthorityPositionTitleComponent
---@field super BaseUIComponent
local AllianceAuthorityPositionTitleComponent = class('AllianceAuthorityPositionTitleComponent', BaseUIComponent)

function AllianceAuthorityPositionTitleComponent:OnCreate(param)
    self._p_icon_none = self:Image("p_icon_none")
    self._p_head = self:GameObject("p_head")
    self._p_frame_head = self:Image("p_frame_head")
    self._p_text_position = self:Text("p_text_position")
    self._p_text_name = self:Text("p_text_name")
    self._p_icon_logo = self:Image("p_icon_logo")
    ---@type CS.UnityEngine.UI.Text[]
    self._buffTexts = {}
    self._buffTexts[1] = self:Text("p_text_buff_a")
    self._buffTexts[2] = self:Text("p_text_buff_b")
end

---@param data AllianceAuthorityPositionTitleComponentData
function AllianceAuthorityPositionTitleComponent:OnFeedData(data)
    if not data.player then
        self._p_icon_none:SetVisible(true)
        self._p_head:SetVisible(false)
        self._p_text_position:SetVisible(true)
        self._p_text_name.text = I18N.Get(data.title:KeyId())
    else
        self._p_text_position:SetVisible(false)
        self._p_icon_none:SetVisible(false)
        self._p_head:SetVisible(true)
        self._p_text_name.text = data.player.Name
        self._p_text_position.text = I18N.Get(data.title:KeyId())
    end
    g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetAllianceTitleIcon(data.title), self._p_icon_logo)
    --todo need slg buff
    for i = 1, #self._buffTexts do
        self._buffTexts[i]:SetVisible(false)
        --self._buffTexts[i].text = I18N.GetWithParams("#buff空位{1}", tostring(i))
    end
end

return AllianceAuthorityPositionTitleComponent