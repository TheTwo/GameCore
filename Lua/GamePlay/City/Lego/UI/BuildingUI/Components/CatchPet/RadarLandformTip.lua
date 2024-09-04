local I18N = require('I18N')
local BaseUIMediator = require("BaseUIMediator")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local TimerUtility = require('TimerUtility')

---@class RadarLandformTipParameter
---@field landCfgId number @LandConfigCell Id

---@class RadarLandformTip:BaseUIMediator
---@field new fun():RadarLandformTip
---@field super BaseUIMediator
local RadarLandformTip = class('RadarLandformTip', BaseUIMediator)

---@param param RadarLandformTipParameter
function RadarLandformTip:OnCreate(param)
    self.landCfgId = param.landCfgId
    self.needGoto = param.needGoto or false
    self.hideAll = param.hideAll or false

    self.imgBanner = self:Image('p_banner_landform')
    self.txtTitle = self:Text('p_text_title')

    self.txtPetSubtitle = self:Text('p_text_subtitle', 'bw_newcircle_info_3')
    self.txtPetQualityPre = self:Text('p_text_quality_1', 'bw_info_petrarerange')
    self.txtPetQuality = self:Text('p_text_quality')
    self.tablePet = self:TableViewPro('p_table_pet')
    self.btnPetProbability = self:Button('p_btn_info', Delegate.GetOrCreate(self, self.OnPetProbabilityClick))

    self.goGroupMonster = self:GameObject('p_monster')
    self.txtMonsterSubtitle = self:Text('p_text_subtitle_monster', 'bw_newcircle_info_4')
    self.txtMonsterQualityPre = self:Text('p_text_quality_monster_1', 'bw_info_moblevelrange')
    self.txtMonsterQuality = self:Text('p_text_quality_monster')
    self.tableMonster = self:TableViewPro('p_table_monster')

    self.goGroupBoss = self:GameObject('p_boss')
    self.txtBossSubtitle = self:Text('p_text_subtitle_boss', 'bw_newcircle_info_5')
    self.txtBossQualityPre = self:Text('p_text_quality_boss_1', 'bw_info_moblevelrange')
    self.txtBossQuality = self:Text('p_text_quality_boss')
    self.tableBoss = self:TableViewPro('p_table_boss')

    self.p_btn_goto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.p_text_goto = self:Text('p_text_goto', 'bw_btn_goto_landmod')
end

function RadarLandformTip:OnShow(param)
    self.content = param.content
    self.title = param.title

    self:RefreshUI()
end

function RadarLandformTip:OnHide(param)

end

function RadarLandformTip:RefreshUI()
    local landCfgCell = ConfigRefer.Land:Find(self.landCfgId)
    g_Game.SpriteManager:LoadSprite(landCfgCell:Iconbg(), self.imgBanner)
    self.txtTitle.text = I18N.Get(landCfgCell:Name())

    self.tablePet:Clear()
    self.txtPetQuality.text = I18N.Get(landCfgCell:DiscPet())
    local petCount = landCfgCell:UnlockPetLength()
    local petVillageCount = landCfgCell:UnlockPetVillageLength()
    for i = 1, petVillageCount do
        local unlockPet = landCfgCell:UnlockPetVillage(i)
        ---@type LandformImageCellData
        local petCellData = {}
        petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
        petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
        petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
        petCellData.isVillagePet = true
        self.tablePet:AppendData(petCellData)
    end
    for i = 1, petCount do
        local unlockPet = landCfgCell:UnlockPet(i)
        ---@type LandformImageCellData
        local petCellData = {}
        petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
        petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
        petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
        self.tablePet:AppendData(petCellData)
    end

    local monsterCount = landCfgCell:UnlockMobLength()
    self.goGroupMonster:SetVisible(monsterCount > 0)
    if monsterCount > 0 then
        self.txtMonsterQuality.text = I18N.Get(landCfgCell:DiscMonster())
        self.tableMonster:Clear()
        for i = 1, monsterCount do
            local unlockMonster = landCfgCell:UnlockMob(i)
            ---@type LandformImageCellData
            local monsterCellData = {}
            monsterCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromKmonsterDataCfgId(unlockMonster)
            monsterCellData.nameKey = ModuleRefer.LandformModule:GetNameFromKmonsterDataCfgId(unlockMonster)
            monsterCellData.descKey = ModuleRefer.LandformModule:GetDescFromKmonsterDataCfgId(unlockMonster)
            monsterCellData.isMonster = true
            monsterCellData.itemGroupId = ModuleRefer.LandformModule:GetRewardsFromKmonsterDataCfgId(unlockMonster)
            self.tableMonster:AppendData(monsterCellData)
        end
    end

    local bossCount = landCfgCell:UnlockEliteMobLength()
    self.goGroupBoss:SetVisible(bossCount > 0)
    if bossCount > 0 then
        self.txtBossQuality.text = I18N.Get(landCfgCell:DiscEliteMonster())
        self.tableBoss:Clear()
        for i = 1, bossCount do
            local unlockBoss = landCfgCell:UnlockEliteMob(i)
            ---@type LandformImageCellData
            local bossCellData = {}
            bossCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromKmonsterDataCfgId(unlockBoss)
            bossCellData.nameKey = ModuleRefer.LandformModule:GetNameFromKmonsterDataCfgId(unlockBoss)
            bossCellData.descKey = ModuleRefer.LandformModule:GetDescFromKmonsterDataCfgId(unlockBoss)
            bossCellData.isMonster = true
            bossCellData.itemGroupId = ModuleRefer.LandformModule:GetRewardsFromKmonsterDataCfgId(unlockBoss)
            self.tableBoss:AppendData(bossCellData)
        end
    end
end

function RadarLandformTip:OnPetProbabilityClick()
    ---@type LandformPetProbabilityMediatorParameter
    local param = {}
    param.landCfgId = self.landCfgId
    g_Game.UIManager:Open(UIMediatorNames.LandformPetProbabilityMediator, param)
end

function RadarLandformTip:OnClickGoto()
    local scene = g_Game.SceneManager.current
    local duration = 2

    g_Game.UIManager:CloseByName(UIMediatorNames.PetCollectionPhotoDetailMediator)
    g_Game.UIManager:CloseByName(UIMediatorNames.PetCollectionPhotoMediator)
    g_Game.UIManager:CloseByName(UIMediatorNames.UIPetMediator)
    g_Game.UIManager:CloseByName(UIMediatorNames.RadarLandformTip)
    g_Game.UIManager:CloseByName(UIMediatorNames.RadarMediator)

    if scene:IsInCity() then
        local callback = function()
            KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
            KingdomMapUtils.GetBasicCamera():ZoomToMaxSize(duration)
            TimerUtility.DelayExecute(function()
                g_Game.EventManager:TriggerEvent(EventConst.OPEN_LANDFORM_VIEW)
                g_Game.EventManager:TriggerEvent(EventConst.ON_LANDFORM_SELECT, self.landCfgId)
            end, duration)
        end
        scene:LeaveCity(callback)
    else
        KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
        KingdomMapUtils.GetBasicCamera():ZoomToMaxSize(duration)
        TimerUtility.DelayExecute(function()
            g_Game.EventManager:TriggerEvent(EventConst.OPEN_LANDFORM_VIEW)
            g_Game.EventManager:TriggerEvent(EventConst.ON_LANDFORM_SELECT, self.landCfgId)
        end, duration)
    end
end

return RadarLandformTip
