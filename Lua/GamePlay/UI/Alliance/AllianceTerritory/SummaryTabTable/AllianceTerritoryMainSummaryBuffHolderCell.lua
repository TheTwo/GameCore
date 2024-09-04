local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local NumberFormatter = require("NumberFormatter")
local BaseTableViewProCell = require("BaseTableViewProCell")
local AllianceTerritoryMainSummaryBuffHolderCell = class('AllianceTerritoryMainSummaryBuffHolderCell', BaseTableViewProCell)
local AllianceModuleDefine = require('AllianceModuleDefine')
local AllianceCurrencyType = require('AllianceCurrencyType')

function AllianceTerritoryMainSummaryBuffHolderCell:OnCreate(param)
    self.p_table_resources_holder = self:TableViewPro("p_table_resources_holder")
end

function AllianceTerritoryMainSummaryBuffHolderCell:OnFeedData(data)
    self:BuildResBuffCells()
end

function AllianceTerritoryMainSummaryBuffHolderCell:BuildResBuffCells()
    self.p_table_resources_holder:Clear()

    local CurrencyConfig = ConfigRefer.CurrencyInfo
    local AllianceCurrencyConfig = ConfigRefer.AllianceCurrency
    local ResourceTypeConfig = ConfigRefer.CityResourceType

    local resConfig = CurrencyConfig:Find(1)
    local itemConfig = ConfigRefer.Item:Find(resConfig:RelItem())
    local allianceCurrency = AllianceCurrencyConfig:Find(1)
    self:SetCell(itemConfig, nil, allianceCurrency)
    
    itemConfig = ConfigRefer.Item:Find(ResourceTypeConfig:Find(1):Items(1))
    allianceCurrency = AllianceCurrencyConfig:Find(2)
    self:SetCell(itemConfig, 1701, allianceCurrency)

    itemConfig = ConfigRefer.Item:Find(ResourceTypeConfig:Find(2):Items(1))
    allianceCurrency = AllianceCurrencyConfig:Find(3)
    self:SetCell(itemConfig, 1702, allianceCurrency)

    -- itemConfig = ConfigRefer.Item:Find(ResourceTypeConfig:Find(3):Items(1))
    -- allianceCurrency = AllianceCurrencyConfig:Find(4)
    -- self:SetCell(itemConfig, 1703, allianceCurrency)

    -- itemConfig = ConfigRefer.Item:Find(AllianceModuleDefine.AllianceDeclaration)
    -- allianceCurrency = AllianceCurrencyConfig:Find(5)
    -- self:SetCell(itemConfig, 2013, allianceCurrency)
end

function AllianceTerritoryMainSummaryBuffHolderCell:SetCell(itemConfig, attrType, allianceCurrency)
    ---@type AllianceTerritoryMainSummaryBuffDetailCellData
    local resBuffCellData = {}
    resBuffCellData.pName = I18N.Get(itemConfig:NameKey())
    resBuffCellData.pIcon = itemConfig:Icon()

    local outPutSpeed = 0
    if attrType then
        local attrTypeConfig = ConfigRefer.AttrType:Find(attrType)
        if attrTypeConfig and attrTypeConfig:CityAttr() ~= 0 then
            local cityAttr = ModuleRefer.VillageModule._globalAutoGrowSpeedTimeCityAttrType
            if cityAttr then
                local ins = ModuleRefer.CastleAttrModule:SimpleGetValue(cityAttr)
                if ins > 0 then
                    local v = ModuleRefer.CastleAttrModule:SimpleGetValue(attrTypeConfig:CityAttr())
                    outPutSpeed = math.floor(v * (3600 / ins))
                end
            end
        end
    end

    resBuffCellData.pValue = I18N.GetWithParams("alliance_resource_xiaoshi", NumberFormatter.NumberAbbr(outPutSpeed))
    resBuffCellData.aName = I18N.Get(allianceCurrency:Name())
    resBuffCellData.aIcon = allianceCurrency:Icon()

    local speed = ModuleRefer.AllianceModule:GetAllianceCurrencyAddSpeedById(allianceCurrency:Id())
    local ins = ModuleRefer.AllianceModule:GetAllianceCurrencyAutoAddTimeInterval(allianceCurrency:CurrencyType())
    if not ins or ins <= 0 then
        resBuffCellData.aValue = I18N.GetWithParams("alliance_resource_xiaoshi", "0")
    else
        if allianceCurrency:CurrencyType() == AllianceCurrencyType.WarCard or allianceCurrency:CurrencyType() == AllianceCurrencyType.BuildCard then
            resBuffCellData.aValue = I18N.GetWithParams("alliance_xuanzhanchanchu", NumberFormatter.NumberAbbr(math.floor(speed * (1 / ins) + 0.5)))
        else
            resBuffCellData.aValue = I18N.GetWithParams("alliance_resource_xiaoshi", NumberFormatter.NumberAbbr(math.floor(speed * (3600 / ins))))
        end
    end
    self.p_table_resources_holder:AppendData(resBuffCellData)
end

return AllianceTerritoryMainSummaryBuffHolderCell
