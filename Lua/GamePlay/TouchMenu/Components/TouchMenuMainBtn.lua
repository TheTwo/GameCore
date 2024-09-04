local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')

---@class TouchMenuMainBtn:BaseUIComponent
local TouchMenuMainBtn = class('TouchMenuMainBtn', BaseUIComponent)

function TouchMenuMainBtn:OnCreate()
    self._transform = self:RectTransform("")
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._image = self:Image("")
    self._p_text = self:Text("p_text")
    self._p_group_resume = self:GameObject("p_group_resume")
    self._p_text_resume = self:Text("p_text_resume")
    self._p_icon_resume = self:Image("p_icon_resume")
end

---@param data TouchMenuMainBtnDatum
function TouchMenuMainBtn:OnFeedData(data)
    self.data = data
    self._p_text.text = data.label
    local showExtra = self:ShowExtra()
    self._p_group_resume:SetActive(showExtra)

    if self.data.enable then
        g_Game.SpriteManager:LoadSprite(self.data.customImage, self._image)
    else
        g_Game.SpriteManager:LoadSprite(self.data.customDisableImage, self._image)
    end

    if showExtra then
        self._p_text_resume.text = self:GetExtraText()
        if self.data.extraLabelColor then
            self._p_text_resume.color = self.data.extraLabelColor
        end
        local showImage = self:ShowImage()
        self._p_icon_resume:SetVisible(showImage)
        if showImage then
            g_Game.SpriteManager:LoadSprite(data.extraImage, self._p_icon_resume)
        end
    end
end

function TouchMenuMainBtn:ShowExtra()
    return not string.IsNullOrEmpty(self.data.extraLabel) or not string.IsNullOrEmpty(self.data.extraImage)
end

function TouchMenuMainBtn:GetExtraText()
    if string.IsNullOrEmpty(self.data.extraLabel) then
        return string.Empty
    end
    return self.data.extraLabel
end

function TouchMenuMainBtn:ShowImage()
    return not string.IsNullOrEmpty(self.data.extraImage)
end

function TouchMenuMainBtn:OnClick()
    if self.data.enable then
        if self.data.onClick then
            if not self.data.onClick(self.data.onClickDatum, self._transform) then
                local mediator = self:GetParentBaseUIMediator()
                if mediator then
                    mediator:CloseSelf()
                end
                self.data.onClick = nil
            end
        else
            if UNITY_EDITOR or UNITY_DEBUG then
                g_Logger.Error("空回调from:%s", tostring(self.data.where))
            end
        end
    else
        if self.data.onClickDisable then
            if not self.data.onClickDisable(self.data.onClickDatum, self._transform) then
                local mediator = self:GetParentBaseUIMediator()
                if mediator then
                    mediator:CloseSelf()
                end
                self.data.onClickDisable = nil
            end
        end
    end
end

return TouchMenuMainBtn
