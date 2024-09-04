local BaseUIComponent = require ('BaseUIComponent')
---@class NotificationNode : BaseUIComponent
local NotificationNode = class('NotificationNode', BaseUIComponent)

function NotificationNode:OnCreate()
    self.go = self:GameObject("")
    self.redDot = self:GameObject("p_type_1")
    self.redTextGo = self:GameObject("p_type_2")
    self.redNew = self:GameObject("p_type_3")
    self.redRecommend = self:GameObject("p_type_4")
    self.redNewText = self:Text("p_text_new", "New")
    self.redText = self:Text("p_text_num")
end

function NotificationNode:OnFeedData(param)

end

function NotificationNode:ShowNumRedDot(num)
    self.redDot:SetActive(false)
    self.redTextGo:SetActive(true)
    self.redNew:SetActive(false)
    if self.redRecommend then
        self.redRecommend:SetVisible(false)
    end
    self.redText.text = num
end

function NotificationNode:ShowRedDot()
    self.redDot:SetActive(true)
    self.redTextGo:SetActive(false)
    self.redNew:SetActive(false)
    if self.redRecommend then
        self.redRecommend:SetVisible(false)
    end
end
function NotificationNode:ShowNewRedDot()
    self.redDot:SetActive(false)
    self.redTextGo:SetActive(false)
    self.redNew:SetActive(true)
    if self.redRecommend then
        self.redRecommend:SetVisible(false)
    end
end

function NotificationNode:ShowRecommendDot()
    self.redDot:SetActive(false)
    self.redTextGo:SetActive(false)
    self.redNew:SetActive(false)
    if self.redRecommend then
        self.redRecommend:SetVisible(true)
    end
end

function NotificationNode:HideAllRedDot()
    self.redDot:SetActive(false)
    self.redTextGo:SetActive(false)
    self.redNew:SetActive(false)
    if self.redRecommend then
        self.redRecommend:SetVisible(false)
    end
end


return NotificationNode
