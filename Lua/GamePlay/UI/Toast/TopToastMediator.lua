local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local ArtResourceUtils = require("ArtResourceUtils")

---@class TopToastMediator : BaseUIMediator
local TopToastMediator = class('TopToastMediator', BaseUIMediator)
local DURATION = 3

---@class TopToastParameter
---@field content string
---@field details string
---@field imageId number|nil

function TopToastMediator:ctor()
    ---@type number
    self.openTime = 0
end

function TopToastMediator:OnCreate()
    self.textContent = self:Text('p_text_content')
    self.textDetails = self:Text('p_text_detail')
    self.imgIcon = self:Image("p_icon")
end

---@param param TopToastParameter
function TopToastMediator:OnOpened(param)
    if not param then
        return
    end
    self.textContent.text = param.content
    self.textDetails.text = param.details
    if param.imageId then
        local image = ArtResourceUtils.GetUIItem(param.imageId)
        if string.IsNullOrEmpty(image) then
            self.imgIcon.gameObject:SetActive(false)
        else
            self.imgIcon.gameObject:SetActive(true)
            g_Game.SpriteManager:LoadSprite(image, self.imgIcon)
        end
    else
        self.imgIcon.gameObject:SetActive(false)
    end

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function TopToastMediator:OnClose(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

---@field delta number
function TopToastMediator:Tick(delta)
    self.openTime = self.openTime + delta
    if self.openTime > DURATION then
        g_Game.UIManager:Close(self.runtimeId)
    end
end

return TopToastMediator
