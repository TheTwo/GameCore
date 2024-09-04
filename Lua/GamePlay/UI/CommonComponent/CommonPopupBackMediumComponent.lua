local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')

---@class CommonPopupBackMediumComponent : BaseUIComponent
---@field callback fun()
local CommonPopupBackMediumComponent = class('CommonPopupBackMediumComponent', BaseUIComponent)

function CommonPopupBackMediumComponent:ctor()

end

function CommonPopupBackMediumComponent:OnCreate()
    self.textTitle = self:Text('p_title')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
end

---@param param CommonBackButtonData
function CommonPopupBackMediumComponent:OnFeedData(param)
    if not param  then
        return
    end
    self.textTitle.text = I18N.Get(param.title)
    self.callback = param.onClose
    if param.hideClose then
        self.btnClose:SetVisible(false)
    end	
end

function CommonPopupBackMediumComponent:OnBtnCloseClicked(args)
    if self.callback then
        self.callback()
    else        
        local parentUIMediator = self:GetParentBaseUIMediator()
        if parentUIMediator then
            parentUIMediator:CloseSelf()
        end
    end
end

return CommonPopupBackMediumComponent;
