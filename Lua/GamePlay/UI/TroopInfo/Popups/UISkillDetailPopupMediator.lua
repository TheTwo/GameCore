local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local UIHelper = require('UIHelper')
local I18N = require('I18N')

---@class UISkillDetailPopupParam
---@field title string
---@field skillTitle string
---@field skillIds number[]


---@class UISkillDetailPopupMediator : BaseUIMediator
local UISkillDetailPopupMediator = class('UISkillDetailPopupMediator', BaseUIMediator)

function UISkillDetailPopupMediator:ctor()

end

function UISkillDetailPopupMediator:OnCreate()
    
    self.textTitle = self:Text('p_text_title')
    self.goItemTitle1 = self:GameObject('p_item_title_1')
    self.textGain = self:Text('p_text_gain')
    self.compItemSkill = self:LuaBaseComponent('p_item_skill')
    self.goGroupEmpty = self:GameObject('p_group_empty')
    self.textEmpty = self:Text('p_text_empty',"[*]Empty")
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
end


function UISkillDetailPopupMediator:OnShow(param)
    self.textTitle.text = I18N.Get(param.title)
    self.textGain.text = I18N.Get(param.skillTitle)
    if param.skillIds and #param.skillIds > 0 then
        self.goGroupEmpty:SetActive(false)
        self.compItemSkill:SetVisible(true)
        self.compItemSkill:FeedData(param.skillIds[1])
        if #param.skillIds > 1 then
            local itemParent = self.compItemSkill.transform.parent
            for i = 2, #param.skillIds do
                -- body
                local comp = UIHelper.DuplicateUIComponent(self.compItemSkill, itemParent)
                comp:FeedData(param.skillIds[i])
            end
        end
    else
        self.goGroupEmpty:SetActive(true)
        self.compItemSkill:SetVisible(false)
    end
end

function UISkillDetailPopupMediator:OnHide(param)
end

function UISkillDetailPopupMediator:OnOpened(param)
end

function UISkillDetailPopupMediator:OnClose(param)
end



function UISkillDetailPopupMediator:OnBtnCloseClicked(args)
    self:CloseSelf()
end

return UISkillDetailPopupMediator
