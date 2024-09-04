local ModuleRefer = require('ModuleRefer')
local BaseUIComponent = require("BaseUIComponent")
local ConfigRefer = require("ConfigRefer")
local HeroUIUtilities = require("HeroUIUtilities")
local UIHelper = require("UIHelper")
local UIHeroLocalData = require("UIHeroLocalData")

---@class ReplicaPVPSlotComponent : BaseUIComponent
---@field new fun():ReplicaPVPSlotComponent
---@field super BaseUIComponent
local ReplicaPVPSlotComponent = class("ReplicaPVPSlotComponent", BaseUIComponent)

function ReplicaPVPSlotComponent:OnCreate(param)
    self.goEmpty = self:GameObject('p_empty')
    self.goStatus = self:GameObject('p_status_n')

    self.goPet = self:GameObject('p_pet')
    self.imagePetFrame = self:Image('p_base_pet')
    self.imagePet = self:Image('p_img_pet')

    self.imgHeroFrame = self:Image('p_base_frame')
    self.imgHero = self:Image('p_img_hero')
    self.txtHeroLevel = self:Text('p_text_lv')

    ---@type UIHeroStrengthenCell
    -- self.heroStrenghCell = self:LuaObject('p_strengthen_hero_icon')

    ---@type UIHeroAssociateIconComponent
    self.heroStyle = self:LuaObject('p_icon_style')

    self.imgJob = self:Image('p_icon_job')
end

---@param data wds.HeroGrowthInfo
function ReplicaPVPSlotComponent:OnFeedData(data)
    self.goEmpty:SetVisible(data == nil)
    self.goStatus:SetVisible(data ~= nil)

    if data then
        self.data = data
        self:RefreshUI()
    end
end

function ReplicaPVPSlotComponent:RefreshUI()
    local petConfigCell = ConfigRefer.Pet:Find(self.data.Pet.CfgId)
    if petConfigCell then
        self.goPet:SetVisible(true)
        self:LoadSprite(petConfigCell:Icon(), self.imagePet)

        g_Game.SpriteManager:LoadSprite(ModuleRefer.PetModule:GetQualityCircleBackground(petConfigCell:Quality() + 2), self.imagePetFrame)
    else
        self.goPet:SetVisible(false)
    end

    local heroConfigCell = ConfigRefer.Heroes:Find(self.data.CfgId)
    local heroResConfigCell = ConfigRefer.HeroClientRes:Find(heroConfigCell:ClientResCfg())
    if heroConfigCell and heroResConfigCell then
        self:LoadSprite(HeroUIUtilities.GetQualitySpriteID(heroConfigCell:Quality()), self.imgHeroFrame)
        local heroIcon = UIHelper.GetFitHeroHeadIcon(self.imgHero, heroResConfigCell)
        self:LoadSprite(heroIcon, self.imgHero)
        self.txtHeroLevel.text = self.data.Level

        -- ---@type UIHeroStrengthenCellData
        -- local heroStrengthenCellData = {}
        -- heroStrengthenCellData.strengthLv = self.data.StrengthenLevel
        -- self.heroStrenghCell:FeedData(heroStrengthenCellData)

        ---@type AssociateIconParam
        local param = {}
        param.tagId = heroConfigCell:AssociatedTagInfo()
		self.heroStyle:FeedData(param)

        local battleStyle = heroConfigCell:BattleType()
        local styleIconPath = UIHeroLocalData.BATTLE_LABEL[battleStyle].icon
        g_Game.SpriteManager:LoadSprite(styleIconPath, self.imgJob)
    end
end

return ReplicaPVPSlotComponent
