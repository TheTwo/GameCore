local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local ModuleRefer = require('ModuleRefer')
local GotoUtils = require('GotoUtils')
local DBEntityType = require('DBEntityType')

---@class GMPageSlg:GMPage
local GMPageSlg = class('GMPageSlg', GMPage)
local UIMediatorNames = require("UIMediatorNames")

function GMPageSlg:ctor()
    
    self.DebugMode = g_Game.PlayerPrefsEx:GetInt('SLGDebugMode',0) > 0
    self.KMDataCfgIds = '100001,100002,100003,100004,100005,100006,100007,100008,100009'
    self.MonsterIds = '100001,100002,100003,100004,100005,100006,100007,100008,100009'

    
    self.TroopCount = '1'
    self.PosX = ""
    self.PosY = ""  
    self.PosXOffset = "0"
    self.PosYOffset = "0" 
    self.scroPos = CS.UnityEngine.Vector2.zero
    
    self.ShowTroopList = false
    self.ShowTroopTest = false
    self.ShowTroopFallback = false
    
    
    -- self.TroopIndex = '1'
    -- self.HeroId0 = "101"
    -- self.HeroId1 = "0"
    -- self.HeroId2 = "0"
    -- -- self.SoldierId = "1"
    -- -- self.SoldierCount = "500000"
    -- self.petId0 = '1'
    -- self.petId1 = '2'
    -- self.petid2 = '3'
end

function GMPageSlg:OnShow()
    self.panel._serverCmdProvider:RefreshCmdList()
    self:InitFallbackConfig()
end

function GMPageSlg:GetKMonsterIds(idsStr)
    local ids = {}
    local idStrParts = string.split(idsStr,',')
    for key, value in pairs(idStrParts) do
        table.insert(ids,tonumber(value))
    end
    return ids
end

function GMPageSlg:OnGUI()
	-- if (GUILayout.Button("打开编队界面")) then
	-- 	g_Game.UIManager:Open(UIMediatorNames.UITroopMediator)
	-- 	self.panel:PanelShow(false)
	-- end

    -- if g_Game.SceneManager and g_Game.SceneManager.current and 
    --     (g_Game.SceneManager.current:GetName() ~= "KingdomScene" 
    --     and g_Game.SceneManager.current:GetName() ~= "SlgScene" 
    --     )
    -- then
    --     if GUILayout.Button('Goto Kingdom') then
    --         GotoUtils.GotoSceneKingdom(GotoUtils.SceneId.Kingdom, 0)
    --     end
    --     return
    -- end

    self.DebugMode = GUILayout.Toggle(self.DebugMode,'DebugMode')
    if self.DebugMode ~= ModuleRefer.SlgModule.DebugMode then
        ModuleRefer.SlgModule:SetupDebugMode(self.DebugMode)
    end

    self.scroPos = GUILayout.BeginScrollView(self.scroPos)   
    --Troop Ctrl
    GUILayout.Label('KMonsterData.ID')
    self.KMDataCfgIds = GUILayout.TextField(self.KMDataCfgIds, GUILayout.shrinkWidth)
    GUILayout.BeginHorizontal()
    if GUILayout.Button('Create Troop', GUILayout.shrinkWidth) then        
        local kMonsterIds = self:GetKMonsterIds(self.KMDataCfgIds)
        self.panel:SendGMCmd('troopbyconfig',kMonsterIds[1] or 3)
    end        
    GUILayout.EndHorizontal()  
    
    --Monster
    GUILayout.Label("MonsterId", GUILayout.shrinkWidth)
    self.MonsterIds = GUILayout.TextField(self.MonsterIds, GUILayout.shrinkWidth)   
    GUILayout.BeginHorizontal()
    GUILayout.Label("PosX", GUILayout.shrinkWidth)
    self.PosX = GUILayout.TextField(self.PosX)
    GUILayout.Label("PosY", GUILayout.shrinkWidth)
    self.PosY = GUILayout.TextField(self.PosY)
    if GUILayout.Button('Create Mob', GUILayout.shrinkWidth) then        
        local kMonsterIds = self:GetKMonsterIds(self.MonsterIds)
        if not string.IsNullOrEmpty(self.PosX) and not string.IsNullOrEmpty(self.PosY) then
            self.panel:SendGMCmd('mob',kMonsterIds[1] or 4,tonumber(self.PosX),tonumber(self.PosY))
        else
            self.panel:SendGMCmd('mob',kMonsterIds[1] or 4)
        end
    end       
    GUILayout.EndHorizontal()  
    
    local troopListButtonStr = self.ShowTroopList and 'Hide TroopList' or 'Show TroopList'
    if GUILayout.Button(troopListButtonStr) then
        self.ShowTroopList = not self.ShowTroopList
    end
    if self.ShowTroopList then
        self:OnGUI_TroopList()
    end

    local troopTestButtonStr = self.ShowTroopTest and 'Hide TroopTest' or 'Show TroopTest'
    if GUILayout.Button(troopTestButtonStr) then
        self.ShowTroopTest = not self.ShowTroopTest
    end
    if self.ShowTroopTest then
        self:OnGUI_TroopTest()
    end

    local troopFallbackButtonStr = self.ShowTroopFallback and 'Hide Fallback Config' or 'Show Fallback Config'
    if GUILayout.Button(troopFallbackButtonStr) then
        self.ShowTroopFallback = not self.ShowTroopFallback
    end
    if self.ShowTroopFallback then
        self:OnGUI_FallbackConfig()
    end
    GUILayout.EndScrollView()

    if GUILayout.Button('Open RVO Scene') then
        self.panel:PanelShow(false)
    end
end

function GMPageSlg:GetDefaultLocation()
    local KingdomMapUtils = require("KingdomMapUtils")

    local camera = KingdomMapUtils.GetBasicCamera()
    if camera == nil then
        return 0, 0
    end

    local staticMapData = KingdomMapUtils.GetStaticMapData()
    if staticMapData == nil then
        return 0, 0
    end

    local lookAtPos = camera:GetLookAtPosition()
    local unitsPerTileX = staticMapData.UnitsPerTileX or 0
    local unitsPerTileZ = staticMapData.UnitsPerTileZ or 0
    local x = math.floor(lookAtPos.x / unitsPerTileX)
    local y = math.floor(lookAtPos.z / unitsPerTileZ)

    return x, y
end

-- function GMPageSlg:OnGUI_PresetInfo()
--     --Troop Preset   
--     GUILayout.Label('--Troop Preset----------------------------------------------------------')
--     GUILayout.BeginHorizontal()
--     if GUILayout.Button('Get PresetData') then
--         local index = tonumber(self.TroopIndex)        
--         ModuleRefer.TroopEditModule:UpdatePresetsCache()
--         local presetData = ModuleRefer.TroopEditModule:GetPreset(index)
--         if presetData then
--             self.HeroId0 = tostring( presetData.Heroes[1] )
--             self.HeroId1 = tostring( presetData.Heroes[2] )
--             self.HeroId2 = tostring( presetData.Heroes[3] )            
--             -- self.SoldierId = tostring(presetData.soliderId)
--             -- self.SoldierCount = tostring(presetData.soliderCount)
--             self.petId0 = tostring(presetData.pets[1])
--             self.petId1 = tostring(presetData.pets[2])
--             self.petId2 = tostring(presetData.pets[3])
--         end
--     end
--     GUILayout.Label("TroopIndex", GUILayout.shrinkWidth)
--     self.TroopIndex = GUILayout.TextField(self.TroopIndex)
--     GUILayout.Label("HeroMain", GUILayout.shrinkWidth)
--     self.HeroId0 = GUILayout.TextField(self.HeroId0)
--     GUILayout.Label("Hero2", GUILayout.shrinkWidth)
--     self.HeroId1 = GUILayout.TextField(self.HeroId1)
--     GUILayout.Label("Hero3", GUILayout.shrinkWidth)    
--     self.HeroId2 = GUILayout.TextField(self.HeroId2)
--     GUILayout.EndHorizontal() 
--     GUILayout.BeginHorizontal()
--     GUILayout.Label("Soldier", GUILayout.shrinkWidth)
--     self.SoldierId = GUILayout.TextField(self.SoldierId)
--     -- GUILayout.Label("Count", GUILayout.shrinkWidth)
--     -- self.SoldierCount = GUILayout.TextField(self.SoldierCount)
--     GUILayout.EndHorizontal() 
--     GUILayout.BeginHorizontal()
--     GUILayout.Label("Pet1", GUILayout.shrinkWidth)
--     self.petId0 = GUILayout.TextField(self.petId0)
--     GUILayout.Label("Pet2", GUILayout.shrinkWidth)
--     self.petId1 = GUILayout.TextField(self.petId1)
--     GUILayout.Label("Pet3", GUILayout.shrinkWidth)
--     self.petId2 = GUILayout.TextField(self.petId2)
--     GUILayout.EndHorizontal() 

--     GUILayout.BeginHorizontal()

--     if GUILayout.Button('Setup Preset Heros') then                
--         local heroId0 =  string.IsNullOrEmpty(self.HeroId0) and 0 or tonumber(self.HeroId0)
--         local heroId1 =  string.IsNullOrEmpty(self.HeroId1) and 0 or tonumber(self.HeroId1)
--         local heroId2 =  string.IsNullOrEmpty(self.HeroId2) and 0 or tonumber(self.HeroId2)
--         local index = tonumber(self.TroopIndex)
--         ModuleRefer.TroopEditModule:SetupTroopPresetHeros(index,{heroId0,heroId1,heroId2})        
--     end

--     -- if GUILayout.Button('Setup Preset Soldier') then                      
--     --     local index = tonumber(self.TroopIndex)
--     --     ModuleRefer.TroopEditModule:SetupTroopPresetSoldiers(index,tonumber(self.SoldierId),tonumber(self.SoldierCount),nil,function()
--     --         g_Logger:g_Logger("Setup Succeed")
--     --     end)        
--     -- end
--     if GUILayout.Button('Setup Preset Pets') then          
--         local pets = {}
--         local petId0 =  string.IsNullOrEmpty(self.petId0) and 0 or tonumber(self.petId0)
--         if  petId0 and petId0 > 0 then
--             table.insert(pets,petId0)
--         end
--         local petId1 =  string.IsNullOrEmpty(self.petId1) and 0 or tonumber(self.petId1)
--         if petId1 and petId1 > 0 then
--             table.insert(pets,petId1)
--         end
--         local petId2 =  string.IsNullOrEmpty(self.petId2) and 0 or tonumber(self.petId2)            
--         if  petId2 and petId2 > 0 then
--             table.insert(pets,petId2)
--         end
--         local index = tonumber(self.TroopIndex)
--         ModuleRefer.TroopEditModule:SetupTroopPresetPets(index,pets,nil,function()
--             g_Logger:g_Logger("Setup Succeed")
--         end)        
--     end

--     GUILayout.EndHorizontal()
-- end

function GMPageSlg:OnGUI_TroopList()
     ---@type wds.Troop[]
     local allTroops = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Troop)
     GUILayout.Label("--Troops " ..  tostring(#allTroops) .. '----------------------------------------------------')
     for key, value in pairs(allTroops) do
         if ModuleRefer.SlgModule:IsMyTroop(value) then
             local heroIds = ''
             for key, value in pairs(value.Battle.Group.Heros) do
                 heroIds = heroIds .. tostring(value.HeroID) .. ';'
             end
             GUILayout.TextField(string.format('id:%d | HerosID:%s ',
             value.ID,
             heroIds             
            ) )
         end
     end
     local allMob= g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapMob)
     GUILayout.Label("--Mobs" .. tostring(#allMob) .. "----------------------------------------------------------")    
     for key, value in pairs(allMob) do
         
         local heroIds = ''
         for key, value in pairs(value.Battle.Group.Heros) do
             heroIds = heroIds .. tostring(value.HeroID) .. ';'
         end
         GUILayout.TextField(string.format('id:%d | HerosID:%s ',
         value.ID,
         heroIds) )
         
     end
     GUILayout.Label("--MapBuilding(Type:0建筑 1家具 3墙)------------------------------")
     ---@type wds.MapBuilding[]
     local allBuilding= g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapBuilding)
     for key, value in pairs(allBuilding) do
        
        
         
         GUILayout.TextField(string.format('id:%d(type %d) Pos:(%0.1f,%0.1f) Durability:%d/%d ' ,
         value.ID,            
         value.Base.CityBrief.cityType,
         value.MapBasics.Position.X,value.MapBasics.Position.Y,
         value.Battle.Durability,value.Battle.MaxDurability
     ) )
         
     end
end

---@param count number
---@param cfgId number
---@param x number
---@param y number
---@param xOffset number
---@param yOffset number
function GMPageSlg:CreateTestTroop(count,cfgIdsStr,x,y,xOffset,yOffset)
    local row = math.floor(math.sqrt(count))
    local col = math.ceil(count / row)   
    local cfgIds = self:GetKMonsterIds(cfgIdsStr)
    local idIndex = 1
    local maxIndex = #cfgIds
    for i = 1, row do
        for j = 1, col do
            self.panel._serverCmdProvider:SendCmd({cmd = 'troopbyconfig'},{tostring(cfgIds[idIndex]),'','',tostring(x + xOffset * (i-1)),tostring(y + yOffset * (j-1))})
            idIndex = idIndex + 1
            if idIndex > maxIndex then
                idIndex = 1
            end
        end
    end
end

function GMPageSlg:CreateMobs(count,cfgIdsStr,x,y,xOffset,yOffset)
    local row = math.floor(math.sqrt(count))
    local col = math.ceil(count / row)
    local cfgIds = self:GetKMonsterIds(cfgIdsStr)
    local idIndex = 1
    local maxIndex = #cfgIds
    for i = 1, row do
        for j = 1, col do
            self.panel._serverCmdProvider:SendCmd({cmd = 'mob'},{tostring(cfgIds[idIndex]),tostring(x + xOffset * (i-1)),tostring(y + yOffset * (j-1))})
            idIndex = idIndex + 1
            if idIndex > maxIndex then
                idIndex = 1
            end
        end
    end   
end

---@param pos1 wds.Vector3F
---@param pos2 wds.Vector3F
function CalcDistanceSque(pos1,pos2)
    local x = pos1.X - pos2.X
    local y = pos1.Y - pos2.Y
    return x * x + y * y
end
local TimerUtility = require('TimerUtility')
function GMPageSlg:SendAllTroopToMob()
    ---@type wds.Troop[]
    local allTroops = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Troop)
    ---@type wds.MapMob[]
    local allMob= g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapMob)
    local slgModule = ModuleRefer.SlgModule    
    local troopCount = table.nums(allTroops)

    local loopTime = ( troopCount/ 5) + 1
    
    TimerUtility.IntervalRepeat(function()
        if not allMob or not allTroops then
            return
        end
        local troopIds = {}
        local count = 0
        for id, troop in pairs(allTroops) do
            if not allMob then
                break
            end
            if slgModule:IsMyTroop(troop) then           
                ---@type wds.MapMob
                local targetMob = nil
                local targetMobKey = nil
              
                for key, mob in pairs(allMob) do
                    -- body
                    if mob and mob.MobInfo.Level < 2 then
                       targetMob = mob
                       targetMobKey = key
                    end
                end
                if not targetMob then
                    allMob = nil
                    break
                end
                allMob[targetMobKey] = nil
                if targetMob then
                    slgModule:MoveTroopToEntityViaData(troop,-1,targetMob.ID)
                end
                table.insert(troopIds,id)
                count = count + 1
            end
            if count >= 5 then
                break
            end
        end

        for key, value in pairs(troopIds) do
            allTroops[value] = nil
        end

    end, 0.5, loopTime, true, nil)

   
end

function GMPageSlg:SendAllTroopToHome(immediately)
    ---@type wds.Troop[]
    local allTroops = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Troop)   
    local slgModule = ModuleRefer.SlgModule    
    for _, troop in pairs(allTroops) do
        if slgModule:IsMyTroop(troop) and not troop.MapStates.BackToCity then
            if immediately then
                slgModule:ReturnToHomeImmediately(troop.ID)
            else
                slgModule:ReturnToHome(troop.ID)
            end
        end
    end
end


function GMPageSlg:OnGUI_TroopTest()
    local count = 1
    local configId = -1
    local posX = -1
    local posY = -1
    local posXOffset = 1
    local posYOffset = 1
    GUILayout.BeginHorizontal()
    local allTroops = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Troop)
    GUILayout.Label("Troops " ..  tostring(#allTroops))
    local allMob= g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapMob)
    GUILayout.Label("Mobs" .. tostring(#allMob))    
    GUILayout.EndHorizontal()  

    GUILayout.Label('KMonsterData.ID')
    self.KMDataCfgIds = GUILayout.TextField(self.KMDataCfgIds, GUILayout.shrinkWidth)        
    GUILayout.BeginHorizontal()
    GUILayout.Label('TroopCount',GUILayout.shrinkWidth)
    self.TroopCount = GUILayout.TextField(self.TroopCount)
    count = string.IsNullOrEmpty(self.TroopCount) and 0 or tonumber(self.TroopCount)
    GUILayout.EndHorizontal()  
    GUILayout.BeginHorizontal()
    GUILayout.Label("PosX", GUILayout.shrinkWidth)
    self.PosX = GUILayout.TextField(self.PosX)
    GUILayout.Label("PosXOffset", GUILayout.shrinkWidth)
    self.PosXOffset = GUILayout.TextField(self.PosXOffset)
    GUILayout.EndHorizontal()  
    GUILayout.BeginHorizontal()
    GUILayout.Label("PosY", GUILayout.shrinkWidth)
    self.PosY = GUILayout.TextField(self.PosY)
    GUILayout.Label("PosYOffset", GUILayout.shrinkWidth)
    self.PosYOffset = GUILayout.TextField(self.PosYOffset)
    GUILayout.EndHorizontal()  

    if GUILayout.Button("Use Castle Pos") then
        local x, y = self:GetDefaultLocation()
        self.PosX = tostring(x)
        self.PosY = tostring(y)
    end
    
    posX = string.IsNullOrEmpty(self.PosX) and posX or tonumber(self.PosX)
    posY = string.IsNullOrEmpty(self.PosY) and posY or tonumber(self.PosY)
    posXOffset = string.IsNullOrEmpty(self.PosXOffset) and posXOffset or tonumber(self.PosXOffset)
    posYOffset = string.IsNullOrEmpty(self.PosYOffset) and posYOffset or tonumber(self.PosYOffset)


    if not string.IsNullOrEmpty(self.KMDataCfgIds)
        and posX and posY 
        and posXOffset and posYOffset 
        and count > 0 and posX > 0 and posY > 0 
    then
        GUILayout.BeginHorizontal()
        if GUILayout.Button('Create Troops') then        
            self:CreateTestTroop(count,self.KMDataCfgIds,posX,posY,posXOffset,posYOffset)        
        end
        if GUILayout.Button('Create Mobs') then        
            self:CreateMobs(count,self.KMDataCfgIds,posX,posY,posXOffset,posYOffset)        
        end
        GUILayout.EndHorizontal()          
    end

    if GUILayout.Button('Send All Troops to Mob') then    
        self:SendAllTroopToMob()
    end

    GUILayout.BeginHorizontal()
    if GUILayout.Button('Remove All Show Mob') then 
        local allMob= g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapMob)        
        for key, value in pairs(allMob) do
           self.panel:SendGMCmd('removemob',value.ID)                       
        end
    end
    if GUILayout.Button('Send All Troops to Home') then    
        self:SendAllTroopToHome(false)
    end
    GUILayout.EndHorizontal()  


end

function GMPageSlg:InitFallbackConfig()
    self.HideMoveVfxCount = tostring( ModuleRefer.SlgModule.FallbackConfig.HideMoveVfxCount )
    self.HideBuffVfxCount = tostring( ModuleRefer.SlgModule.FallbackConfig.HideBuffVfxCount )
    self.HideOtherVfxCount = tostring(ModuleRefer.SlgModule.FallbackConfig.HideOtherVfxCount)
end

function GMPageSlg:OnGUI_FallbackConfig()
    GUILayout.BeginHorizontal()
    local allTroops = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Troop)
    local allMob= g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapMob)
    GUILayout.Label("Troops + Mobs: " ..  tostring(#allTroops + #allMob))    
    GUILayout.EndHorizontal() 
    
    GUILayout.BeginHorizontal()
    GUILayout.Label("隐藏移动特效的部队数量:", GUILayout.shrinkWidth)
    local hideMoveVfxCount = GUILayout.TextField(self.HideMoveVfxCount)
    if hideMoveVfxCount ~= self.HideMoveVfxCount then
        local hideMoveVfxCountNum = tonumber(hideMoveVfxCount)
        if hideMoveVfxCount then
            self.HideMoveVfxCount = hideMoveVfxCount
            ModuleRefer.SlgModule.FallbackConfig.HideMoveVfxCount = hideMoveVfxCountNum
        end
    end
    GUILayout.EndHorizontal() 

    GUILayout.BeginHorizontal()
    GUILayout.Label("隐藏Buff特效的部队数量:", GUILayout.shrinkWidth)
    local hideBuffVfxCount = GUILayout.TextField(self.HideBuffVfxCount)
    if hideBuffVfxCount ~= self.HideBuffVfxCount then
        local hideBuffVfxCountNum = tonumber(hideBuffVfxCount)
        if hideBuffVfxCount then
            self.HideBuffVfxCount = hideBuffVfxCount
            ModuleRefer.SlgModule.FallbackConfig.HideBuffVfxCount = hideBuffVfxCountNum
        end
    end
    GUILayout.EndHorizontal() 

    GUILayout.BeginHorizontal()
    GUILayout.Label("隐藏技能特效的部队数量:", GUILayout.shrinkWidth)
    local hideOtherVfxCount = GUILayout.TextField(self.HideOtherVfxCount)
    if hideOtherVfxCount ~= self.HideOtherVfxCount then
        local hideOtherVfxCountNum = tonumber(hideOtherVfxCount)
        if hideOtherVfxCount then
            self.HideOtherVfxCount = hideOtherVfxCount
            ModuleRefer.SlgModule.FallbackConfig.HideOtherVfxCount = hideOtherVfxCountNum
        end
    end
    GUILayout.EndHorizontal() 
end

return GMPageSlg
