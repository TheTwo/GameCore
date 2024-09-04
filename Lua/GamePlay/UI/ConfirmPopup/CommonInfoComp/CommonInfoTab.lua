local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require('Delegate')

---@class CommonInfoTab : BaseTableViewProCell
local CommonInfoTab = class("CommonInfoTab", BaseTableViewProCell)

---@class CommonInfoTabParam
---@field selected boolean
---@field icon string
---@field onClick fun()

function CommonInfoTab:OnCreate()
    self.statusRecordParent = self:StatusRecordParent('')
    self.p_icon_selected = self:Image('p_icon_selected')
    self.p_icon_unselected = self:Image('p_icon_unselected')
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnBtnClick))
end

---@param param CommonInfoTabParam
function CommonInfoTab:OnFeedData(param)
    self.selected = param.selected
    self.onClick = param.onClick
    g_Game.SpriteManager:LoadSprite(param.icon, self.p_icon_selected)
    g_Game.SpriteManager:LoadSprite(param.icon, self.p_icon_unselected)
    self:RefreshStatus()
end

function CommonInfoTab:RefreshStatus()
    if self.selected then
        self.statusRecordParent:SetState(1)
    else
        self.statusRecordParent:SetState(0)
    end
end

function CommonInfoTab:OnBtnClick(param)
    if self.onClick then
        self.onClick()
    end
end

function CommonInfoTab:ChangeSelectTab(selected)
    self.selected = selected
    self:RefreshStatus()
end
return CommonInfoTab
