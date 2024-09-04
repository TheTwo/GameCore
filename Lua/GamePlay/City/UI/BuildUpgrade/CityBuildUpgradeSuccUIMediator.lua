---Scene Name : scene_build_upgrade
local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require("I18N")

---@class CityBuildUpgradeSuccUIMediator:BaseUIMediator
local CityBuildUpgradeSuccUIMediator = class('CityBuildUpgradeSuccUIMediator', BaseUIMediator)

---@class CityBuildUpgradeUIParameter
---@field cellTile CityCellTile

function CityBuildUpgradeSuccUIMediator:OnCreate()
    self.imageBuilding = self:Image("p_img_building")
    self.tableviewproTable = self:TableViewPro('p_table')
    self.textTitle = self:Text('p_text_title')
end

---@param param CityBuildUpgradeUIParameter
function CityBuildUpgradeSuccUIMediator:OnOpened(configId)
    self.lvCell = ConfigRefer.BuildingLevel:Find(configId)
    self.typCell = ConfigRefer.BuildingTypes:Find(self.lvCell:Type())
    self.textTitle.text =  I18N.GetWithParams("city_upgrade_main_title", self.lvCell:Level())
    local buildingTypeConfig = ConfigRefer.BuildingTypes:Find(self.lvCell:Type())
    g_Game.SpriteManager:LoadSprite(buildingTypeConfig:Image(), self.imageBuilding)
    self.tableviewproTable:Clear()
    self.lastLvCell = ConfigRefer.BuildingLevel:Find(self.typCell:LevelCfgIdList(self.lvCell:Level() - 1))
    if self:HasSizeChange() then
        local sizeItem = {}
        sizeItem.icon = buildingTypeConfig:Image()
        sizeItem.name = I18N.Get("city_upgrade_attr_size_expand")
        self.tableviewproTable:AppendData(sizeItem)
    end

    local attrCfg = self.lvCell:Attr()
    local attrList = self:GetAttrValue(attrCfg)
    for _, attr in ipairs(attrList) do
        local attrItem = {}
        attrItem.icon = attr[1]
        attrItem.name = I18N.GetWithParams("city_upgrade_attr_up", attr[2])
        attrItem.textNum = attr[3]
        self.tableviewproTable:AppendData(attrItem)
    end
end


function CityBuildUpgradeSuccUIMediator:GetAttrValue(attrGroupId)
    local attrGroupCfg = ConfigRefer.AttrGroup:Find(attrGroupId)
    local attrList = {}
    for i = 1 , attrGroupCfg:AttrListLength() do
        local attrCfg = attrGroupCfg:AttrList(i)
        local typeId = attrCfg:TypeId()
        local attrTypeCfg = ConfigRefer.AttrElement:Find(typeId)
        if attrTypeCfg:Show() ~= 0 then
            local name = I18N.Get(attrTypeCfg:Name())
            attrList[#attrList + 1] = {attrTypeCfg:Icon(), name, ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrTypeCfg, attrCfg:Value())}
        end
    end
    return attrList
end

function CityBuildUpgradeSuccUIMediator:HasSizeChange()
    return self.lvCell:SizeX() ~= self.lastLvCell:SizeX() or self.lvCell:SizeY() ~= self.lastLvCell:SizeY()
end


return CityBuildUpgradeSuccUIMediator