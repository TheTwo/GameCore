local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetSkillType = require("PetSkillType")


---@class UIPetMainPopupMediator:BaseUIMediator
local UIPetMainPopupMediator = class('UIPetMainPopupMediator', BaseUIMediator)

---@class UIPetMainPopupMediatorParameter
---@field petId number
---@field attrList list{name, num}[]

function UIPetMainPopupMediator:ctor()
    self._rewardList = {}
end

function UIPetMainPopupMediator:OnCreate()
    ---@type UIPetAttrTableViewCell
    self.p_table = self:TableViewPro('p_table')
end

---@param param UIPetMainPopupMediatorParameter
function UIPetMainPopupMediator:OnShow(param)
    local petId = param.petId
    self.p_table:Clear()
    if petId and petId > 0 then
        self:ShowPetAttr(petId)
    elseif param.attrList then
        for i, v in ipairs(param.attrList) do
            self.p_table:AppendData({index = i, text = I18N.Get(v.name), value = tostring(v.num)})
        end
    end
end

function UIPetMainPopupMediator:ShowPetAttr(petId)
    for i = 1, ConfigRefer.PetConsts:PetAttrUIShowListLength() do
        local attrId = ConfigRefer.PetConsts:PetAttrUIShowList(i)
        local dispConf = ConfigRefer.AttrDisplay:Find(attrId)
        local value, text = ModuleRefer.PetModule:GetPetAttrDisplayValue(petId, attrId)
        if (ModuleRefer.AttrModule:IsAttrValueShow(dispConf, value)) then
            local elementId = ModuleRefer.HeroModule:GetAttrDiaplayRelativeAttrType(attrId)
            local attr = ConfigRefer.AttrElement:Find(elementId)
            local data = {index = i, text = I18N.Get(text), value = tostring(ModuleRefer.AttrModule:GetAttrValueShowTextByType(attr, value))}
            self.p_table:AppendData(data)
        end
    end
end

function UIPetMainPopupMediator:OnHide(param)
end

return UIPetMainPopupMediator
