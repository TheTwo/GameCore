local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
---@type MailModule
local Mail = ModuleRefer.MailModule
local UIHelper = require("UIHelper")
local MailBoxType = require("MailBoxType")

---@class MailTitleItemTableViewCell : BaseTableViewProCell
---@field super BaseTableViewProCell
local MailTitleItemTableViewCell = class('MailTitleItemTableViewCell', BaseTableViewProCell)

local ICON_BASE_SELECTED = "sp_mail_base_b"
local ICON_BASE_UNSELECTED = "sp_mail_base_a"

function MailTitleItemTableViewCell:ctor()
    MailTitleItemTableViewCell.super.ctor(self)
    self.id = 0
end

function MailTitleItemTableViewCell:OnCreate(param)
    self.button = self:Button("cell", Delegate.GetOrCreate(self, self.OnClick))
    self.canvasGroup = self:BindComponent("content", typeof(CS.UnityEngine.CanvasGroup))
    self.selectedNode = self:GameObject('p_img_select')
	self.iconBase = self:Image("base_icon")
    self.icon = self:Image('p_icon_mail')
	self.iconRead = self:Image("p_icon_mail_read")
	self.iconTime = self:Image("p_icon_time")
    self.title = self:Text('p_text_title_mail')
    self.senderName = self:Text('p_text_name')
    self.sendTime = self:Text('p_text_time')
    self.timerNode = self:GameObject('p_icon_time')
    self.reward = self:GameObject('p_icon_gift')
    self.rewardCollected = self:GameObject("p_icon_gift_received")
    self.favoriteNode = self:GameObject('p_icon_collect')
end

function MailTitleItemTableViewCell:OnFeedData(param)
    if (not param) then return end
    self.id = param.id
    local mail = Mail:GetMail(self.id)
    if (not mail) then
        self.CSComponent.gameObject:SetActive(false)
        return
    end
    local mailCfg = ConfigRefer.Mail:Find(mail.mailTid)
    local title = I18N.Get(mail.Title)
    local senderName = mail.Sender.Name
    local sendTime = Mail:GetElapsedTimeString(self.id)
    local reward = Mail:HasAttachment(self.id)
    local claimed = mail.Claimed or false
    local timer = reward
    local expired = Mail:IsExpired(self.id)
    
    if (mailCfg) then
		-- 战报
		if (mail.MailBoxType == MailBoxType.BattleReport) then
			local t, _, color , color_selected = Mail:GetBattleReportTitle(mail.BattleReport)
			title = UIHelper.GetColoredText(I18N.Get(t), param.selected and color_selected or color)
			local targetName = Mail:GetBattleReportTargetName(mail.BattleReport)
			senderName = Mail:GetBattleReportBattleAgainstTargetText(targetName)
		-- 普通
		else
			title = I18N.Get(mailCfg:Title())
			senderName = I18N.Get(mailCfg:Sender())
		end
    end
	self.canvasGroup.alpha = ModuleRefer.MailModule:GetTitleContentAlpha(param.selected == true, mail.Read == true)
	self.title.color = ModuleRefer.MailModule:GetTitleTextColor(param.selected == true, mail.Read == true)
	self.senderName.color = ModuleRefer.MailModule:GetTitleSenderNameColor(param.selected == true, mail.Read == true)
	self.sendTime.color = ModuleRefer.MailModule:GetTitleSendTimeColor(param.selected == true, mail.Read == true)
    if (mail.Read == true) then
		self.icon.gameObject:SetActive(false)
		self.iconRead.gameObject:SetActive(true)
	else
		self.icon.gameObject:SetActive(true)
		self.iconRead.gameObject:SetActive(false)
    end

    self.selectedNode:SetActive(param.selected == true)
	if (param.selected == true) then
		self.icon.color = ModuleRefer.MailModule:GetTitleTextColor(true, true)
		g_Game.SpriteManager:LoadSprite(ICON_BASE_SELECTED, self.iconBase)
	else
		self.icon.color = ModuleRefer.MailModule:GetTitleTextColor(false, true)
		g_Game.SpriteManager:LoadSprite(ICON_BASE_UNSELECTED, self.iconBase)
	end
	self.iconRead.color = self.icon.color
	self.iconTime.color = self.icon.color
    self.title.text = title
    self.senderName.text = senderName
    self.sendTime.text = sendTime
    self.timerNode:SetActive(timer == true)
    self.reward:SetActive(reward == true and not claimed)
    self.rewardCollected:SetActive(reward == true and claimed)
    UIHelper.SetGray(self.reward, expired == true)
    self.favoriteNode:SetActive(mail.Favourite == true)
    self.onClick = param.onClick
end

function MailTitleItemTableViewCell:OnClick()
    if (self.onClick) then
        self.onClick(self.id)
    end
end

return MailTitleItemTableViewCell;
