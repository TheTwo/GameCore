local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')

---@class UIPetFilterComp : BaseTableViewProCell
local UIPetFilterComp = class('UIPetFilterComp', BaseTableViewProCell)

---@class UIPetFilterCompData
---@field index number
---@field icon string
---@field text string
---@field onClick fun(index:number)

function UIPetFilterComp:ctor()

end

function UIPetFilterComp:OnCreate()
    self.statusRecordParent = self:StatusRecordParent('')
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_icon = self:Image('p_icon') or self:Image('icon')
    self.p_text = self:Text('p_text') or self:Text('text')
end

---@param param UIPetFilterCompData
function UIPetFilterComp:OnFeedData(param)
    self.param = param
    self.isSelected = false
    self.statusRecordParent:SetState(0)
    self.index = param.index
    if param.text and self.p_text then
        self.p_text.text = param.text
    end
    if param.icon and self.p_icon then
        g_Game.SpriteManager:LoadSprite(param.icon, self.p_icon)
    end
end

function UIPetFilterComp:OnBtnClick()
    self.param.onClick(self.index)
end

function UIPetFilterComp:IsSelect(isSelected)
    if isSelected == nil then
        return self.isSelected
    end
    if self.isSelected == isSelected then
        return
    end

    if isSelected then
        self.statusRecordParent:SetState(1)
        self.isSelected = true
    else
        self.statusRecordParent:SetState(0)
        self.isSelected = false
    end
end

return UIPetFilterComp
