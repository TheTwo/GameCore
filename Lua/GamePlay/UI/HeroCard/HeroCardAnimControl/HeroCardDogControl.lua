local ModuleRefer = require("ModuleRefer")

---@field otherDog1 CS.UnityEngine.GameObject
---@field otherDog2 CS.UnityEngine.GameObject
---@field otherDog3 CS.UnityEngine.GameObject
---@field otherDog4 CS.UnityEngine.GameObject
local HeroCardDogControl = class('HeroCardDogControl')

function HeroCardDogControl:Awake()
    self.otherDogs = {}
    table.insert(self.otherDogs, self.otherDog1)
    table.insert(self.otherDogs, self.otherDog2)
    table.insert(self.otherDogs, self.otherDog3)
    table.insert(self.otherDogs, self.otherDog4)
end

function HeroCardDogControl:Start()

end

function HeroCardDogControl:OnEnable()
    if ModuleRefer.HeroCardModule:IsTenGacha() then
        for _, dog in ipairs(self.otherDogs) do
            dog:SetActive(true)
        end
        return
    end
    local dogIndex = ModuleRefer.HeroCardModule:GetOtherDogIndex()
    for index, dog in ipairs(self.otherDogs) do
        dog:SetActive(index == dogIndex)
    end
end

function HeroCardDogControl:OnDisable()

end

function HeroCardDogControl:OnDestroy()

end

return HeroCardDogControl