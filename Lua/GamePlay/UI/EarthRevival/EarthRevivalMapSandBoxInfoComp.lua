local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EarthRevivalDefine = require('EarthRevivalDefine')

---@class EarthRevivalMapSandBoxInfoComp : BaseUIComponent
local EarthRevivalMapSandBoxInfoComp = class('EarthRevivalMapSandBoxInfoComp', BaseUIComponent)

function EarthRevivalMapSandBoxInfoComp:OnCreate()
    self.textNameMap = self:Text("p_text_name_map")
    self.textDetail = self:Text("p_text_detail")

    self.textMonsterTitle = self:Text("p_text_monster", "WorldStage_shapangw")
    self.tableviewproMonsters = self:TableViewPro("p_table_monsters")

    self.textBuildingTitle = self:Text("p_text_building", "WorldStage_shapandz")
    self.tableviewproBuildings = self:TableViewPro("p_table_building")

    self.textWorldEventTitle = self:Text("p_text_event", "WorldStage_shapansj")
    self.tableviewproWorldEvents = self:TableViewPro("p_table_event")

    self.textEcologyTitle = self:Text("p_text_ecology", "WorldStage_shapanst")
    self.tableviewproEcologys = self:TableViewPro("p_table_ecology")
    self.goBaseEcology = self:GameObject("base_ecology")
end

function EarthRevivalMapSandBoxInfoComp:OnFeedData(ringIndex)
    ---@type WorldStageSandboxConfigCell
    local sandBoxData = ModuleRefer.EarthRevivalModule:GetSandBoxConfigByRingIndex(ringIndex)
    if not sandBoxData then
        return
    end

    self.textNameMap.text = I18N.Get(sandBoxData:Name())
    self.textDetail.text = I18N.Get(sandBoxData:Describe())

    self.tableviewproMonsters:Clear()
    local monsterLength = sandBoxData:MonstersLength()
    for i = 1, monsterLength do
        local param = {}
        param.type = EarthRevivalDefine.EarthRevivalMap_ItemType.Monster
        param.configID = sandBoxData:Monsters(i)
        self.tableviewproMonsters:AppendData(param)
    end

    self.tableviewproBuildings:Clear()
    local buildingLength = sandBoxData:BuildingsLength()
    for i = 1, buildingLength do
        local param = {}
        param.type = EarthRevivalDefine.EarthRevivalMap_ItemType.Building
        param.configID = sandBoxData:Buildings(i)
        self.tableviewproBuildings:AppendData(param)
    end

    self.tableviewproWorldEvents:Clear()
    local worldEventLength = sandBoxData:ExpeditionsLength()
    for i = 1, worldEventLength do
        local param = {}
        param.type = EarthRevivalDefine.EarthRevivalMap_ItemType.WorldEvent
        param.configID = sandBoxData:Expeditions(i)
        self.tableviewproWorldEvents:AppendData(param)
    end

    self.textEcologyTitle:SetVisible(false)
    self.tableviewproEcologys.gameObject:SetActive(false)
    self.goBaseEcology:SetActive(false)
end

return EarthRevivalMapSandBoxInfoComp