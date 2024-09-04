local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')

---@class CommonBackButtonData
---@field title string
---@field hideClose boolean
---@field onDetailBtnClick fun(btnTrans:CS.UnityEngine.Transform)
---@field onClose fun()

---@class CommonBackButtonComponent : BaseUIComponent
---@field callback fun()
local CommonBackButtonComponent = class('CommonBackButtonComponent', BaseUIComponent)

function CommonBackButtonComponent:ctor()

end

function CommonBackButtonComponent:OnCreate()
    self.btnBack = self:Button('p_btn_back', Delegate.GetOrCreate(self, self.OnBtnBackClicked))
    self.btnClose = self:Button("p_btn_home", Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.textTxtFree2 = self:Text('p_txt_free_2');
    self.goBtnDetail = self:GameObject('child_comp_btn_detail')
    if self.goBtnDetail then
        self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
        self.goBtnDetail:SetVisible(false)
    end
end

---OnFeedData
---@param param CommonBackButtonData
function CommonBackButtonComponent:OnFeedData(param)
    if not param then
        return
    end
    self.textTxtFree2.text = param.title
    self.callback = param.onClose
    if param.hideClose then
        self.btnBack:SetVisible(false)
    end	
    if param.onDetailBtnClick and self.goBtnDetail then
        self.goBtnDetail:SetVisible(true)
        self.onDetailBtnClick = param.onDetailBtnClick
    end
end

---@param title string
function CommonBackButtonComponent:UpdateTitle(title)
    if self.textTxtFree2 and title then
        self.textTxtFree2.text = title
    end
end

function CommonBackButtonComponent:OnBtnBackClicked(args)
    if self.callback then
        self.callback()
	else
        local parentUIMediator = self:GetParentBaseUIMediator()
        if parentUIMediator then
            parentUIMediator:BackToPrevious()
        end
    end
end

function CommonBackButtonComponent:OnBtnCloseClicked()
    local parentUIMediator = self:GetParentBaseUIMediator()
    if parentUIMediator then
        parentUIMediator:CloseSelf()
    end
end

function CommonBackButtonComponent:OnBtnDetailClicked(args)
    if not self.onDetailBtnClick then
        return
    end
    self.onDetailBtnClick(self.btnDetail.transform)
end

return CommonBackButtonComponent
