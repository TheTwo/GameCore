local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local GUILayout = require("GUILayout")
local RuntimeDebugSettings = require("RuntimeDebugSettings")

local GMPage = require("GMPage")

---@class GMPageAlliance:GMPage
---@field new fun():GMPageAlliance
---@field super GMPage
local GMPageAlliance = class('GMPageAlliance', GMPage)

function GMPageAlliance:ctor()
    self._allianceBattleId = ""
    self._queueIndex = ""
    self._villageId = ""
    self._time = 0
    self._blockRecommend = false
end

function GMPageAlliance:OnGUI()
    if ModuleRefer.AllianceModule:IsInAlliance() then
        GUILayout.BeginHorizontal()
        GUILayout.Label("AllianceId:", GUILayout.shrinkWidth)
        GUILayout.TextField(tostring(ModuleRefer.AllianceModule:GetAllianceId()))
        local o,t = ModuleRefer.AllianceModule:GetMyAllianceOnlineMemberCount()
        GUILayout.Label(string.format("%s/%s", o, t), GUILayout.shrinkWidth)
        GUILayout.EndHorizontal()
    end
    GUILayout.BeginHorizontal()
    GUILayout.Label("BattleId:", GUILayout.shrinkWidth)
    self._allianceBattleId = GUILayout.TextField(self._allianceBattleId)
    GUILayout.Label("QueueIndex:", GUILayout.shrinkWidth)
    self._queueIndex = GUILayout.TextField(self._queueIndex)
    GUILayout.EndHorizontal()
    self._blockRecommend = (g_Game.PlayerPrefsEx:GetInt("BlockRecommandToastKey") or 0) > 0
    local b = GUILayout.Toggle(self._blockRecommend, "屏蔽联盟推荐toast")
    if b ~= self._blockRecommend then
        self._blockRecommend = b
        g_Game.PlayerPrefsEx:SetInt("BlockRecommandToastKey", self._blockRecommend and 1 or 0)
    end
    GUILayout.BeginHorizontal()

    GUILayout.EndHorizontal()
    if ModuleRefer.AllianceModule:IsInAlliance() then
        GUILayout.BeginHorizontal()
        if GUILayout.Button("ActiveBattle") then
            local battleId = tonumber(self._allianceBattleId)
            if battleId then
                ModuleRefer.AllianceModule:ActivateAllianceActivityBattle(nil, battleId)
            end
        end
        if GUILayout.Button("SignUpBattle") then
            local battleId = tonumber(self._allianceBattleId)
            if battleId then
                local queue = {}
                if not string.IsNullOrEmpty(self._queueIndex) then
                    local qSplit = string.split(self._queueIndex, ',')
                    if qSplit then
                        for _, v in ipairs(qSplit) do
                            table.insert(queue, tonumber(v))
                        end
                    end
                end
                ModuleRefer.AllianceModule:SignUpAllianceActivityBattle(nil, battleId, queue)
            end
        end
        if GUILayout.Button("StartBattle") then
            local battleId = tonumber(self._allianceBattleId)
            local battleData = ModuleRefer.AllianceModule:GetAllianceActivityBattleData(battleId)
            if battleData then
                local isInBattle = battleData.Members[ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID] and true or false
                if battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
                    ModuleRefer.AllianceModule:StartAllianceActivityBattle(nil, battleId, function(cmd, isSuccess, rsp)
                        if isSuccess and isInBattle then
                            ModuleRefer.AllianceModule:EnterAllianceActivityBattleScene(nil, battleId)
                        end
                    end)
                elseif battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
                    ModuleRefer.AllianceModule:EnterAllianceActivityBattleScene(nil, battleId)
                else
                    g_Logger.Error("%s battle Status is %s", battleId, battleData.Status)
                end
            else
                g_Logger.Error("%s no battle Data", battleId)
            end
        end
        GUILayout.EndHorizontal()
        if GUILayout.Button("Dump") then
            local data = ModuleRefer.AllianceModule:GetMyAllianceData()
            local activityBattleInfo = data.AllianceActivityBattles
            if activityBattleInfo and activityBattleInfo.Battles then
                for k, v in pairs(activityBattleInfo.Battles) do
                    g_Logger.Log("key:%s", k)
                    dump(v)
                end
            end
        end
        GUILayout.BeginHorizontal()
        GUILayout.Label("villageId:", GUILayout.shrinkWidth)
        self._villageId = GUILayout.TextField(self._villageId)
        GUILayout.Label("time:", GUILayout.shrinkWidth)
        self._time = tonumber(GUILayout.TextField(tostring(self._time))) or 0
        if GUILayout.Button("Declare") then
            ModuleRefer.VillageModule:DoStartSignAttackVillage(nil, tonumber(self._villageId), g_Game.ServerTime:GetServerTimestampInSeconds() + self._time)
        end
        if GUILayout.Button("Cancel") then
            ModuleRefer.VillageModule:DoCancelDeclareWarOnVillage(nil, tonumber(self._villageId), nil)
        end
        if GUILayout.Button("Drop") then
            ModuleRefer.VillageModule:DoDropVillage(nil, tonumber(self._villageId))
        end
        GUILayout.EndHorizontal()
        GUILayout.BeginHorizontal()
        if GUILayout.Button("Dump Declaration") then
            dump(ModuleRefer.AllianceModule:GetMyAllianceVillageWars())
        end
        if GUILayout.Button("DumpVillage") then
            dump(ModuleRefer.VillageModule:GetAllVillageMapBuildingBrief())
        end
        GUILayout.EndHorizontal()
        if GUILayout.Button("发起弹劾") then
            ModuleRefer.AllianceModule:StartImpeachmentVote()
        end
        if GUILayout.Button("联盟礼物界面") then
            g_Game.UIManager:Open(require("UIMediatorNames").AllianceGiftMediator)
        end
        if GUILayout.Button("联盟帮助界面") then
            g_Game.UIManager:Open(require("UIMediatorNames").AllianceHelpMediator)
        end
    end
end

return GMPageAlliance