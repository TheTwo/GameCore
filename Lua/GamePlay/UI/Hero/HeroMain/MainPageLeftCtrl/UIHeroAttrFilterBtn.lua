local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
---@class UIHeroAttrFilterBtn : BaseUIComponent
local UIHeroAttrFilterBtn = class("UIHeroAttrFilterBtn", BaseUIComponent)

---@class UIHeroAttrFilterBtnData
---@field index number
---@field tagId number

function UIHeroAttrFilterBtn:ctor()
end

function UIHeroAttrFilterBtn:OnCreate()
    self.btnRoot = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self.imgIcon = self:Image("p_icon_sttribute")
    self.statusRoot = self:StatusRecordParent("")
end

---@param data UIHeroAttrFilterBtnData
function UIHeroAttrFilterBtn:OnFeedData(data)
    self.data = data
    self.index = data.index
    self.tagId = data.tagId

    local tag = ConfigRefer.AssociatedTag:Find(self.tagId)
    if tag then
        local iconId = tag:Icon()
		local artResource = ConfigRefer.ArtResourceUI:Find(iconId)
		local iconPath = ""
		if artResource then
			iconPath = artResource:Path()
		end
        g_Game.SpriteManager:LoadSprite(iconPath, self.imgIcon)
    end
end

function UIHeroAttrFilterBtn:SetSelect(select)
    if select then
        self.statusRoot:ApplyStatusRecord(1)
    else
        self.statusRoot:ApplyStatusRecord(0)
    end
end

function UIHeroAttrFilterBtn:OnClick()
    g_Game.EventManager:TriggerEvent(EventConst.HERO_STYLE_FILTER_CLICK, self.index, self.tagId)
end

return UIHeroAttrFilterBtn