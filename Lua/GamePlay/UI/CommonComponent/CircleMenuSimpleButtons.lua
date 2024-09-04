local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')

---@class CircleMenuSimpleButtons : BaseUIComponent
---@field buttonDatas CircleMenuSimpleButtonData[]
---@field buttons CS.DragonReborn.UI.LuaBaseComponent[]
local CircleMenuSimpleButtons = class('CircleMenuSimpleButtons', BaseUIComponent)

function CircleMenuSimpleButtons:ctor()

end

function CircleMenuSimpleButtons:OnCreate()
    self.buttonTmp = self:LuaBaseComponent('p_btn_troop')
end


function CircleMenuSimpleButtons:OnShow(param)
end

function CircleMenuSimpleButtons:OnHide(param)
end

function CircleMenuSimpleButtons:OnOpened(param)
end

function CircleMenuSimpleButtons:OnClose(param)
end

---@param param CircleMenuSimpleButtonData[]
function CircleMenuSimpleButtons:OnFeedData(param)
    if not param then return end
    self.buttonDatas = param
    if not self.buttons then
        self.buttons = {self.buttonTmp}
    end

    if #self.buttons > 0 then
        for _, button in ipairs(self.buttons) do
            button:SetVisible(false)
        end
    end
    self:InvokeClearFunctions()
    for i = 1, #self.buttonDatas do
        local data = self.buttonDatas[i]
        if not data then goto continue end

        if self.buttons[i] == nil then
            self.buttons[i] = UIHelper.DuplicateUIComponent(self.buttonTmp)           
        end
        self.buttons[i]:SetVisible(true)
        ::continue::
    end

    for i = 1, #self.buttonDatas do
        local data = self.buttonDatas[i]
        if not data then goto continue end
        self.buttons[i]:FeedData(data)
        ::continue::
    end
end

return CircleMenuSimpleButtons;
