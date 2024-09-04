local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class GuideDemoPageBarCell : BaseTableViewProCell
local GuideDemoPageBarCell = class('GuideDemoPageBarCell', BaseTableViewProCell)

function GuideDemoPageBarCell:ctor()

end

function GuideDemoPageBarCell:OnCreate()
    ---@type CS.StatusRecordParent
    self.statusrecordparentItemBar = self:BindComponent('', typeof(CS.StatusRecordParent))
end


function GuideDemoPageBarCell:OnShow(param)
end

function GuideDemoPageBarCell:OnHide(param)
end

function GuideDemoPageBarCell:OnOpened(param)
end

function GuideDemoPageBarCell:OnClose(param)
end

function GuideDemoPageBarCell:OnFeedData(param)
    if param then
        self.statusrecordparentItemBar:Play(0)
    else
        self.statusrecordparentItemBar:Play(1)
    end
end




return GuideDemoPageBarCell
