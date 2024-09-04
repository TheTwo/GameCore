local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')

---@class LandformImageCellData
---@field iconId number
---@field qualityIcon string
---@field nameKey string
---@field descKey string
---@field isMonster boolean
---@field isPetItem boolean
---@field petItemID number @ItemConfigCell Id
---@field isVillagePet boolean
---@field itemGroupId number @ItemGroupConfigCell Id

---@class LandformImageCell:BaseTableViewProCell
---@field new fun():LandformImageCell
---@field super BaseTableViewProCell
local LandformImageCell = class('LandformImageCell', BaseTableViewProCell)

function LandformImageCell:OnCreate()
    self.btnItem = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self.imgItem = self:Image("p_img")
    self.imgBase = self:Image("p_base")

    self.vxTrigger = self:AnimTrigger('vx_trigger_pet_item')
end

---@param data LandformImageCellData
function LandformImageCell:OnFeedData(data)
    self.data = data

    if type(self.data.iconId) == "number" then
        self:LoadSprite(self.data.iconId, self.imgItem)
    else
        g_Game.SpriteManager:LoadSprite(self.data.iconId, self.imgItem)
    end

    if self.data.qualityIcon then
        g_Game.SpriteManager:LoadSprite(self.data.qualityIcon, self.imgBase)
    end

    if self.vxTrigger then
        if self.data.isVillagePet then
            self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        else
            self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    end
end

function LandformImageCell:OnHide()
    if self.toastRuntimeId and self.toastRuntimeId > 0 then
        ModuleRefer.ToastModule:CancelTextToast(self.toastRuntimeId)
        self.toastRuntimeId = nil
    end
end

function LandformImageCell:OnClick()
    if self.data.isMonster then
        ---@type MonsterInfoTipsMediatorParameter
        local tipsParam = {}
        tipsParam.iconId = self.data.iconId
        tipsParam.nameKey = self.data.nameKey
        tipsParam.descKey = self.data.descKey
        tipsParam.itemGroupId = self.data.itemGroupId
        tipsParam.clickTransform = self.btnItem.transform
        g_Game.UIManager:Open(UIMediatorNames.MonsterInfoTipsMediator, tipsParam)
    elseif self.data.isPetItem then
        local param = {
            itemId = self.data.petItemID,
            itemType = require("CommonItemDetailsDefine").ITEM_TYPE.ITEM,
            clickTransform = self.btnItem.transform,
        }
        self.tipsRuntimeId = g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    else
        ---@type TextToastMediatorParameter
        local toastParameter = {}
        toastParameter.clickTransform =  self.btnItem.transform
        toastParameter.title = I18N.Get(self.data.nameKey)
        if self.data.isVillagePet then
            -- 乡镇宠物追加
            toastParameter.content = string.format('%s\n%s', I18N.Get(self.data.descKey), I18N.Get('bw_tips_occupy_pet_center')) 
        else
            toastParameter.content = I18N.Get(self.data.descKey)
        end
        self.toastRuntimeId = ModuleRefer.ToastModule:ShowTextToast(toastParameter)

    end
end

return LandformImageCell