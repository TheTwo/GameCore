---@class CityPetStatusHandle
---@field new fun():CityPetStatusHandle
local CityPetStatusHandle = class("CityPetStatusHandle")
local ManualResourceConst = require("ManualResourceConst")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local TimerUtility = require("TimerUtility")
local ConfigRefer = require("ConfigRefer")

---@param petUnit CityUnitPet
function CityPetStatusHandle:ctor(petUnit)
    self.petUnit = petUnit
    self.manager = petUnit.petData.manager
    self.petId = petUnit.petData.id
end

function CityPetStatusHandle:LoadModel()
    self.modelHandle = self.manager.city.createHelper:Create(ManualResourceConst.ui3d_bubble_pet_status, self.manager.city.CityWorkerRoot, Delegate.GetOrCreate(self, self.OnAssetLoaded))
end

function CityPetStatusHandle:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    ---@type CS.UnityEngine.GameObject
    self.go = go
    ---@type CityPetStatus
    self.petStatus = go:GetLuaBehaviour("CityPetStatus").Instance
    self.petStatus:Initialize()
    self:UpdateName()
    self:Update()
end

function CityPetStatusHandle:Dispose()
    if self.petStatus then
        self.petStatus:Dispose()
        self.petStatus = nil
    end

    if self.modelHandle then
        self.modelHandle:Delete()
        self.modelHandle = nil
    end
end

function CityPetStatusHandle:Update()
    if not self.petStatus then return end
    if self.inBingo then return end
    
    self.petStatus:HideAllExceptName()
    local petDatum = self.petUnit.petData
    if petDatum and petDatum:IsHungry() then
        self.petStatus:ShowHp(petDatum:GetHpPercent())
    else
        self.petStatus:ShowHp()
    end

    if self.manager:IsPetHungry(self.petId) then
        self.petStatus:ShowEmoji("sp_icon_citizen_emoji_01")
        self.petStatus:ShowWannaFood()
        g_Game.SpriteManager:LoadSprite("sp_icon_citizen_emoji_01", self.p_icon_emoji)
    end
end

function CityPetStatusHandle:ShowBingo(delay)
    if not self.petStatus then return end
    if self.inBingo then return end

    self.petStatus:HideAllExceptName()
    self.petStatus:ShowEmoji("sp_item_icon_exclamation_mark")
    self.inBingo = true
    self.timer = TimerUtility.DelayExecute(function()
        self.inBingo = false
        self:Update()
    end, delay or 2)
end

function CityPetStatusHandle:ShowEatting(progress)
    if not self.petStatus then return end

    local itemId = self.petUnit.petData.eatingFoodItemId
    local itemCfg = ConfigRefer.Item:Find(itemId)
    local icon = "sp_icon_missing"
    if itemCfg then
        icon = itemCfg:Icon()
    end
    self.petStatus:ShowEating(icon, progress)
end

function CityPetStatusHandle:HideEatting()
    if not self.petStatus then return end

    self.petStatus:ShowEating()
end

function CityPetStatusHandle:UpdateName()
    if not self.petStatus then return end
    local pet = ModuleRefer.PetModule:GetPetByID(self.petId)
    if pet then
        self.petStatus:ShowName(pet.PetInfoWrapper.Name)
    else
        self.petStatus:ShowName()
    end
end

function CityPetStatusHandle:Tick(dt)
    if Utils.IsNull(self.go) then return end
    
    self:SyncPosFromMoveAgent(self.petUnit._moveAgent)
    if Utils.IsNotNull(self.petUnit._attachPointHolder) then
        self:SyncPosFromAttachPointHandler(self.petUnit._attachPointHolder)
    end
end

---@param holder CS.FXAttachPointHolder
function CityPetStatusHandle:SyncPosFromAttachPointHandler(holder)
    if not self.petStatus then return end

    local anchor = holder:GetAttachPoint("hanging_point")
    if Utils.IsNull(anchor) then return end

    self.petStatus:SyncEmojiPos(anchor.position)
end

---@param moveAgent UnitMoveAgent
function CityPetStatusHandle:SyncPosFromMoveAgent(moveAgent)
    if self.go then
        self.go.transform.position = moveAgent._currentPosition
    end
end

return CityPetStatusHandle