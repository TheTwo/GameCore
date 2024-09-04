local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local Utils = require("Utils")

---@class CommonPopupBackSmallComponent : BaseUIComponent
---@field callback fun()
local CommonPopupBackSmallComponent = class('CommonPopupBackSmallComponent', BaseUIComponent)

function CommonPopupBackSmallComponent:ctor()

end

function CommonPopupBackSmallComponent:OnCreate()
    self.textTitle = self:Text('p_title')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
end

---@param param CommonBackButtonData
function CommonPopupBackSmallComponent:OnFeedData(param)
    if not param  then
        return
    end
    if Utils.IsNotNull(self.textTitle) then
        self.textTitle.text = I18N.Get(param.title)
    end
    self.callback = param.onClose
    if Utils.IsNotNull(self.btnClose) then
        if param.hideClose then
            self.btnClose:SetVisible(false)
        end
    end	
end

function CommonPopupBackSmallComponent:OnBtnCloseClicked(args)
    if self.callback then
        self.callback()
    else        
        local parentUIMediator = self:GetParentBaseUIMediator()
        if parentUIMediator then
            parentUIMediator:CloseSelf()
        end
    end
end

return CommonPopupBackSmallComponent;
