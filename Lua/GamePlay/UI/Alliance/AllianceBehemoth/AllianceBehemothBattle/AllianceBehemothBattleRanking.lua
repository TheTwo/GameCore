local BaseUIComponent = require("BaseUIComponent")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
---@class AllianceBehemothBattleRanking : BaseUIComponent
local AllianceBehemothBattleRanking = class('AllianceBehemothBattleRanking', BaseUIComponent)

function AllianceBehemothBattleRanking:OnCreate()
    self.textTitleRanking = self:Text('p_text_title_ranking', 'alliance_behemoth_title_ranknum')
    self.textTitlePlayer = self:Text('p_text_title_player', 'alliance_behemoth_title_playername')
    self.textTitleOutput = self:Text('p_text_title_output', 'alliance_behemoth_title_damage')
    self.tableRanking = self:TableViewPro('table_ranking')
    ---@type CommonDropDown
    self.luaTypeDropdown = self:LuaObject('child_dropdown_scroll')
    self.textTitle = self:Text('p_text_title', 'alliance_behemoth_title_damagestatistics')
    ---@type GveBattleDamageInfoCell
    self.luaMyRank = self:LuaObject('p_mine')
end

---@param param wds.MapMob
function AllianceBehemothBattleRanking:OnFeedData(param)
    self.bossData = param
    self.luaMyRank:SetVisible(true)
    self:UpdateDamage()
end

function AllianceBehemothBattleRanking:OnShow(param)
    self.luaTypeDropdown:SetVisible(false)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.UpdateDamage))
end

function AllianceBehemothBattleRanking:OnHide(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.UpdateDamage))
end

function AllianceBehemothBattleRanking:UpdateDamage()
    self.tableRanking:Clear()
    local damageList, damageTotal, damageHighest = ModuleRefer.SlgModule:GetMobDamageData(self.bossData)
    local hasMyInfo = false
    for index, value in ipairs(damageList) do
        ---@type GveBattleDamageInfoCellData
        local info = {}
        info.index = index
        info.isSelf = ModuleRefer.PlayerModule:IsMineById(value.playerId)
        info.damageInfo = value
        info.allDamage = damageTotal
        info.maxPlayerDamage = damageHighest
        self.tableRanking:AppendData(info)
        if info.isSelf then
            hasMyInfo = true
            self.luaMyRank:FeedData(info)
        end
    end
    self.luaMyRank:SetVisible(hasMyInfo)
end

return AllianceBehemothBattleRanking