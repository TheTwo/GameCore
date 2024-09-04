local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIStrengthenTipsMediator = class('UIStrengthenTipsMediator',BaseUIMediator)

local TYPE_NAMES = {
    I18N.Get("player_power_hero_name"),
    I18N.Get("player_power_pet_name"),
    I18N.Get("player_power_city_name"),
    I18N.Get("player_power_others_name"),
}

local TROOP_NAME = {
    I18N.Get("power_squad1_name"),
    I18N.Get("power_squad2_name"),
    I18N.Get("power_squad3_name"),
}

function UIStrengthenTipsMediator:OnCreate()
    self.tableviewproTable = self:TableViewPro('p_table')
end

function UIStrengthenTipsMediator:OnOpened()
    local strongHoldLv = ModuleRefer.PlayerModule:StrongholdLevel()
    local playerData =  ModuleRefer.PlayerModule:GetPlayer()
    local curPower = playerData.PlayerWrapper2.PlayerPower.TotalPower
    self.tableviewproTable:Clear()
    self.tableviewproTable:AppendData({title = I18N.Get("power_entire_breakdown_name")}, 1)
    self.tableviewproTable:AppendData({title = I18N.Get("player_power_name"), num = curPower, color = "#F84981"}, 2)
    local subTypePowers = playerData.PlayerWrapper2.PlayerPower.SubTypePowers
    local typeMap = self:BuildTypeMap()
    for _, config in ConfigRefer.PowerTypeMap:ipairs() do
        local powerType = config:PowerType()
        local showTypes = typeMap[powerType]
        local typeTotalPower = 0
        local recommendCfg = ConfigRefer.RecommendPowerTable:Find(strongHoldLv)
        for i = 1, recommendCfg:SubTypePowersLength() do
            local subTypePower = recommendCfg:SubTypePowers(i)
            local subType = subTypePower:SubType()
            if table.ContainsValue(showTypes, subType) then
                local power = subTypePowers[subType] or 0
                typeTotalPower = typeTotalPower + power
            end
        end
        self.tableviewproTable:AppendData({title = TYPE_NAMES[config:PowerType()], num = typeTotalPower}, 2)
    end
    self.tableviewproTable:AppendData({title = I18N.Get("power_squad_breakdown_name")}, 1)
    self.tableviewproTable:AppendData({title = I18N.Get("player_power_squad_name"), num = ModuleRefer.TroopModule:GetAllTroopsTotalPower(), color = "#F84981"}, 2)
    for i = 1, 3 do
		local power = ModuleRefer.TroopModule:GetTroopPower(i)
        if power > 0 then
            self.tableviewproTable:AppendData({title = TROOP_NAME[i], num = power}, 2)
        end
	end

end

function UIStrengthenTipsMediator:OnClose(param)

end

function UIStrengthenTipsMediator:BuildTypeMap()
    local typeMap = {}
    for _, config in ConfigRefer.PowerTypeMap:ipairs() do
        local powerType = config:PowerType()
        if not typeMap[powerType] then
            typeMap[powerType] = {}
        end
        for i = 1, config:PowerSubTypesLength() do
            typeMap[powerType][#typeMap[powerType] + 1] = config:PowerSubTypes(i)
        end
    end
    return typeMap
end

return UIStrengthenTipsMediator
