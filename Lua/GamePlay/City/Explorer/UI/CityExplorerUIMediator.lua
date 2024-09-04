local Delegate = require("Delegate")
local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local CastleExplorerAddParameter = require("CastleExplorerAddParameter")
local CastleExplorerDelParameter = require("CastleExplorerDelParameter")

---@class CityExplorerUIMediator:BaseUIMediator
---@field new fun():CityExplorerUIMediator
---@field super BaseUIMediator
local CityExplorerUIMediator = class('CityExplorerUIMediator', BaseUIMediator)

function CityExplorerUIMediator:OnCreate(param)
    self._lb_title = self:Text("p_txt_free_2", I18N.Temp().text_assign)
    self._lb_hint = self:Text("p_text_hint", I18N.Temp().text_assign_already)

    self._btn_exit = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnClickClose))
    self._btn_operation = self:Button("p_comp_btn_a_l", Delegate.GetOrCreate(self, self.OnClickOperation))
    self._lb_operation = self:Text("p_text", I18N.Temp().text_assign)
    self._tbl_heroTable = self:TableViewPro("p_table_hero")
    self._tbl_heroTable:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedChanged))

    self._trans_buildingScreenPos = self:RectTransform("p_building_pos")
    self._lb_left_heroName = self:Text("p_text_name_build")
    self._img_left_heroIcon = self:Image("p_img_hero")

    self._heroData = {}
end

---@param param CityCellTile
function CityExplorerUIMediator:OnShow(param)
    local cell = param:GetCell()
    if cell then
        self._buildingId = cell.tileId
        self:ForcusOnBuilding(param:GetCity():GetCamera(), param.pos)
    end
    self._uid = ModuleRefer.CityModule.myCity.uid
    self:Refresh()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.InCityInfo.Explorers.MsgPath, Delegate.GetOrCreate(self, self.OnExplorerDataChanged))
end

function CityExplorerUIMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.InCityInfo.Explorers.MsgPath, Delegate.GetOrCreate(self, self.OnExplorerDataChanged))
end

function CityExplorerUIMediator:OnClose(param)
    self._tbl_heroTable:SetSelectedDataChanged(nil)
    BaseUIMediator.OnClose(self, param)
end

function CityExplorerUIMediator:OnClickClose()
    self:CloseSelf()
end

function CityExplorerUIMediator:OnClickOperation()
    if self._selected == self._currentBuildingHero then
        return
    else
        local onBuilding = self._hero2Building[self._selected.HId]
        if not onBuilding then
            if not self._currentBuildingHero then
                local request = CastleExplorerAddParameter.new()
                request.args.HeroId = tonumber(self._selected.HId)
                request.args.BuildingId = tonumber(self._buildingId)
                request:Send()
            else
                local removeOld = CastleExplorerDelParameter.new()
                removeOld.args.HeroId = tonumber(self._currentBuildingHero.HId)
                removeOld:Send()
                local addNew = CastleExplorerAddParameter.new()
                addNew.args.HeroId = tonumber(self._selected.HId)
                addNew.args.BuildingId = tonumber(self._buildingId)
                addNew:Send()
            end
        end
    end
end

---@param entity wds.CastleBrief
function CityExplorerUIMediator:OnExplorerDataChanged(entity, changedTable)
    if self._uid ~= entity.ID then
        return
    end
    self:Refresh()
end

---@param camera BasicCamera
function CityExplorerUIMediator:ForcusOnBuilding(camera, buildingPos)
    camera:LookAt(buildingPos, 0.5)
end

function CityExplorerUIMediator:Refresh()
    self._hero2Building = {}
    self._tbl_heroTable:Clear()
    self._selected = nil
    self._currentBuildingHero = nil
    local explorers = ModuleRefer.PlayerModule:GetPlayer().Castle.InCityInfo.Explorers
    local allHeroes = ModuleRefer.PlayerModule:GetPlayer().Hero.HeroInfos
    local heroConfig = ConfigRefer.Heroes
    for heroId, buildingId in pairs(explorers) do
        self._hero2Building[heroId] = buildingId
    end
    for heroId, heroValue in pairs(allHeroes) do
        local config = heroConfig:Find(heroValue.CfgId)
        local cellData = {BId = self._hero2Building[heroId], HId = heroId, HCfg = config, IsCurrent = false}
        if cellData.BId == self._buildingId then
            self._currentBuildingHero = cellData
            cellData.IsCurrent = ture
        end
        table.insert(self._heroData, cellData)
    end
    -- table.insert(self._heroData, {BId = self._buildingId, HId = 101, HCfg = heroConfig:Find(101), IsCurrent = true})
    -- table.insert(self._heroData, {BId = nil, HId = 102, HCfg = heroConfig:Find(102), IsCurrent = false})
    -- table.insert(self._heroData, {BId = 10293, HId = 103, HCfg = heroConfig:Find(103), IsCurrent = false})
    local currentBuildingId = self._buildingId
    table.sort(self._heroData, function(a,b)
        local aBuilding = self._hero2Building[a.HId]
        local bBuilding = self._hero2Building[b.HId]
        if currentBuildingId and aBuilding and currentBuildingId == aBuilding then
            return true
        end
        if not aBuilding and bBuilding then
            return true
        end
        return false
    end)
    for _, v in ipairs(self._heroData) do
        self._tbl_heroTable:AppendData(v)
    end
    if  self._currentBuildingHero and self._currentBuildingHero.HCfg then
        self._lb_left_heroName.text = I18N.Get(self._currentBuildingHero.HCfg:Name())
        self._img_left_heroIcon.enabled = true
        g_Game.SpriteManager:LoadSprite(self._img_left_heroIcon, self._currentBuildingHero.HCfg:HeadIcon())
    else
        self._lb_left_heroName.text = string.Empty
        self._img_left_heroIcon.enabled = false
    end
    if #self._heroData > 0 then
        self._selected = self._heroData[1]
        self._tbl_heroTable:SetToggleSelect(self._selected)
    end
    self:OnSelectedChanged(self._selected)
end

function CityExplorerUIMediator:OnSelectedChanged(obj1, obj2)
    self._selected = obj1
    if self._selected == self._currentBuildingHero then
        self._lb_hint.enabled = true
        self._btn_operation.gameObject:SetActive(false)
    else
        local onBuilding = self._hero2Building[self._selected.HId]
        if not onBuilding then
            self._btn_operation.gameObject:SetActive(true)
            self._lb_hint.enabled = false
        else
            self._lb_hint.enabled = true
            self._btn_operation.gameObject:SetActive(false)
        end
    end
end

return CityExplorerUIMediator