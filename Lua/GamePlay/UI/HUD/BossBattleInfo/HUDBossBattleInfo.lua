local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')
local DBEntityType = require('DBEntityType')    

---@class HUDBossBattleInfo : BaseUIComponent
local HUDBossBattleInfo = class('HUDBossBattleInfo', BaseUIComponent)

function HUDBossBattleInfo:ctor()

end

function HUDBossBattleInfo:OnCreate()    
    ---@type GvEBossInfo
    self.compChildLeagueBehemothTopInfo = self:LuaObject('child_league_behemoth_top_info')
end


function HUDBossBattleInfo:OnShow(param)        
    g_Game.DatabaseManager:AddChanged(DBEntityPath.MapMob.Battle.MsgPath,Delegate.GetOrCreate(self,self.OnBossChanged))
end

function HUDBossBattleInfo:OnHide(param)    
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapMob.Battle.MsgPath,Delegate.GetOrCreate(self,self.OnBossChanged))
end


---@param data wds.MapMob
---@param changed wds.Battle
function HUDBossBattleInfo:OnBossChanged(data,changed)
    if not self.focusBoss or self.focusBoss.ID ~= data.ID then
        return
    end

    -- self.imgProgressFillA.fillAmount = 1
    if changed.Hp or (changed.Group and changed.Group.Heros and changed.Group.Heros[0] ) then
        -- local hpPct = data.Battle.Hp / data.Battle.MaxHp
        -- self.sliderProgressFillB.value = hpPct
        -- self.textBloodNum.text = NumberFormatter.PercentKeep2(hpPct)
        self.compChildLeagueBehemothTopInfo:OnBossChanged(data)
    end
end

function HUDBossBattleInfo:GetEndTime(cage)
    if not cage then
        return nil
    end
     local allianceID = ModuleRefer.AllianceModule:GetAllianceId()
     local villageWarStatusInfo = ModuleRefer.VillageModule:GetBehemothCageWarInfo(cage, allianceID)
     if not villageWarStatusInfo or villageWarStatusInfo.Status < wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Battle then
         return nil
     end
    local _, timestamp = ModuleRefer.VillageModule:GetBehemothCountDown(cage, allianceID)
    return timestamp   
end

function HUDBossBattleInfo:OnFeedData(param)
    ---@type wds.MapMob
    self.focusBoss = param.bossData

    local cageId =  self.focusBoss.MobInfo.BehemothCageId
    if cageId > 0 then
        self.cageEntity = g_Game.DatabaseManager:GetEntity(cageId, DBEntityType.BehemothCage)
    end
   
    -- ---@type GvEBossInfoData
    local bossInfoData = {}
    bossInfoData.bossData = param.bossData
    bossInfoData.endTime = self:GetEndTime(self.cageEntity)

    self.compChildLeagueBehemothTopInfo:OnFeedData(bossInfoData)
end



return HUDBossBattleInfo
