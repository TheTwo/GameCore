local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')

local I18N = require('I18N')
---@class CommonDropDownItemData
---@field id number
---@field onClick fun(evt:number)
---@field iconName string
---@field text string
---@field showText string
---@field selected boolean


---@class CommonDropDownItem : BaseUIComponent
---@field btnItem CS.UnityEngine.UI.Button
---@field imgIcon1 CS.UnityEngine.UI.Image
---@field textTroops1 CS.UnityEngine.UI.Text
---@field btnId number
local CommonDropDownItem = class('CommonDropDownItem', BaseUIComponent)

function CommonDropDownItem:ctor()

end

function CommonDropDownItem:OnCreate()
    self.btnItem = self:Button('', Delegate.GetOrCreate(self, self.OnBtnItemClicked))
    --normal state
    self.imgIcon1 = self:Image('p_icon_1')
    self.textTroops1 = self:Text('p_text_troops_1')
    --selected state
    self.goSelect = self:GameObject('p_select')
    self.imgIcon2 = self:Image('p_icon_2')
    self.textTroops2 = self:Text('p_text_troops_2')
end


function CommonDropDownItem:OnShow(param)
end

function CommonDropDownItem:OnOpened(param)
end

function CommonDropDownItem:OnClose(param)
end

---OnFeedData
---@param param CommonDropDownItemData
function CommonDropDownItem:OnFeedData(param)
    if not param then return end
    self.onClick = param.onClick
    if param.selected then
        if string.IsNullOrEmpty(param.iconName) then
            self.imgIcon2:SetVisible(false)
        else
            self.imgIcon2:SetVisible(true)
            g_Game.SpriteManager:LoadSprite(param.iconName,self.imgIcon2)
        end
        self.textTroops2.text = I18N.Get(param.showText)
        self.goSelect:SetVisible(true)
    else
        if string.IsNullOrEmpty(param.iconName) then
            self.imgIcon1:SetVisible(false)
        else
            self.imgIcon1:SetVisible(true)
            g_Game.SpriteManager:LoadSprite(param.iconName,self.imgIcon1)
        end
        self.textTroops1.text = I18N.Get(param.showText)
        self.goSelect:SetVisible(false)
    end
    self.btnId = param.id
end



function CommonDropDownItem:OnBtnItemClicked(args)
    if self.onClick then
        self.onClick(self.btnId)
    end
end

return CommonDropDownItem;
