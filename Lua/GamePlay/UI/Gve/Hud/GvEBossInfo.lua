local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local NumberFormatter = require('NumberFormatter')
local GvEBossInfoAngeDot = require('GvEBossInfoAngeDot')
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')

---@class BossSkillInfo
---@field pct number
---@field desc string
---@field iconType number
---@field state number

---@class GvEBossInfoData
---@field bossData wds.MapMob
---@field endTime number
---@field fixTime number

---@class GvEBossInfo : BaseUIComponent
---@field bossData wds.MapMob
---@field endTime number
---@field fixTime number
---@field rageMax number
---@field skillInfo BossSkillInfo[]
---@field compDost GvEBossInfoAngeDot[]
local GvEBossInfo = class('GvEBossInfo', BaseUIComponent)

function GvEBossInfo:ctor()    
    self.rageMax = ModuleRefer.SlgModule:TroopRageMax()
end

function GvEBossInfo:OnCreate()
    
    self.imgImgMonster = self:Image('p_img_monster')
    self.textBossLv = self:Text('p_text_boss_lv')
    self.textName = self:Text('p_text_name')
    self.goTime = self:GameObject('p_time')
    self.compChildTime = self:LuaObject('child_time')

    -- self.imgProgressFillA = self:Image('p_progress_fill_a')
    self.sliderProgressFillB = self:Slider('p_progress_fill_b')
    self.textBloodNum = self:Text('p_text_blood_num')

    self.imgProgressFillC = self:Image('p_progress_fill_c')
    self.sliderProgressFillD = self:Slider('p_progress_fill_d')
    self.transDots = self:RectTransform('p_dots')
    self.compDotFirst = self:LuaBaseComponent('p_dot')
    self.compDots = {
        [1] = self.compDotFirst
    }
    self.goToastSkill = self:GameObject('p_toast_skill')
    self.imgIconSkill = self:Image('p_icon_skill')
    self.textSkill = self:Text('p_text_skill')
    self.goToastSkill:SetVisible(false)

    self.toastAnim = self:AnimTrigger('vx_trigger')
end


function GvEBossInfo:OnShow(param)    
    g_Game.EventManager:AddListener(EventConst.FOCUS_BOSS_EXECUTE_SKILL, Delegate.GetOrCreate(self, self.OnBossSkillReleased))      
end

function GvEBossInfo:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.FOCUS_BOSS_EXECUTE_SKILL, Delegate.GetOrCreate(self, self.OnBossSkillReleased))
    if self.timer and self.timer.running then
        self.timer:Stop()
        self.timer = nil
    end
end

function GvEBossInfo:OnOpened(param)
end

function GvEBossInfo:OnClose(param)
end

---@param GvEBossInfoData
function GvEBossInfo:OnFeedData(param)
    if not self.bossData or self.bossData.ID ~= param.bossData.ID then
        self.lastRageValue = 0
        self.curWarningIndex = -1
    end
    self.bossData = param.bossData
    self.endTime = param.endTime
    self.fixTime = param.fixTime
    self:FeedBossInfo()
end

function GvEBossInfo:FeedBossInfo()    
    if not self.bossData 
        or not self.bossData.Battle 
        or not self.bossData.Battle.Group 
        or not self.bossData.Battle.Group.Heros 
        or not self.bossData.Battle.Group.Heros[0]
    then
        return
    end   
    local heroData = self.bossData.Battle.Group.Heros[0]
    local heroId = heroData.HeroID
    local heroCfg = ConfigRefer.Heroes:Find(heroId)
    
    self.textName.text = I18N.Get(heroCfg:Name())
    
    ---@type CommonTimerData
    local timerParam = {}
    if self.endTime then
        self.goTime:SetActive(true)
        self.compChildTime:SetVisible(true)
        timerParam.needTimer = true
        timerParam.endTime = self.endTime
        self.compChildTime:FeedData(timerParam)    
    elseif self.fixTime then
        self.goTime:SetActive(true)
        self.compChildTime:SetVisible(true)
        timerParam.fixTime = self.fixTime
        self.compChildTime:FeedData(timerParam)    
    else
        self.goTime:SetActive(false)
        self.compChildTime:SetVisible(false)
    end

    local heroClientRes = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    self:LoadSprite( heroClientRes:HeadMini(), self.imgImgMonster )
    self.textBossLv.text = tostring(heroData.HeroLevel)

    local dotsCount = #self.compDots
    if dotsCount > 0 then
        for i = 1, dotsCount do
            self.compDots[i]:SetVisible(false)
        end
    end

    local mobCfg = ConfigRefer.KmonsterData:Find(self.bossData.MobInfo.MobID)
    local behemothCfg = mobCfg and ConfigRefer.BehemothData:Find(mobCfg:BehemothInfo()) or nil
    if behemothCfg then
        local skillCount = behemothCfg:SkillOrderLength()
        local waringCount = behemothCfg:WarningPercentOrderLength()
        if skillCount <= 0 then
            self.skillInfo = nil
        else
            local dotPosMax = self.transDots.sizeDelta.x
            local ragePct = self.bossData.Battle.RageValue / self.rageMax
            self.skillInfo = {}
            for i = 1, skillCount do
                local skillInfoId = behemothCfg:SkillOrder(i)
                local skillInfoCfg = ConfigRefer.SlgSkillInfo:Find(skillInfoId)
                local skillLogicId = skillInfoCfg and skillInfoCfg:SkillId() or 0
                local kSkillLogicCfg = ConfigRefer.KheroSkillLogical:Find(skillLogicId)
                if not kSkillLogicCfg then
                    goto continue
                end
                self.skillInfo[i] = {}
                self.skillInfo[i].index = i
                self.skillInfo[i].skillId = skillLogicId                
                self.skillInfo[i].pct = behemothCfg:PercentOrder(i)
                if i > waringCount then
                    self.skillInfo[i].warningPct = self.skillInfo[i].pct - 0.02
                else
                    self.skillInfo[i].warningPct = behemothCfg:WarningPercentOrder(i)
                end
                self.skillInfo[i].desc = behemothCfg:BehemothDes(i)
                self.skillInfo[i].iconType = behemothCfg:BehemothIcon(i)
                self.skillInfo[i].state = 
                    (ragePct > self.skillInfo[i].pct) 
                    and GvEBossInfoAngeDot.State.Idle or GvEBossInfoAngeDot.State.Sleep

                self.skillInfo[i].skillIcon = kSkillLogicCfg:SkillPic()
                self.skillInfo[i].skillAssetId = kSkillLogicCfg:Asset()

                if i > dotsCount then
                    local dot = UIHelper.DuplicateUIComponent(self.compDotFirst, self.transDots)
                    self.compDots[i] = dot
                end
                self.compDots[i]:SetVisible(true)
                self.compDots[i].Lua:SetupDot(dotPosMax * self.skillInfo[i].pct, self.skillInfo[i].iconType)
                self.compDots[i].Lua:SetState(self.skillInfo[i].state)
                ::continue::
            end
            if ragePct >= 1 or ragePct < self.lastRageValue then
                self.toastAnim:PlayAll(FpAnimTriggerEvent.Custom3)
            end
        end
    end
    self.curWarningIndex = -1
    self:OnBossChanged(self.bossData)
end


---@param data wds.MapMob
function GvEBossInfo:OnBossChanged(data)

    -- self.imgProgressFillA.fillAmount = 1
    local hpPct = data.Battle.Hp / data.Battle.MaxHp
    self.sliderProgressFillB.value = hpPct
    self.textBloodNum.text = NumberFormatter.PercentKeep2(hpPct)
    
    self.imgProgressFillC.fillAmount = 1
    local rageValue = data.Battle.Group.Heros[0].RageValue
    local ragePct = rageValue / self.rageMax
    self.sliderProgressFillD.value = ragePct
    
    if self.skillInfo then
        local warIndex = 1
        for i = 1, #self.skillInfo do
            if self.skillInfo[i].pct <= ragePct then
                warIndex = i + 1
            else
                break
            end
        end
        
        if warIndex ~= self.curWarningIndex
            and warIndex <=  #self.skillInfo 
            and ragePct > ( self.skillInfo[warIndex].warningPct)             
        then            

            if self.curWarningIndex > 0 then
                self.skillInfo[self.curWarningIndex].state = GvEBossInfoAngeDot.State.Idle
                self.compDots[self.curWarningIndex].Lua:SetState(GvEBossInfoAngeDot.State.Idle)
            end

            self.curWarningIndex = warIndex
            self.skillInfo[warIndex].state = GvEBossInfoAngeDot.State.Active
            ---@type GvEBossInfoAngeDot
            local compObj = self.compDots[warIndex].Lua
            compObj:SetState(self.skillInfo[warIndex].state)
            self:SetupSkillWaring(self.skillInfo[warIndex], compObj)
        -- elseif self.curWarningIndex > 0 then
        --     if(ragePct > self.skillInfo[self.curWarningIndex].pct+ 0.02) then
        --         self.goToastSkill:SetVisible(false)
        --         self.skillInfo[self.curWarningIndex].state = GvEBossInfoAngeDot.State.Idle
        --         self.compDots[self.curWarningIndex].Lua:SetState(GvEBossInfoAngeDot.State.Idle)
        --         self.curWarningIndex = -1
        --     end
        elseif self.curWarningIndex < 0 then
            self.goToastSkill:SetVisible(false)
        end
    end
end

---@param skillInfo BossSkillInfo
---@param dotObj GvEBossInfoAngeDot
function GvEBossInfo:SetupSkillWaring(skillInfo,dotObj)
    if not skillInfo then        
        return
    end
    self.goToastSkill:SetVisible(true)
    self.toastAnim:PlayAll(FpAnimTriggerEvent.Custom1)
    dotObj:PlayFpAnim(FpAnimTriggerEvent.Custom1)
    if skillInfo.skillIcon then
        self.imgIconSkill:SetVisible(true)
        self:LoadSprite(skillInfo.skillIcon, self.imgIconSkill)
    else
        self.imgIconSkill:SetVisible(false)
    end
    self.textSkill.text = I18N.Get(skillInfo.desc)
end

function GvEBossInfo:OnBossSkillReleased(skillIds)
    if not self.skillInfo or not skillIds or #skillIds < 1 then return end
    
    local skillIndex = -1    
    for i = 1, #self.skillInfo do
        for j = 1, #skillIds do
            g_Logger.LogChannel("GvEBossInfo", "OnBossSkillReleased:" .. tostring(skillIds[j]))
            if self.skillInfo[i].skillId == skillIds[j] then
                skillIndex = i               
                break
            end
        end
        if skillIndex > 0 then
            break
        end
    end
    if skillIndex < 0 then
        return
    end
    self.curWarningIndex = -1
    local skillCache = ModuleRefer.SlgModule.dataCache:GetSkillAssetCache(self.skillInfo[skillIndex].skillIdllId)
    local delayDuration = 1
    if skillCache then
        delayDuration = skillCache.animDuration
    end
    if self.timer and self.timer.running then
        self.timer:Stop()
    end
    self.timer =TimerUtility.DelayExecute(function()
        if self then
            self:HideBossSkillWaring(skillIndex)
        end
    end, delayDuration)

end


function GvEBossInfo:HideBossSkillWaring(index)
    if self.skillInfo and self.skillInfo[index] then
        self.skillInfo[index].state = GvEBossInfoAngeDot.State.Idle
    end

    if self.toastAnim then
        self.toastAnim:PlayAll(FpAnimTriggerEvent.Custom2)
    end
    if self.compDots and self.compDots[index] then
        self.compDots[index].Lua:PlayFpAnim(FpAnimTriggerEvent.Custom2)    
        self.timer = TimerUtility.DelayExecute(function()
            if self.compDots and self.compDots[index] then
                self.compDots[index].Lua:SetState(self.skillInfo[index].state)
            end
            if self.goToastSkill then
                self.goToastSkill:SetVisible(false)
            end
        end, 0.3)
    end
end


return GvEBossInfo
