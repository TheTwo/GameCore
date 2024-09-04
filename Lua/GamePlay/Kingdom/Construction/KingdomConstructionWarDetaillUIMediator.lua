---scene_construction_popup_war_detail
---
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityType = require('DBEntityType')
local DBEntityPath = require('DBEntityPath')
---@class WarGroupData
---@field Attacker KCWarDetailCellTroopData
---@field Defender KCWarDetailCellTroopData

---@class TroopCacheData
---@field hp number
---@field dirty boolean
---@field update boolean

---@class KingdomConstructionWarDetaillUIMediator : BaseUIMediator
---@field warGroup table<number, WarGroupData>
---@field troopCache table<number,TroopCacheData>
---@field hasDead boolean
---@field hasAdded boolean
---@field deadAnimTimer number
local KingdomConstructionWarDetaillUIMediator = class('KingdomConstructionWarDetaillUIMediator', BaseUIMediator)

KingdomConstructionWarDetaillUIMediator.DeadAnimDuration = 0.5

function KingdomConstructionWarDetaillUIMediator:ctor()
    self.deadAnimTimer = -1
    self.hasDead = false
    self.hasAdded = false
end

function KingdomConstructionWarDetaillUIMediator:OnCreate()
    self:Text("p_text_title","village_btn_Battle_situation")
    self.textTitleL = self:Text('p_text_title_l', 'world_build_jingong')
    self.textTitleR = self:Text('p_text_title_r', 'world_build_fangshou')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.tableviewproTableWar = self:TableViewPro('p_table_war')    
end


function KingdomConstructionWarDetaillUIMediator:OnShow(param)
    --GetData
    ---@type wds.DefenceTower|wds.EnergyTower|wds.TransferTower|wds.Village|wds.ResourceField|wds.CastleBrief|wds.CommonMapBuilding|wds.Pass|{Army:wds.Army}
    local buildEntity = param.buildEntity
    self.entityId = buildEntity.ID
    self.entityType = buildEntity.TypeHash

    --Init group data
    self.deadAnimTimer = -1
    self.hasDead = false
    self.hasAdded = false
    self:RefreshAllData(buildEntity)    
    ---@see DBEntityPath.Village
    self.entityPath = param.entityPath
    g_Game.DatabaseManager:AddChanged(self.entityPath.Army.Situation.Infos.MsgPath,Delegate.GetOrCreate(self,self.InfosChanged))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self,self.WaitForRefreshList))
end

function KingdomConstructionWarDetaillUIMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(self.entityPath.Army.Situation.Infos.MsgPath,Delegate.GetOrCreate(self,self.InfosChanged))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self,self.WaitForRefreshList))
end

function KingdomConstructionWarDetaillUIMediator:OnBtnCloseClicked(args)
    self:CloseSelf()
end

function KingdomConstructionWarDetaillUIMediator:WaitForRefreshList(delta)
    if self.hasDead then
        if self.deadAnimTimer > 0 then
            self.deadAnimTimer = self.deadAnimTimer - delta
        else
            self.deadAnimTimer = -1
            self.hasDead = false
            self.hasAdded = false
            self:RefreshAllData()
        end
    elseif self.hasAdded then
        self.hasAdded = false
        self:RefreshAllData()
    end
end

---@param data wds.DefenceTower|wds.EnergyTower|wds.TransferTower|wds.Village|wds.ResourceField|wds.CastleBrief|wds.CommonMapBuilding
function KingdomConstructionWarDetaillUIMediator:InfosChanged(data,changed)    
    if changed and data.ID == self.entityId then
        self:UpdateAllData(data.Army)   
    end    
end

---@param armyData wds.Army
function KingdomConstructionWarDetaillUIMediator:UpdateAllData(armyData)
    local infos = armyData and armyData.Situation.Infos
    local hasDead = false
    local hasAdded = false
    if not infos or infos:Count() < 1 then
        self:OnBtnCloseClicked()
        return
    end
      
    for i = 1, infos:Count() do
        local info = infos[i]
        if info.Attackers and info.Attackers:Count() > 0 then
            for j = 1, info.Attackers:Count() do
                local att = info.Attackers[j]
                if att then
                    local attId = att.Id
                    if self.troopCache[attId] == nil then
                        hasAdded = true                                                        
                        self.troopCache[attId] = {hp = att.Hp,dirty = true,update = true}
                    else
                        if self.troopCache[attId].hp ~= att.Hp then
                            self.troopCache[attId].hp = att.Hp
                            self.troopCache[attId].dirty = true
                        end
                        self.troopCache[attId].update = true
                    end
                end
            end
        end
        if info.Defender then
            local defId = info.Defender.Id
            if self.troopCache[defId] == nil then
                hasAdded = true
                self.troopCache[defId] = {hp = info.Defender.Hp,dirty = true,update = true}
            end
            if self.troopCache[defId].hp ~= info.Defender.Hp then
                self.troopCache[defId].hp = info.Defender.Hp
                self.troopCache[defId].dirty = true
            end            
            self.troopCache[defId].update = true
        end
    end
   
    for key, value in pairs(self.troopCache) do        
     
        if not value.update and value.hp > 0 then
            hasDead = true
            value.hp = 0     
            value.dirty = true  
        elseif (value.update or self.deadAnimTimer < 0) and value.hp <= 0 then
            hasDead = true             
        end        
    end    
    
    for key, value in pairs(self.warGroup) do
        local needUpdate = false
        if value.Attacker and self.troopCache[value.Attacker.id] and self.troopCache[value.Attacker.id].dirty then
            value.Attacker.count = self.troopCache[value.Attacker.id].hp
            needUpdate = true
        end
        if value.Defender and self.troopCache[value.Defender.id] and self.troopCache[value.Defender.id].dirty then
            value.Defender.count = self.troopCache[value.Defender.id].hp
            needUpdate = true
        end
        if needUpdate then
            self.tableviewproTableWar:UpdateChild(value)
        end
    end

    if hasAdded then
        self.hasAdded = true
    end

    if hasDead then
        self.hasDead = true
        if self.deadAnimTimer < 0 then
            self.deadAnimTimer = self.DeadAnimDuration
        else
            self.deadAnimTimer = self.deadAnimTimer + self.DeadAnimDuration * 0.2
        end
    end
    for key, value in pairs(self.troopCache) do
        value.dirty = false
        value.update = false
    end
end

---@param armyData wds.Army
function KingdomConstructionWarDetaillUIMediator:CreateDataFromDummy(armyData)
    self.tableviewproTableWar:Clear()
    if not armyData then return end
    local index = 0
    for key, value in pairs(armyData.DummyTroopIDs) do
        if index > 0 then
            self.tableviewproTableWar:AppendData({},1)
        end
        ---@type WarGroupData
        local groupData = {}
        groupData.Attacker = nil
        groupData.Defender = self:CreateCellData(value)
        self.tableviewproTableWar:AppendData(groupData,0)
        index = index + 1
    end
end

---@param armyData wds.Army
function KingdomConstructionWarDetaillUIMediator:CreateDataFromInfos(armyData)
    
    self.warGroup = {}
    self.troopCache = {}
    local infos = armyData and armyData.Situation.Infos
    if infos and infos:Count() > 0 then        
        -- for i = 1, infos:Count() do
        for key, info in pairs(infos) do                    
            if (not info.Attackers 
                or (info.Attackers and info.Attackers:Count() < 1) )
            and (not info.Defender)
            then
                goto contiune
            end
            ---@type WarGroupData
            local groupData = {}
            ---@type WarGroupData
            if info.Attackers and info.Attackers:Count() > 0 then                           
                groupData.Attacker = self:CreateCellData(info.Attackers[1])
                self.troopCache[info.Attackers[1].Id] = {hp = info.Attackers[1].Hp,dirty = false,update = false}
            end
            if info.Defender and info.Defender.Id > 0  then              
                groupData.Defender = self:CreateCellData(info.Defender)
                self.troopCache[info.Defender.Id] = {hp = info.Defender.Hp,dirty = false,update = false}
            end            
            self.warGroup[key] = groupData
            ::contiune::
        end    
    end    
    self.tableviewproTableWar:Clear()
    local index = 0
    for key, value in pairs(self.warGroup) do        
        -- body
        if value.Defender and index > 0 then
            self.tableviewproTableWar:AppendData({},1)
        end
        self.tableviewproTableWar:AppendData(value,0)
        index = index + 1
    end
end

---@param data wds.DefenceTower|wds.EnergyTower|wds.TransferTower|wds.Village|wds.ResourceField|wds.CastleBrief|wds.CommonMapBuilding|wds.Pass
function KingdomConstructionWarDetaillUIMediator:RefreshAllData(data)
    if not data and self.entityId and self.entityType then
        data = g_Game.DatabaseManager:GetEntity(self.entityId,self.entityType)
    end
    if not data then
        return
    end

    if data.Army.DummyTroopInitFinish then
        self:CreateDataFromInfos(data.Army)
    else
        self:CreateDataFromDummy(data.Army)
    end

end


---@param info wds.ArmyMemberInfo
---@return KCWarDetailCellTroopData
function KingdomConstructionWarDetaillUIMediator:CreateCellData(info)
    if not info then return nil end
    ---@type KCWarDetailCellTroopData
    local cellData = {}
    cellData.id = info.Id
    cellData.count = info.Hp
    cellData.maxCount = info.HpMax
    cellData.heroId = info.HeroTId[1]
    cellData.heroLvl = info.HeroLevel[1]
    cellData.starLvl = info.StarLevel[1]
    cellData.allianceAbbr = info.AllianceAbbr
    cellData.playerName = info.PlayerName
    cellData.playerId = info.PlayerId    
    cellData.portrait = info.Portrait
    cellData.portraitInfo = info.PortraitInfo
    if info.DummyTroop then
        local heroConfig = ConfigRefer.Heroes:Find(info.HeroTId[1])
        cellData.iconName = ModuleRefer.MapBuildingTroopModule:GetHeroSpriteName(heroConfig)
    end
    return cellData
end

return KingdomConstructionWarDetaillUIMediator
