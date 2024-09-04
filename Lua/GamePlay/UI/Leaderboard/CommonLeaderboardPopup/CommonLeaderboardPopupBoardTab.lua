local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
---@class CommonLeaderboardPopupBoardTab : BaseUIComponent
local CommonLeaderboardPopupBoardTab = class('CommonLeaderboardPopupBoardTab', BaseUIComponent)

---@class CommonLeaderboardPopupBoardTabParam
---@field title string
---@field isSelcted boolean
---@field onClick fun()

function CommonLeaderboardPopupBoardTab:OnCreate()
    self.statusCtrler = self:StatusRecordParent('')
    self.btn = self:Button('', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.goSelect = self:GameObject('p_base_a')
    self.textSelect = self:Text('p_text_a')
    self.goUnselect = self:GameObject('p_base_b')
    self.textUnselect = self:Text('p_text_b')
    self.notifyNode = self:LuaObject('p_reddot_player')
end

---@param param CommonLeaderboardPopupBoardTabParam
function CommonLeaderboardPopupBoardTab:OnFeedData(param)
    self.title = param.title
    self.onClick = param.onClick
    self.isSelcted = param.isSelcted
    self.textSelect.text = I18N.Get(self.title)
    self.textUnselect.text = I18N.Get(self.title)
    self.notifyNode:SetVisible(false)
end

function CommonLeaderboardPopupBoardTab:OnBtnClick()
    if self.onClick then
        self.onClick()
    end
end

function CommonLeaderboardPopupBoardTab:Select()
    self.isSelcted = true
    self.statusCtrler:ApplyStatusRecord(0)
end

function CommonLeaderboardPopupBoardTab:Unselect()
    self.isSelcted = false
    self.statusCtrler:ApplyStatusRecord(1)
end

function CommonLeaderboardPopupBoardTab:SetSelect(isSelect)
    if isSelect then
        self:Select()
    else
        self:Unselect()
    end
end

return CommonLeaderboardPopupBoardTab