local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')

---@class CommonSmallBackButtonComponent : BaseUIComponent
---@field onCloseBtnClick fun()
local CommonSmallBackButtonComponent = class('CommonSmallBackButtonComponent', BaseUIComponent)

function CommonSmallBackButtonComponent:ctor()

end

function CommonSmallBackButtonComponent:OnCreate()    
    self.btnChildCommonBackS = self:Button('', Delegate.GetOrCreate(self, self.OnBtnChildCommonBackSClicked))
end

---@param param CommonBackButtonData
function CommonSmallBackButtonComponent:OnFeedData(param)
    if not param then
        return
    end   
    self.onCloseBtnClick = param.onClose
end



function CommonSmallBackButtonComponent:OnBtnChildCommonBackSClicked(args)
    if self.onCloseBtnClick then
        self.onCloseBtnClick()
	else
        local parentUIMediator = self:GetParentBaseUIMediator()
        if parentUIMediator then
            parentUIMediator:BackToPrevious()
        end
    end
end

return CommonSmallBackButtonComponent
