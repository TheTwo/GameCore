local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')

---@class CommonPopupBackLargeComponent : BaseUIComponent
---@field callback fun()
local CommonPopupBackLargeComponent = class('CommonPopupBackLargeComponent', BaseUIComponent)

function CommonPopupBackLargeComponent:ctor()

end

function CommonPopupBackLargeComponent:OnCreate()
    self.textTitle = self:Text('p_title')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
end

---@param param CommonBackButtonData
function CommonPopupBackLargeComponent:OnFeedData(param)
    if not param  then
        return
    end
    self.textTitle.text = I18N.Get(param.title)
    self.callback = param.onClose
    if param.hideClose then
        self.btnClose:SetVisible(false)
    end	
end

function CommonPopupBackLargeComponent:OnBtnCloseClicked(args)
    if self.callback then
        self.callback()
    else        
        local parentUIMediator = self:GetParentBaseUIMediator()
        if parentUIMediator then
            parentUIMediator:CloseSelf()
        end
    end
end

return CommonPopupBackLargeComponent;
