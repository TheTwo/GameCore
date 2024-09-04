local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class UIPlayerPortraitTableCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIPlayerPortraitTableCell = class('UIPlayerPortraitTableCell', BaseTableViewProCell)

---@class UIPlayerPortraitTableCellParam
---@field id number
---@field selected boolean
---@field onClick fun(id:number)
---@field inUse boolean
---@field status wds.enum.AvatarStatus
---@field customAvatar string

function UIPlayerPortraitTableCell:ctor()

end

function UIPlayerPortraitTableCell:OnCreate()
	self.selectedNode = self:GameObject("child_img_select_circle_s")
	---@type PlayerInfoComponent
	self.portrait = self:LuaObject("child_ui_head_player")
	self.portrait:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnClick))
	self.btnCell = self:Button("", Delegate.GetOrCreate(self, self.OnClickUpLoad))
	self.inUseNode = self:GameObject("p_use")
	self.inUseText = self:Text("p_text_use", "playerinfo_inuse")

	self.statusHead = self:StatusRecordParent("")
	self.textAudit = self:Text("p_text_audit", "skincollection_avatar_upload_examining")
end


function UIPlayerPortraitTableCell:OnShow(param)
end

function UIPlayerPortraitTableCell:OnOpened(param)
end

function UIPlayerPortraitTableCell:OnClose(param)
end

---@param param UIPlayerPortraitTableCellParam
function UIPlayerPortraitTableCell:OnFeedData(param)
	if (param) then
		self.id = param.id
		self.selected = param.selected
		self.onClick = param.onClick
		self.inUse = param.inUse
		if param.status then
			self.upLoadType = param.status
		end
		if param.customAvatar then
			self.customAvatar = param.customAvatar
		end
	end
	if (not self.id) then self.id = 0 end
	if self.upLoadType then
		if self.upLoadType == wds.enum.AvatarStatus.AvatarStatusReviewing then
			self.statusHead:ApplyStatusRecord(2)
		elseif self.upLoadType == wds.enum.AvatarStatus.AvatarStatusPass or not string.IsNullOrEmpty(self.customAvatar) then
			self.statusHead:ApplyStatusRecord(3)
			if not string.IsNullOrEmpty(self.customAvatar) then
				---@type wds.PortraitInfo
				local portraitInfo = wds.PortraitInfo.New()
				portraitInfo.PlayerPortrait = 0
				portraitInfo.PortraitFrameId = 0
				portraitInfo.CustomAvatar = self.customAvatar
				self.portrait:FeedData(portraitInfo)
			end
		else
			self.statusHead:ApplyStatusRecord(1)
		end
	else
		self.statusHead:ApplyStatusRecord(0)
		self.portrait:FeedData({
			iconId = self.id
		})
	end
	self.selectedNode:SetActive(self.selected)
	self.inUseNode:SetActive(self.inUse)
end

function UIPlayerPortraitTableCell:Select(param)

end

function UIPlayerPortraitTableCell:UnSelect(param)

end

function UIPlayerPortraitTableCell:OnClick(args)
	if (self.onClick and self.upLoadType) then
		self.onClick(self.upLoadType)
		return
	end
	if (self.onClick) then
		self.onClick(self.id)
	end
end

function UIPlayerPortraitTableCell:OnClickUpLoad(args)
	if (self.onClick and self.upLoadType) then
		self.onClick(self.upLoadType)
	end
end

return UIPlayerPortraitTableCell;
