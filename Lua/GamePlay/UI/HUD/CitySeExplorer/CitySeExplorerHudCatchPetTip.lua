local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class CitySeExplorerHudCatchPetTipData
---@field petTid number
---@field starSkillLevel number
---@field delayFadeOut number

---@class CitySeExplorerHudCatchPetTip:BaseUIComponent
---@field new fun():CitySeExplorerHudCatchPetTip
---@field super BaseUIComponent
local CitySeExplorerHudCatchPetTip = class('CitySeExplorerHudCatchPetTip', BaseUIComponent)

function CitySeExplorerHudCatchPetTip:ctor()
    CitySeExplorerHudCatchPetTip.super.ctor(self)
    self._delayFadeOut = nil
    self._waitFadeOut = nil
end

function CitySeExplorerHudCatchPetTip:OnCreate(param)
    self._p_base_pet_quality_1 = self:Image("p_base_pet_quality_1")
    self._p_img_pet = self:Image("p_img_pet")
    self._p_text_pet_title = self:Text("p_text_pet_title", "pet_se_result_win")
    self._p_text_pet_name = self:Text("p_text_pet_name")
    ---@type PetStarLevelComponent
    self._p_group_star = self:LuaObject("p_group_star")
    self._aniTrigger = self:AnimTrigger("")
end

---@param data CitySeExplorerHudCatchPetTipData
function CitySeExplorerHudCatchPetTip:OnFeedData(data)
    self._delayFadeOut = data.delayFadeOut
    local petConfig = ConfigRefer.Pet:Find(data.petTid)
    self._p_text_pet_name.text = I18N.Get(petConfig:Name())
    self:LoadSprite(petConfig:ShowPortrait(), self._p_img_pet)
    ---@type PetStarLevelComponentParam
    local startInfo = {}
    startInfo.skillLevels = {}
    startInfo.skillLevels[1] = {level = data.starSkillLevel, quality = petConfig:Quality()}
    self._p_group_star:FeedData(startInfo)
    self._p_base_pet_quality_1.color = ModuleRefer.PetModule:GetPetQualityColor(petConfig:Quality())
    self._waitFadeOut = nil
    self._aniTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._aniTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function CitySeExplorerHudCatchPetTip:OnShow(param)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CitySeExplorerHudCatchPetTip:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CitySeExplorerHudCatchPetTip:Tick(deltaTime)
    if self._waitFadeOut then
        self._waitFadeOut = self._waitFadeOut - deltaTime
        if self._waitFadeOut < 0 then
            self._waitFadeOut = nil
            self:SetVisible(false)
        end
    end
    if not self._delayFadeOut then return end
    self._delayFadeOut = self._delayFadeOut - deltaTime
    if self._delayFadeOut > 0 then return end
    self._delayFadeOut = nil
    self._aniTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._waitFadeOut = self._aniTrigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
end

return CitySeExplorerHudCatchPetTip