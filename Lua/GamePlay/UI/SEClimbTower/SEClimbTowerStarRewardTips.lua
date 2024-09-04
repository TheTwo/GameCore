local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require('ConfigRefer')

---@class SEClimbTowerStarRewardTipsData
---@field chapterId number

---@class SEClimbTowerStarRewardTips:BaseUIComponent
---@field new fun():SEClimbTowerStarRewardTips
---@field super BaseUIComponent
local SEClimbTowerStarRewardTips = class('SEClimbTowerStarRewardTips', BaseUIComponent)

function SEClimbTowerStarRewardTips:OnCreate()
    self.btnClose = self:Button('p_btn_base', Delegate.GetOrCreate(self, self.OnCloseClick))

    self.txtTitle = self:Text('p_text_title_star', 'setower_title_star')
    self.progress = self:Slider('p_progress_star')
    self.txtStarInfo = self:Text('p_text_star_number')

    ---@type SEClimbTowerStarRewardTipsItem
    self.box1 = self:LuaObject('p_item_star_1')
    self.box2 = self:LuaObject('p_item_star_2')
    self.box3 = self:LuaObject('p_item_star_3')
    self.box4 = self:LuaObject('p_item_star_4')
    self.box5 = self:LuaObject('p_item_star_5')

    self.allBox = {}
    table.insert(self.allBox, self.box1)
    table.insert(self.allBox, self.box2)
    table.insert(self.allBox, self.box3)
    table.insert(self.allBox, self.box4)
    table.insert(self.allBox, self.box5)

    self.RevisedProcessTable = {
        0.600, 0.600, 0.600, 0.600, 0.600, 0.597,
        0.607, 0.616, 0.625, 0.634, 0.643, 0.670,
        0.689, 0.698, 0.707, 0.716, 0.725, 0.750,
        0.778, 0.787, 0.796, 0.805, 0.814, 0.830,
        0.858, 0.867, 0.876, 0.885, 0.894, 0.903
    }
end

function SEClimbTowerStarRewardTips:OnShow()
    g_Game.EventManager:AddListener(EventConst.SE_CLIMB_TOWER_STAR_REWARD_BOX_SHOW_TIPS, Delegate.GetOrCreate(self, self.OnShowRewardBoxTips))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.ClimbTower.ChapterAllStarNumRewardHistorys.MsgPath, Delegate.GetOrCreate(self, self.OnStarRewardDBChanged))
end

function SEClimbTowerStarRewardTips:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.SE_CLIMB_TOWER_STAR_REWARD_BOX_SHOW_TIPS, Delegate.GetOrCreate(self, self.OnShowRewardBoxTips))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.ClimbTower.ChapterAllStarNumRewardHistorys.MsgPath, Delegate.GetOrCreate(self, self.OnStarRewardDBChanged))
end

---@param data SEClimbTowerStarRewardTipsData
function SEClimbTowerStarRewardTips:OnFeedData(data)
    self.chapterId = data.chapterId
    self:UpdateUI()
end

-- 适配弧形进度条，从0.6处开始，到0.9结束
function SEClimbTowerStarRewardTips:GetRevisedProcess(achieved, total)
    local revisedProcess = self.RevisedProcessTable[achieved] or 0
    return math.clamp(revisedProcess, 0.6, 0.9)
end 

function SEClimbTowerStarRewardTips:UpdateUI()
    local achieved, total = ModuleRefer.SEClimbTowerModule:GetChaperStars(self.chapterId)
    self.progress.value = self:GetRevisedProcess(achieved, total)
    self.txtStarInfo.text = string.format('%s/%s', achieved, total)

    for i, v in ipairs(self.allBox) do
        ---@type SEClimbTowerStarRewardTipsItemData
        local itemData = {}
        itemData.chapterId = self.chapterId
        itemData.index = i

        ---@type SEClimbTowerStarRewardTipsItem
        local item = v
        item:FeedData(itemData)
    end
end

function SEClimbTowerStarRewardTips:OnShowRewardBoxTips(chapterId, index)
    ---@type ClimbTowerChapterStarRewardConfigCell
    local starRewardConfigCell = ModuleRefer.SEClimbTowerModule:GetStarRewardConfigCell(chapterId, index)
    
    ---@type SEClimbTowerStarRewardTipsItem
    local box = self.allBox[index]
    ModuleRefer.SEClimbTowerModule:ShowRewardTips('setower_btn_starreward', starRewardConfigCell:Reward(), box:GetClickTrans())
end

function SEClimbTowerStarRewardTips:OnCloseClick()
    self:SetVisible(false)
end

function SEClimbTowerStarRewardTips:OnStarRewardDBChanged()
    self:UpdateUI()
end

return SEClimbTowerStarRewardTips