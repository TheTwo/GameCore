---scene:scene_tips_monster_info

local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require("ConfigRefer")
local I18N = require('I18N')
local TipsRectTransformUtils = require('TipsRectTransformUtils')
local ModuleRefer = require('ModuleRefer')

---@class MonsterInfoTipsMediatorParameter
---@field iconId number
---@field nameKey string
---@field descKey string
---@field itemGroupId number
---@field clickTransform CS.UnityEngine.RectTransform

---@class TextToastMediator : BaseUIMediator
---@field super BaseUIMediator
local MonsterInfoTipsMediator = class('MonsterInfoTipsMediator', BaseUIMediator)

function MonsterInfoTipsMediator:OnCreate()
    self.goRoot = self:GameObject("")
    self.imgMonster = self:Image("p_img_monster")
    self.txtMonsterName = self:Text('p_text_name')
    self.txtDetail = self:Text('p_text_detail')
    self.txtRewards = self:Text('p_text_title', 'bw_info_land_mob_reward')
    self.tableRewards = self:TableViewPro('p_table_rewards')
end

---@param param MonsterInfoTipsMediatorParameter
function MonsterInfoTipsMediator:OnOpened(param)
    self:LoadSprite(param.iconId, self.imgMonster)
    self.txtMonsterName.text = I18N.Get(param.nameKey)
    self.txtDetail.text = I18N.Get(param.descKey)

    self.tableRewards:Clear()
    local itemGroupId = param.itemGroupId
    local itemIds = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(itemGroupId)
    for _, value in pairs(itemIds) do
        ---@type ItemIconData
        local cellData = {}
        cellData.configCell = ConfigRefer.Item:Find(value.id)
        cellData.showCount = false  
        self.tableRewards:AppendData(cellData)
    end

    TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(param.clickTransform, self.goRoot.transform, 1)
end

return MonsterInfoTipsMediator
