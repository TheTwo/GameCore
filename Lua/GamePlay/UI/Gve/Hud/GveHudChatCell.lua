local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
---@class GveHudChatCell : BaseTableViewProCell
local GveHudChatCell = class('GveHudChatCell', BaseTableViewProCell)

function GveHudChatCell:ctor()

end

function GveHudChatCell:OnCreate()
    
    self.textChatCell = self:Text('p_text_chat_cell')
end


function GveHudChatCell:OnShow(param)
end

function GveHudChatCell:OnHide(param)
end

function GveHudChatCell:OnOpened(param)
end

function GveHudChatCell:OnClose(param)
end

function GveHudChatCell:OnFeedData(param)
    if param.isSelf then
        self.textChatCell.text = UIHelper.GetColoredText( param.name,"#44f5a0" ).. ':' .. param.text
    else
        self.textChatCell.text = param.name .. ':' .. param.text
    end
end




return GveHudChatCell
