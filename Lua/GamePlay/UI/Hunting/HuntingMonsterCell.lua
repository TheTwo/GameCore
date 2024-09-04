local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local SEUnitCategory = require("SEUnitCategory")
local ArtResourceUtils = require('ArtResourceUtils')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local UIMediatorNames = require('UIMediatorNames')
---@class HuntingMonsterCell : BaseTableViewProCell
local HuntingMonsterCell = class('HuntingMonsterCell', BaseTableViewProCell)

---@class HuntingMonsterCellData
---@field sectionId number
---@field isUnlocked boolean

local CELL_STATUS = {
    BOSS = 0,
    NORMAL = 1,
    LOCKED = 2,
}

local REWARD_BASE_FRAME = {
    [0] = 'sp_item_frame_circle_0',
    [1] = 'sp_item_frame_circle_1',
    [2] = 'sp_item_frame_circle_2',
    [3] = 'sp_item_frame_circle_3',
    [4] = 'sp_item_frame_circle_4',
    [5] = 'sp_item_frame_circle_5',
}

function HuntingMonsterCell:OnCreate()
    self.btnMonster = self:Button('p_btn_monster', Delegate.GetOrCreate(self, self.OnBtnTabClicked))
    self.textLevel = self:Text('p_text_level', '*8-8')
    self.textName = self:Text('p_text_name', '*怪物名称')
    self.goIconStar = self:GameObject('p_icon_star')
    self.goSelected = self:GameObject('p_img_selected')
    self.goBaseNormalSelected = self:GameObject('p_base_selected')
    self.goBaseBossSelected = self:GameObject('p_base_boss_selected')

    self.imgBoss = self:Image('p_img_boss')
    self.imgMonster = self:Image('p_img_monster')
    self.imgLock = self:Image('p_img_lock')

    self.btnRewardIcon = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnRewardClicked))
    self.imgRewardIcon = self:Image('p_btn_reward')
    self.imgRewardBase = self:Image('p_base_frame')
    self.goReward = self:GameObject('group_reward')

    self.statusCtrler = self:StatusRecordParent('')
    self.animCellIn = self:BindComponent('p_cell_group', typeof(CS.UnityEngine.Animation))

    self.luaItem1 = self:LuaObject('p_item_1')
    self.luaItem2 = self:LuaObject('p_item_2')
    self.luaItems = {self.luaItem1, self.luaItem2}
end

---@param param HuntingMonsterCellData
function HuntingMonsterCell:OnFeedData(param)
    if not param then
        return
    end
    self.sectionId = param.sectionId
    self.isUnlocked = param.isUnLocked
    ---@type HuntingSectionInfo
    self.sectionInfo = ModuleRefer.HuntingModule:GetSectionInfo(self.sectionId)
    self.textLevel.text = I18N.Get(self.sectionInfo.sectionName)
    self.textName.text = I18N.Get(self.sectionInfo.monsterName)

    local importantRewardIds = self.sectionInfo.importantRewardId
    self:SetImportReward(importantRewardIds)

    local isBoss = self.sectionInfo.monsterType == SEUnitCategory.Boss
    local sprite = ArtResourceUtils.GetUIItem(self.sectionInfo.headPic)
    if not self.isUnlocked then
        -- self:LoadImg(sprite, self.imgLock)
        self.statusCtrler:ApplyStatusRecord(CELL_STATUS.LOCKED)
    elseif isBoss then
        self:LoadImg(sprite, self.imgBoss)
        self.statusCtrler:ApplyStatusRecord(CELL_STATUS.BOSS)
    else
        self:LoadImg(sprite, self.imgMonster)
        self.statusCtrler:ApplyStatusRecord(CELL_STATUS.NORMAL)
    end

    self.goIconStar:SetActive(self.sectionInfo.isFinished)
end

function HuntingMonsterCell:SetImportReward(importantReward)
    for i, luaItem in ipairs(self.luaItems) do
        local rewardId = importantReward[i]
        if rewardId then
            ---@type ItemIconData
            local data = {}
            data.showCount = false
            data.configCell = ConfigRefer.Item:Find(rewardId)
            luaItem:FeedData(data)
            luaItem:SetVisible(true)
        else
            luaItem:SetVisible(false)
        end
    end
end

function HuntingMonsterCell:OnShow()
    self.animCellIn:Play()
end

function HuntingMonsterCell:Select()
    if self.isUnlocked then
        self.goSelected:SetActive(true)
        self.goBaseBossSelected:SetActive(true)
        self.goBaseNormalSelected:SetActive(true)
        g_Game.EventManager:TriggerEvent(EventConst.HUNTING_MONSTER_CELL_SELECT, self.sectionInfo)
    end
end

function HuntingMonsterCell:UnSelect()
    self.goSelected:SetActive(false)
    self.goBaseBossSelected:SetActive(false)
    self.goBaseNormalSelected:SetActive(false)
end

function HuntingMonsterCell:OnBtnTabClicked()
    self:SelectSelf()
end

function HuntingMonsterCell:OnBtnRewardClicked()
    local param = {
        itemId = self.itemData:Id(),
        itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
    }
    self.tipsRuntimeId = g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

function HuntingMonsterCell:LoadImg(sprite, img)
    if not sprite or not img then
        return
    end
    g_Game.SpriteManager:LoadSprite(sprite, img)
end

return HuntingMonsterCell