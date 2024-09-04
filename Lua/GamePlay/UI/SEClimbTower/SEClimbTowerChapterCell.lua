local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIHelper = require("UIHelper")
local EventConst = require('EventConst')

---@class SEClimbTowerChapterCellData
---@field configCell ClimbTowerChapterConfigCell

---@class SEClimbTowerChapterCell:BaseTableViewProCell
---@field new fun():SEClimbTowerChapterCell
---@field super BaseTableViewProCell
local SEClimbTowerChapterCell = class('SEClimbTowerChapterCell', BaseTableViewProCell)

function SEClimbTowerChapterCell:OnCreate()
    self.btnClick = self:Button('p_btn_chapter', Delegate.GetOrCreate(self, self.OnClick))

    self.goLock = self:GameObject('p_lock')
    self.imgChapter = self:Image('p_img_chapter')
    self.txtStarInfo = self:Text('p_text_star_quantity')
    self.txtSymbol = self:Text('p_text_lv')
    self.txtChapterName = self:Text('p_text_name')
end

---@param data SEClimbTowerChapterCellData
function SEClimbTowerChapterCell:OnFeedData(data)
    self.cell = data.configCell
    self.txtChapterName.text = I18N.Get(self.cell:Name())
    self.txtSymbol.text = I18N.Get(self.cell:Symbol())
    self:LoadSprite(self.cell:Preview(), self.imgChapter)

    local curStars, totalStarts = ModuleRefer.SEClimbTowerModule:GetChaperStars(self.cell:Id())
    self.txtStarInfo.text = string.format('%s/%s', curStars, totalStarts)

    -- 是否解锁
    local isUnlock = ModuleRefer.SEClimbTowerModule:IsChapterUnlock(self.cell:Id())
    self.goLock:SetVisible(not isUnlock)
    UIHelper.SetGray(self.btnClick.gameObject, not isUnlock)
end

function SEClimbTowerChapterCell:OnClick()
    local isUnlock = ModuleRefer.SEClimbTowerModule:IsChapterUnlock(self.cell:Id())
    if not isUnlock then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('setower_tips_preschapter'))
        return
    end

    g_Game.EventManager:TriggerEvent(EventConst.SE_CLIMB_TOWER_CHAPTER_CLICK, self.cell:Id())
end

return SEClimbTowerChapterCell