local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local UIHelper = require('UIHelper')
local ModuleRefer = require('ModuleRefer')

---@class CommonResourceBtnData
---@field content string
---@field isShowPlus boolean
---@field iconName string
---@field onClick fun()

---@class CommonResourceBtnSimplifiedData
---@field itemId number
---@field isShowPlus boolean
---@field onClick fun()

---@class CommonResourceBtn:BaseUIComponent
local CommonResourceBtn = class('CommonResourceBtn', BaseUIComponent)

function CommonResourceBtn:OnCreate()
    self.btnChildCapsule = self:Button('', Delegate.GetOrCreate(self, self.OnBtnChildCapsuleClicked))
    self.p_icon_capsule = self:Button('p_icon_capsule', Delegate.GetOrCreate(self, self.OnBtnChildCapsuleClicked))
    self.textText = self:Text('p_text')
    self.imgIconCapsule = self:Image('p_icon_capsule')
    self.goIconPlus = self:GameObject('p_icon_plus')
end

function CommonResourceBtn:OnClose()

end

---@param param CommonResourceBtnData | CommonResourceBtnSimplifiedData
function CommonResourceBtn:OnFeedData(param)
    if not param then
        return
    end
    self.itemId = param.itemId
    if self.itemId then
        local itemCfg = ConfigRefer.Item:Find(self.itemId)
        local amount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.itemId)
        self.textText.text = amount
        local icon = UIHelper.GetFitItemIcon(self.imgIconCapsule, itemCfg)
        g_Game.SpriteManager:LoadSprite(icon, self.imgIconCapsule)
    else
        self.textText.text = param.content
        g_Game.SpriteManager:LoadSprite(param.iconName, self.imgIconCapsule)
    end
    self.param = param
    self.goIconPlus:SetActive(param.isShowPlus or false)
end

function CommonResourceBtn:OnBtnChildCapsuleClicked(args)
    if self.param and self.param.onClick then
        self.param.onClick()
    end
end

function CommonResourceBtn:SetupContent(content)
    self.textText.text = content
end

return CommonResourceBtn
