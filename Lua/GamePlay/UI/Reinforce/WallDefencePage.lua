local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local UITroopHelper = require("UITroopHelper")
local ModuleRefer = require("ModuleRefer")
local BaseUIComponent = require("BaseUIComponent")

---@class WallDefencePage : BaseUIComponent
local WallDefencePage = class("WallDefencePage", BaseUIComponent)

function WallDefencePage:OnCreate()
    self.table = self:TableViewPro("p_table_mine")
end

function WallDefencePage:OnOpened()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChanged))
    self:UpdatePresets()
end

function WallDefencePage:OnClose()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnPresetChanged))
end

function WallDefencePage:UpdatePresets()
    self.table:Clear(false, false)

    local castle = ModuleRefer.PlayerModule:GetCastle()

    ---@type WallDefencePageCellData[]
    local list = {}

    for index, preset in pairs(castle.TroopPresets.Presets) do
        local heroCount = preset.Heroes:Count()
        if heroCount > 0 then
            local data = WallDefencePage.CreateData(index, preset)
            table.insert(list, data)    
        end
    end

    table.sort(list, function(x, y) return x.power > y.power end)

    for index, data in ipairs(list) do
        data.index = index
        self.table:AppendData(data)
    end
end

---@param preset wds.TroopPreset
---@return WallDefencePageCellData
function WallDefencePage.CreateData(index, preset)
    local heroList, petList = UITroopHelper.GetPresetHerosAndPets(preset)
    local power = UITroopHelper.CalcTroopPower(heroList, petList)
    return {preset = preset, power = power, presetIndex = index - 1, index = 0}
end

---@param data wds.CastleBrief
function WallDefencePage:OnPresetChanged(data)
    if data.ID ~= ModuleRefer.PlayerModule:GetCastle().ID then
        return
    end

    self:UpdatePresets()
end

return WallDefencePage