local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ManualUIConst = require('ManualUIConst')
local EventConst = require('EventConst')
---@class RadarFourPetComp : BaseTableViewProCell
---@field data HeroConfigCache
local RadarFourPetComp = class('RadarFourPetComp', BaseTableViewProCell)

function RadarFourPetComp:ctor()

end

function RadarFourPetComp:OnCreate()
    ---@type RadarPetComp
    self.p_pet_1 = self:LuaObject('p_pet_1')
    self.p_pet_2 = self:LuaObject('p_pet_2')
    self.p_pet_3 = self:LuaObject('p_pet_3')
    self.p_pet_4 = self:LuaObject('p_pet_4')

    self.pets = {self.p_pet_1, self.p_pet_2, self.p_pet_3, self.p_pet_4}
    g_Game.EventManager:AddListener(EventConst.RADAR_TRACE_PET_CHANGE, Delegate.GetOrCreate(self, self.RefreshCheck))

end

function RadarFourPetComp:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TRACE_PET_CHANGE, Delegate.GetOrCreate(self, self.RefreshCheck))

end

function RadarFourPetComp:OnFeedData(param)
    self.param = param
    for i = 1, 4 do
        if param[i] then
            self.index = param[i].index
            self.pets[i]:FeedData(param[i])
            self.pets[i]:SetVisible(true)
        else
            self.pets[i]:SetVisible(false)
        end
    end

    local cfgId = ModuleRefer.RadarModule:GetRadarTraceSelectPet()
    self:RefreshSelect(cfgId)
    self:RefreshCheck(self.index)
end

function RadarFourPetComp:RefreshSelect(cfgId)
    for k, v in pairs(self.pets) do
        if v.cfgId == cfgId then
            v:Select()
        else
            v:UnSelect()
        end
    end
end

function RadarFourPetComp:RefreshCheck(index)
    if index ~= self.index then
        return
    end
    local pets = ModuleRefer.RadarModule:GetTempRadarTracingPets()
    for k, v in pairs(self.pets) do
        local isCheck = false
        if pets then
            for k2, v2 in pairs(pets) do
                if v.cfgId == v2 then
                    isCheck = true
                    break
                end
            end
        end
        if self.param[k] then
            self.param[k].isCheck = isCheck
            self.param[k].showMask = isCheck
        end
        v:SetCheck(isCheck)
    end

end

return RadarFourPetComp
