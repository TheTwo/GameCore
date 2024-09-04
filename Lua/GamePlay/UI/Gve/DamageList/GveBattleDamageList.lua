local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local NumberFormatter = require('NumberFormatter')
local DBEntityPath = require('DBEntityPath')
---@class GveBattleDamageList : BaseUIMediator
local GveBattleDamageList = class('GveBattleDamageList', BaseUIMediator)

function GveBattleDamageList:ctor()
    self.module = ModuleRefer.GveModule
    self.slgModule = ModuleRefer.SlgModule
    self.playerModule = ModuleRefer.PlayerModule
    self.damageDataList = {}
end

function GveBattleDamageList:OnCreate()
    self.textTitle = self:Text('p_text_title','gverating_outputrankTitle')
    self.textTitleRanking = self:Text('p_text_title_ranking','gverating_rank')
    self.textTitlePlayer = self:Text('p_text_title_player','gverating_commander')
    self.textTitleOutput = self:Text('p_text_title_output','gverating_totaloutput')
    self.damageDataTable = self:TableViewPro('table_ranking')
    self.myInfo = self:LuaObject('mine')
    self.myInfo:SetVisible(false)
end


function GveBattleDamageList:OnShow(param)
    self.bossId = self.module.curBoss and self.module.curBoss.ID
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapMob.DamageStatistic.TakeDamage.MsgPath,Delegate.GetOrCreate(self,self.OnDamageChanged))
    self:UpdateDamageInfo()
end

function GveBattleDamageList:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapMob.DamageStatistic.TakeDamage.MsgPath,Delegate.GetOrCreate(self,self.OnDamageChanged))
end

function GveBattleDamageList:OnOpened(param)
end

function GveBattleDamageList:OnClose(param)
end

---@param data wds.MapMob
---@param changed table<number, number>
function GveBattleDamageList:OnDamageChanged(data,changed)
    if data.ID ~= self.bossId then
        return
    end
    self:UpdateDamageInfo()
end

function GveBattleDamageList:UpdateDamageInfo()
    local damageList,allDamage,maxPlayerDamage = self.module:GetBossDamageDatas()
    self.damageDataList = damageList
    self.damageDataTable:Clear()
    local myInfo = nil
    for index, value in ipairs(self.damageDataList) do
        ---@type GveBattleDamageInfoCellData
        local info = {}
        info.index = index
        info.isSelf = ModuleRefer.PlayerModule:IsMineById(value.playerId)
        info.damageInfo = value
        info.allDamage = allDamage
        info.maxPlayerDamage = maxPlayerDamage
        self.damageDataTable:AddData(info)
        if not myInfo and info.isSelf then
            myInfo = info
        end
    end

    if myInfo then
        self.myInfo:SetVisible(true)
        self.myInfo:FeedData(myInfo)
    end
end


return GveBattleDamageList
