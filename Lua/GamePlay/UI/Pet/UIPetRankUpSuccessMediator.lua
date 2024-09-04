local BaseUIMediator = require ('BaseUIMediator')

---@class UIPetRankUpSuccessMediator : BaseUIMediator
local UIPetRankUpSuccessMediator = class('UIPetRankUpSuccessMediator', BaseUIMediator)

function UIPetRankUpSuccessMediator:ctor()

end

function UIPetRankUpSuccessMediator:OnCreate()
	self:InitObjects()
end

function UIPetRankUpSuccessMediator:InitObjects()
	self.rankText = self:Text("p_text_strengthen")
	self.rankNextText = self:Text("p_text_strengthen_next")
	self.attrDescText = self:Text("p_text_detail")
	self.attrValueText = self:Text("p_text_num")
	self.attrValueOldText = self:Text("p_text_num_0")
	self.hintText = self:Text("p_text_hint", "tech_info_close")
end

function UIPetRankUpSuccessMediator:OnShow(param)
	if (not param) then return end
	self.rankText.text = tostring(param.rank)
	self.rankNextText.text = tostring(param.rankNext)
	self.attrDescText.text = param.attrDesc
	self.attrValueText.text = param.attrValue .. "%"
	self.attrValueOldText.text = param.attrValueOld .. "%"
end

function UIPetRankUpSuccessMediator:OnHide(param)
end

function UIPetRankUpSuccessMediator:OnOpened(param)
end

function UIPetRankUpSuccessMediator:OnClose(param)

end

return UIPetRankUpSuccessMediator
