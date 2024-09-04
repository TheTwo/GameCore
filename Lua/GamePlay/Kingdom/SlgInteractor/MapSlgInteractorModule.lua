local BaseModule = require("BaseModule")
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local KingdomMapUtils = require("KingdomMapUtils")
local OnChangeHelper = require("OnChangeHelper")

---@class MapSlgInteractorModule : BaseModule
local MapSlgInteractorModule = class('MapSlgInteractorModule', BaseModule)


function MapSlgInteractorModule:ctor()
    --TODO
end


function MapSlgInteractorModule:OnRegister()
    --TODO
end


function MapSlgInteractorModule:OnRemove()
    --TODO
end

function MapSlgInteractorModule:Setup()
    self.isShow = true
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerSeEnter.MsgPath, Delegate.GetOrCreate(self, self.OnUpdateSlgInteractor))

    self:UpdateAllSlgInteractor(true)
end

function MapSlgInteractorModule:ShutDown()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerSeEnter.MsgPath, Delegate.GetOrCreate(self, self.OnUpdateSlgInteractor))
end

function MapSlgInteractorModule:RestoreAllUnits()
end

---@param seEnterData wds.SeEnter
---@param mineConfig MineConfigCell
---@param buildingPosX number
---@param buildingPosY number
function MapSlgInteractorModule:AddSlgInteractorUnit(seEnterData, mineConfig, buildingPosX, buildingPosY)
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(mineConfig:MapLayout())
    local affectX = buildingPosX
    local affectY = buildingPosY
    local affectSizeX = layout.SizeX
    local affectSizeY = layout.SizeY
    ModuleRefer.MapUnitModule:AddUnit(seEnterData.TypeHash, seEnterData.ID, buildingPosX, buildingPosY, layout.SizeX, layout.SizeY, affectX, affectY, affectSizeX, affectSizeY, true)
end

---@param seEnterData wds.SeEnter
function MapSlgInteractorModule:RemoveSlgInteractorUnit(seEnterData)
    ModuleRefer.MapUnitModule:RemoveUnit(seEnterData.TypeHash, seEnterData.ID, true)
end

---@param seEnterData wds.SeEnter
function MapSlgInteractorModule:UpdateSlgInteractorUnit(seEnterData)
    ModuleRefer.MapUnitModule:UpdateUnit(seEnterData.TypeHash, seEnterData.ID, true)
end

---@param seEnterData wds.SeEnter
function MapSlgInteractorModule:MoveSlgInteractorUnit(seEnterData, mineConfig, buildingPosX, buildingPosY)
    local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(mineConfig:MapLayout())
    local affectX = buildingPosX
    local affectY = buildingPosY
    local affectSizeX = layout.SizeX
    local affectSizeY = layout.SizeY
    ModuleRefer.MapUnitModule:MoveUnit(seEnterData.TypeHash, seEnterData.ID, buildingPosX, buildingPosY, layout.SizeX, layout.SizeY, affectX, affectY, affectSizeX, affectSizeY, true)

end

function MapSlgInteractorModule:CanShowSlgInteractor(lod)
    return KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod)
end

---@param changedData wds.PlayerSeEnter
function MapSlgInteractorModule:OnUpdateSlgInteractor(entity, changedData)
    local lod = KingdomMapUtils.GetLOD()
    if not self:CanShowSlgInteractor(lod) then
        return
    end
    local addMap, removeMap, changeMap = OnChangeHelper.GenerateMapFieldChangeMap(changedData.SeEnters)
    if addMap or removeMap or changeMap then
        if removeMap then
            ---@param seEnterData wds.SeEnter
            for _, seEnterData in pairs(removeMap) do
                self:RemoveSlgInteractorUnit(seEnterData)
            end
        end

        if addMap then
            ---@param seEnterData wds.SeEnter
            for _, seEnterData in pairs(addMap) do
                local buildingPosX, buildingPosY = KingdomMapUtils.ParseBuildingPos(seEnterData.Position)
                local mineConfig = ConfigRefer.Mine:Find(seEnterData.MineCfgId)
                self:AddSlgInteractorUnit(seEnterData, mineConfig, buildingPosX, buildingPosY)
            end
        end

        if changeMap then
            ---@param seEnterDatas wds.SeEnter[]
            for _, seEnterDatas in pairs(changeMap) do
                for _, seEnterData in ipairs(seEnterDatas) do
                    self:UpdateSlgInteractorUnit(seEnterData)
                end
            end
        end
    else
        for id, data in pairs(changedData.SeEnters) do
            if data.Position then
                local seEnterData = self:GetSlgInteractorData(id)
                local buildingPosX, buildingPosY = KingdomMapUtils.ParseBuildingPos(seEnterData.Position)
                local mineConfig = ConfigRefer.Mine:Find(seEnterData.MineCfgId)
                self:MoveSlgInteractorUnit(seEnterData, mineConfig, buildingPosX, buildingPosY)
            end
        end
    end
end

function MapSlgInteractorModule:OnLodChanged(oldLod, newLod)
    local isShow = self:CanShowSlgInteractor(newLod)
    if self.isShow ~= isShow then
        self.isShow = isShow
        if self.isShow then
            self:UpdateAllSlgInteractor()
        else
            self:HideSlgInteractor()
        end
    end

end

function MapSlgInteractorModule:UpdateAllSlgInteractor(refreshUnits)
    local datas = self:GetAllSlgInteractors()
    for _, seEnterData in pairs(datas) do
        local buildingPosX, buildingPosY = KingdomMapUtils.ParseBuildingPos(seEnterData.Position)
        local mineConfig = ConfigRefer.Mine:Find(seEnterData.MineCfgId)
        if refreshUnits then
            self:RemoveSlgInteractorUnit(seEnterData)
            self:AddSlgInteractorUnit(seEnterData, mineConfig, buildingPosX, buildingPosY)
        end
    end
end

function MapSlgInteractorModule:HideSlgInteractor()
    local mapSystem = KingdomMapUtils.GetMapSystem()
    mapSystem:SetTerrainCreepRenderTexture(mapSystem.CameraBox, nil)
end

---@return table<number, wds.SeEnter> | MapField
function MapSlgInteractorModule:GetAllSlgInteractors()
    local playerSlgInteractors = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper3.PlayerSeEnter
    return playerSlgInteractors and playerSlgInteractors.SeEnters or {}
end

function MapSlgInteractorModule:ClearSlgInteractorUnits()
    local datas = self:GetAllSlgInteractors()
    for _, seEnterData in pairs(datas) do
        self:RemoveSlgInteractorUnit(seEnterData)
    end
end

function MapSlgInteractorModule:GetSlgInteractorData(id)
    local datas = self:GetAllSlgInteractors()
    return datas[id]
end

function MapSlgInteractorModule:IsCanCombat(id)
    return id == self:GetCanCombatSlgInteractorID()
end

--获取当前能够挑战的个人SEID
function MapSlgInteractorModule:GetCanCombatSlgInteractorID()
    local curSectionID = ModuleRefer.HuntingModule:GetNextSectionId()
    local datas = self:GetAllSlgInteractors()
    for _, seEnterData in pairs(datas) do
       if seEnterData.HuntingSectionId == curSectionID then
            return seEnterData.ID
       end
    end
    return 0
end

---@return wds.SeEnter
function MapSlgInteractorModule:GetCanCombatSlgInteractorData()
    local curSectionID = ModuleRefer.HuntingModule:GetNextSectionId()
    local datas = self:GetAllSlgInteractors()
    for _, seEnterData in pairs(datas) do
       if seEnterData.HuntingSectionId == curSectionID then
            return seEnterData
       end
    end
    return nil
end

--获取前一关卡的数据
---@return wds.SeEnter
function MapSlgInteractorModule:GetLastSlgInteractorData(id)
    local curData = self:GetSlgInteractorData(id)
    if not curData then
        return nil
    end
    local datas = self:GetAllSlgInteractors()
    for _, seEnterData in pairs(datas) do
        if seEnterData.HuntingSectionId == curData.HuntingSectionId - 1 then
             return seEnterData
        end
     end
    return nil
end

function MapSlgInteractorModule:GetCanCombatSlgInteractoName()
    local seEnterData = self:GetCanCombatSlgInteractorData()
    if seEnterData then
        local huntingConfig = ConfigRefer.HuntingSection:Find(seEnterData.HuntingSectionId)
        if not huntingConfig then
            return ""
        end
        return I18N.Get(huntingConfig:Name())
    end
    return ""
end

--获取前一关卡的名字
function MapSlgInteractorModule:GetLastSlgInteractoName(id)
    local lastSeEnterData = self:GetLastSlgInteractorData(id)
    if lastSeEnterData then
        local huntingConfig = ConfigRefer.HuntingSection:Find(lastSeEnterData.HuntingSectionId)
        if not huntingConfig then
            return ""
        end
        return I18N.Get(huntingConfig:Name())
    end
    return ""
end

return MapSlgInteractorModule