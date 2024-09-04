local BaseTableViewProCell = require ('BaseTableViewProCell')
local ArtResourceUtils = require("ArtResourceUtils")
local I18N = require("I18N")

---@class SEHudMonsterDetailCell : BaseTableViewProCell
local SEHudMonsterDetailCell = class('SEHudMonsterDetailCell', BaseTableViewProCell)

function SEHudMonsterDetailCell:ctor()

end

function SEHudMonsterDetailCell:OnCreate(param)
    self.imageMonster = self:Image('p_img_monster')
    self.textName = self:Text('p_text_name')
    self.textDetail = self:Text('p_text_detail')
    self.goBoss = self:GameObject('p_boss')
    self.textBoss = self:Text('p_text_boss')
end


function SEHudMonsterDetailCell:OnShow(param)
    
end

function SEHudMonsterDetailCell:OnOpened(param)
end

function SEHudMonsterDetailCell:OnClose(param)
end

function SEHudMonsterDetailCell:OnFeedData(param)
    if (not param or not param.image) then
        self.imageMonster.gameObject:SetActive(false)
        return
    end
    self.imageMonster.gameObject:SetActive(true)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(param.image), self.imageMonster)
    self.textName.text = param.name
    self.textDetail.text = param.detail
    self.goBoss:SetActive(param.isBoss == true)
    if (param.isBoss == true) then
        self.textBoss.text = I18N.Get("*BOSS")
    end
end

return SEHudMonsterDetailCell;

