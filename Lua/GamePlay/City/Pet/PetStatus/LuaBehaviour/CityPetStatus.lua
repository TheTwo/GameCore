---@prefabName: ui3d_bubble_pet_status
---@class CityPetStatus
---@field new fun():CityPetStatus
---@field p_rotation CS.UnityEngine.Transform
---@field p_position CS.UnityEngine.Transform
---@field p_emoji CS.UnityEngine.Transform
---@field p_icon_emoji CS.U2DSpriteMesh
---@field p_eating CS.UnityEngine.Transform
---@field p_icon_food CS.U2DSpriteMesh
---@field p_progress_eating CS.U2DSpriteMesh
---@field p_progress CS.UnityEngine.Transform
---@field p_progress_1 CS.U2DSpriteMesh
---@field p_popup_food CS.UnityEngine.Transform
---@field p_icon_food_need CS.U2DSpriteMesh
---@field p_text_name CS.U2DTextMesh
local CityPetStatus = class("CityPetStatus")
local Utils = require("Utils")

---@param city City
---@param emoji string
---@param eating {icon:string, progress:number}
---@param hp number
---@param popupFood boolean
---@param textName string
function CityPetStatus:Initialize(emoji, eating, hp, popupFood, textName)
    self:HideAll()
    self:InitializeFacingCamera()
    self:ShowEmoji(emoji)
    self:ShowEating(eating and eating.icon, eating and eating.progress)
    self:ShowHp(hp)
    self:ShowWannaFood(popupFood)
    self:ShowName(textName)
end

function CityPetStatus:Dispose()
    self.city = nil
    self.petId = nil
    self.inBingo = nil
end

function CityPetStatus:InitializeFacingCamera()
    local script = self.p_rotation.gameObject:GetComponent(typeof(CS.U2DFacingCamera))
    if Utils.IsNotNull(script) then
        script.enabled = true
    end
end

function CityPetStatus:HideAllExceptName()
    self.p_emoji:SetVisible(false)
    self.p_eating:SetVisible(false)
    self.p_progress:SetVisible(false)
    self.p_popup_food:SetVisible(false)

    self.showEmoji = false
    self.showEating = false
    self.showBlood = false
    self.showNeedFood = false
end

function CityPetStatus:HideAll()
    self:HideAllExceptName()
    self.p_text_name:SetVisible(false)
    self.showName = false
end

function CityPetStatus:ShowEmoji(emoji)
    local showEmoji = not string.IsNullOrEmpty(emoji)
    if showEmoji ~= self.showEmoji then
        self.showEmoji = showEmoji
        self.p_emoji:SetVisible(showEmoji)
    end

    if showEmoji then
        g_Game.SpriteManager:LoadSprite(emoji, self.p_icon_emoji)
    end
end

---@param icon string
---@param progress number
function CityPetStatus:ShowEating(icon, progress)
    local showEating = not string.IsNullOrEmpty(icon) or progress ~= nil
    if showEating ~= self.showEating then
        self.showEating = showEating
        self.p_eating:SetVisible(showEating)
    end

    if showEating then
        if not string.IsNullOrEmpty(icon) then
            g_Game.SpriteManager:LoadSprite(icon, self.p_icon_food)
        end

        if progress then
            self.p_progress_eating.fillAmount = progress
        end
    end
end

function CityPetStatus:ShowHp(hp)
    local showHp = hp ~= nil
    if showHp ~= self.showBlood then
        self.showBlood = showHp
        self.p_progress:SetVisible(showHp)
    end

    if showHp then
        self.p_progress_1.fillAmount = hp
    end
end

function CityPetStatus:ShowWannaFood(popupFood)
    local showPopupFood = popupFood ~= nil
    if showPopupFood ~= self.showNeedFood then
        self.showNeedFood = showPopupFood
        self.p_popup_food:SetVisible(showPopupFood)
    end
end

function CityPetStatus:ShowName(textName)
    local showName = not string.IsNullOrEmpty(textName)
    if showName ~= self.showName then
        self.showName = showName
        self.p_text_name:SetVisible(showName)
    end

    if showName then
        self.p_text_name.text = textName
    end
end

---@param position CS.UnityEngine.Vector3
function CityPetStatus:SyncEmojiPos(position)
    self.p_emoji.position = position
end

return CityPetStatus