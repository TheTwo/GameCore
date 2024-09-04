---@prefabName:ui3d_toast_city_buff
---@class CityPetDecreaseUpgradeTime
---@field new fun():CityPetDecreaseUpgradeTime
---@field p_rotation CS.DragonReborn.LuaBehaviour
---@field p_position CS.DragonReborn.LuaBehaviour
---@field content CS.UnityEngine.GameObject
---@field p_pet_1 CS.UnityEngine.GameObject
---@field p_icon_pet_1 CS.U2DSpriteMesh
---@field p_pet_2 CS.UnityEngine.GameObject
---@field p_text_number CS.U2DTextMesh
---@field p_icon_pet_2 CS.U2DSpriteMesh
---@field p_text_detail CS.U2DTextMesh
---@field vx_trigger CS.FpAnimation.FpAnimationCommonTrigger
local CityPetDecreaseUpgradeTime = class("CityPetDecreaseUpgradeTime")

---@param info CityPetCountdownUpgradeTimeInfo
function CityPetDecreaseUpgradeTime:ShowInfo(info)
    if info.count == 1 then
        self:ShowSingleIcon(info)
    else
        self:ShowDoubleIcon(info)
    end
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

---@private
---@param info CityPetCountdownUpgradeTimeInfo
function CityPetDecreaseUpgradeTime:ShowSingleIcon(info)
    self.p_pet_1:SetActive(false)
    self.p_pet_2:SetActive(true)
    g_Game.SpriteManager:LoadSprite(info.icon1, self.p_icon_pet_2)
    self.p_icon_pet_2:SetVisible(true)
    self.p_text_number:SetVisible(false)
    self.p_text_detail.text = info:GetCountdownTimeStr()
end

---@private
---@param info CityPetCountdownUpgradeTimeInfo
function CityPetDecreaseUpgradeTime:ShowDoubleIcon(info)
    self.p_pet_1:SetActive(true)
    self.p_pet_2:SetActive(true)
    g_Game.SpriteManager:LoadSprite(info.icon1, self.p_icon_pet_1)
    if info:NeedShowIcon2() then
        self.p_icon_pet_2:SetVisible(true)
        self.p_text_number:SetVisible(false)
        g_Game.SpriteManager:LoadSprite(info.icon2, self.p_icon_pet_2)
    else
        self.p_icon_pet_2:SetVisible(false)
        self.p_text_number:SetVisible(true)
        self.p_text_number.text = ("+%d"):format(info.count - 1)
    end
    self.p_text_detail.text = info:GetCountdownTimeStr()
end

return CityPetDecreaseUpgradeTime