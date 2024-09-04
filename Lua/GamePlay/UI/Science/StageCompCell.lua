local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local CastleUnlockTechStageParameter = require("CastleUnlockTechStageParameter")
local I18N = require('I18N')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local StageCompCell = class('StageCompCell',BaseUIComponent)

function StageCompCell:OnCreate(param)
    self.goRoot = self:GameObject("")
    self.textTitleCondition = self:Text('p_text_title_condition', I18N.Get("tech_info_preperation"))
    self.goCondition1 = self:GameObject('p_condition_1')
    self.imgIconCondition1 = self:Image('p_icon_condition_1')
    self.textTitleCondition1 = self:Text('p_text_title_condition_1')
    self.textCondition1 = self:LuaObject('p_text_condition_1')
    self.btnGoto1 = self:Button('p_btn_goto_1', Delegate.GetOrCreate(self, self.OnBtnGoto1Clicked))
    self.goReach1 = self:GameObject('p_reach_1')
    self.goCondition2 = self:GameObject('p_condition_2')
    self.imgIconCondition2 = self:Image('p_icon_condition_2')
    self.textTitleCondition2 = self:Text('p_text_title_condition_2', I18N.Get("tech_info_schedule"))
    self.textCondition2 = self:LuaObject('p_text_condition_2')
    self.btnGoto2 = self:Button('p_btn_goto_2', Delegate.GetOrCreate(self, self.OnBtnGoto2Clicked))
    self.goReach2 = self:GameObject('p_reach_2')
    self.goCondition3 = self:GameObject('p_condition_3')
    self.imgIconCondition3 = self:Image('p_icon_condition_3')
    self.textTitleCondition3 = self:Text('p_text_title_condition_3')
    self.textCondition3 = self:LuaObject('p_text_condition_3')
    self.btnGoto3 = self:Button('p_btn_goto_3', Delegate.GetOrCreate(self, self.OnBtnGoto3Clicked))
    self.goDetail3 = self:GameObject('p_detail_3')
    self.goReach3 = self:GameObject('p_reach_3')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.btnGoto1.gameObject:SetActive(false)
    self.btnGoto2.gameObject:SetActive(false)
end

function StageCompCell:OnFeedData(stageId) --不能传相同table进去，所以传进来的是stageId*10000
    self.stageId = stageId / 10000
    local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    local newChapterData = {}
    newChapterData.onClick = Delegate.GetOrCreate(self, self.OnClickNewChapter)
    newChapterData.buttonText =  I18N.Get("tech_btn_openperiod")

    self.compChildCompB:OnFeedData(newChapterData)
    local isShow = ModuleRefer.ScienceModule:IsMeetAllStageConditions(self.stageId)
    local isLastStage = ConfigRefer.CityTechStage:Find(self.stageId):NextStage() == 0
    self.compChildCompB:SetEnabled(isShow and not isLastStage and curStage <= self.stageId)

    local stageConfig = ConfigRefer.CityTechStage:Find(self.stageId)
    local unlockBuilding = stageConfig:UnlockBuilding()
    self.goCondition1:SetActive(unlockBuilding > 0)
    if unlockBuilding > 0 then
        local buildingLevelCfg = ConfigRefer.BuildingLevel:Find(unlockBuilding)
        local buildingTypeCfg = ConfigRefer.BuildingTypes:Find(buildingLevelCfg:Type())
        local maxLevel, unlockLevel = ModuleRefer.ScienceModule:GetUnlockBuildingLevel(unlockBuilding)
        g_Game.SpriteManager:LoadSprite(buildingTypeCfg:Image(), self.imgIconCondition1)
        self.textTitleCondition1.text = I18N.Get(buildingTypeCfg:Name())
        local data = {}
        data.num1 = maxLevel
        data.num2 = unlockLevel
        data.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        self.textCondition1:FeedData(data)
        --self.btnGoto1.gameObject:SetActive(maxLevel < unlockLevel)
        self.goReach1:SetActive(maxLevel >= unlockLevel)
    end
    local unlockTechPoint = stageConfig:UnlockPoint()
    self.goCondition2:SetActive(unlockTechPoint > 0)
    if unlockTechPoint > 0 then
        local curPoint, _ = ModuleRefer.ScienceModule:GetstageProgress(self.stageId)
        local data = {}
        data.num1 = curPoint
        data.num2 = unlockTechPoint
        data.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        self.textCondition2:FeedData(data)
        --self.btnGoto2.gameObject:SetActive(curPoint < unlockTechPoint)
        self.goReach2:SetActive(curPoint >= unlockTechPoint)
    end
    local lastTech = stageConfig:LastTech()
    self.goCondition3:SetActive(lastTech > 0)
    if lastTech > 0 then
        local techLevelCfg = ConfigRefer.CityTechLevels:Find(lastTech)
        local level = techLevelCfg:Level()
        local techType = techLevelCfg:Type()
        local curTechLevel = ModuleRefer.ScienceModule:GetTeachLevel(techType)
        local techCfg = ConfigRefer.CityTechTypes:Find(techType)
        self:LoadSprite(techCfg:Image(), self.imgIconCondition3)
        self.textTitleCondition3.text = I18N.Get(techCfg:Name())
        local data = {}
        data.num1 = curTechLevel
        data.num2 = level
        data.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        self.textCondition3:FeedData(data)
        self.btnGoto3.gameObject:SetActive(level > curTechLevel)
        self.goReach3:SetActive(level <= curTechLevel)
    end
end

function StageCompCell:OnClickNewChapter()
    self.goRoot:SetActive(false)
    g_Game.EventManager:TriggerEvent(EventConst.ON_CLICK_NEW_CHAPTER)
    local param = CastleUnlockTechStageParameter.new()
    param.args.ConfigId = self.stageId + 1
    param:Send()
end

function StageCompCell:OnBtnGoto1Clicked(args)
    --local stageConfig = ConfigRefer.CityTechStage:Find(self.stageId)
    --local unlockBuilding = stageConfig:UnlockBuilding()
    --todo 跳转建筑？
end
function StageCompCell:OnBtnGoto2Clicked(args)
    --todo 引导去加科技点？
end
function StageCompCell:OnBtnGoto3Clicked(args)
    --todo 跳转到前置？
end

return StageCompCell
