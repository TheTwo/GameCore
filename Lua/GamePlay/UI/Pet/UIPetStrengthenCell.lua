local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
---@class UIPetStrengthenCellData
---@field petId number
---@field petStrengthenLv number
---@field unlockNum number


---@class UIPetStrengthenCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIPetStrengthenCell = class('UIPetStrengthenCell', BaseTableViewProCell)

function UIPetStrengthenCell:OnCreate()
    self.imgIconStrengthen = self:Image('p_icon_strengthen')
    self.imgIconSatr1 = self:Image('p_icon_satr_1')
    self.imgIconSatr2 = self:Image('p_icon_satr_2')
    self.imgIconSatr3 = self:Image('p_icon_satr_3')
    self.imgIconSatr4 = self:Image('p_icon_satr_4')
    self.imgIconSatr5 = self:Image('p_icon_satr_5')
    self.imgStars = {self.imgIconSatr1, self.imgIconSatr2, self.imgIconSatr3, self.imgIconSatr4, self.imgIconSatr5}
end

---@param param UIPetStrengthenCellData
function UIPetStrengthenCell:OnFeedData(param)
    local rankLevel = param.petStrengthenLv or 0
    local petId = param.petId
    local unlockNum = param.unlockNum

    local stageLevel = math.floor(rankLevel / 5)
    local showIndex = rankLevel % 5
    local broken = false
    local petCfg = ConfigRefer.Pet:Find(petId)
	local cfg = ConfigRefer.PetRankLevelUpCost:Find(petCfg:RankLevelUpCost())
	if cfg then
		for i = 1, cfg:ItemsLength() do
			local item = cfg:Items(i)
			if i + 1 == unlockNum and item:DestLevel() == rankLevel then
				broken = true
			end
		end
	end
	if broken then
		if rankLevel == 0 or showIndex ~= 0 then
			stageLevel = stageLevel + 1
		end
		stageLevel = stageLevel + 1
		for i, star in ipairs(self.imgStars) do
			star.gameObject:SetActive(false)
		end
    else
        if rankLevel == 0 or showIndex ~= 0 then
            stageLevel = stageLevel + 1
            for i, star in ipairs(self.imgStars) do
                if i < #self.imgStars then
                    g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s_s", star)
                else
                    g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l_s", star)
                end
                star.gameObject:SetActive(i <= showIndex)
            end
        else
            for i, star in ipairs(self.imgStars) do
                if i < #self.imgStars then
                    g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_s_s", star)
                else
                    g_Game.SpriteManager:LoadSprite("sp_pet_icon_lv" .. stageLevel .. "_star_l_s", star)
                end
                star.gameObject:SetActive(true)
            end
        end
    end
    if stageLevel <= ConfigRefer.PetConsts:PetRankTinyIconLength() then
        local icon = ConfigRefer.PetConsts:PetRankTinyIcon(stageLevel)
        self:LoadSprite(icon, self.imgIconStrengthen)
    end

end

function UIPetStrengthenCell:OnShow(param)

end

function UIPetStrengthenCell:OnHide(param)

end

return UIPetStrengthenCell;
