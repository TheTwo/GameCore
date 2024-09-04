---scene: scene_battle_main
--- 添加新战役入口：
--- -1. 如无特殊需求，不需要额外处理，直接添加配置即可
--- 0. Activity.xml -> enum@BattleEntryType 添加新类型
--- 1. 策划配置 BattleEntry.csv
--- 2. BattleEntryBattleCell中添加特殊显示和跳转逻辑
---@see BattleEntryBattleCell
--- 3. BattleEntryModule中添加红点穿透逻辑
---@see BattleEntryModule
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local I18N = require("I18N")
---@class BattleEntryMediator : BaseUIMediator
local BattleEntryMediator = class("BattleEntryMediator", BaseUIMediator)

function BattleEntryMediator:ctor()
    self.curOpenedEntryIds = {}
end

function BattleEntryMediator:OnCreate()
    ---@see CommonBackButtonComponent
    self.luaBtnBack = self:LuaObject("child_common_btn_back")
    self.tableBattles = self:TableViewPro("p_table_battle")
end

function BattleEntryMediator:OnShow()
    ---@type CommonBackButtonData
    local data = {}
    data.title = I18N.Get("battleentry_hud_name")
    self.luaBtnBack:FeedData(data)
    self:FillTable()
    local keyMap = FPXSDKBIDefine.ExtraKey.battle_entry_main
    local extraData = {}
    extraData[keyMap.exist_id] = self.curOpenedEntryIds
    extraData[keyMap.alliance_id] = (ModuleRefer.AllianceModule:GetMyAllianceData() or {}).ID or 0
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.battle_entry_main, extraData)
end

function BattleEntryMediator:OnHide()
end

function BattleEntryMediator:FillTable()
    self.tableBattles:Clear()
    table.clear(self.curOpenedEntryIds)
    local cellList = {}
    for _, v in ConfigRefer.BattleEntry:ipairs() do
        table.insert(cellList, v)
    end
    table.sort(cellList, function(a, b)
        return a:Priority() < b:Priority()
    end)
    for _, v in ipairs(cellList) do
        if ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(v:SystemSwitch()) then
            self.tableBattles:AppendData(v)
            table.insert(self.curOpenedEntryIds, v:Id())
        end
    end
end

return BattleEntryMediator