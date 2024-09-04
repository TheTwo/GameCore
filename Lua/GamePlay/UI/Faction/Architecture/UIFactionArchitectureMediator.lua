local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local UIFactionArchitectureMediator = class('UIFactionArchitectureMediator',BaseUIMediator)

function UIFactionArchitectureMediator:OnCreate()
    self.compChildPopupBaseL = self:LuaObject('child_popup_base_l')
    self.imgIconLogo = self:Image('p_icon_logo')
    self.goLine01 = self:GameObject('p_line_01')
    self.goGroup1 = self:GameObject('p_group_1')
    self.goGroup2 = self:GameObject('p_group_2')
    self.goGroup3 = self:GameObject('p_group_3')
    self.textAuthority1 = self:Text('p_text_authority_1')
    self.textAuthority2 = self:Text('p_text_authority_2')
    self.textAuthority3 = self:Text('p_text_authority_3')
    self.imgIconLogoA = self:Image('p_icon_logo_a')
    self.textNameA = self:Text('p_text_name_a')
    self.textStoryA = self:Text('p_text_story_a')
    self.imgIconLogoB = self:Image('p_icon_logo_b')
    self.textNameB = self:Text('p_text_name_b')
    self.textStoryB = self:Text('p_text_story_b')
    self.imgIconLogoC = self:Image('p_icon_logo_c')
    self.textNameC = self:Text('p_text_name_c')
    self.textStoryC = self:Text('p_text_story_c')

    self.textHintA = self:Text('p_text_hint_a', I18N.Get("sov_memo1"))
    self.textHintB = self:Text('p_text_hint_b', I18N.Get("sov_memo2"))
    self.textHintC = self:Text('p_text_hint_c', I18N.Get("sov_memo3"))
    self.goBase1 = self:GameObject('p_base_text_01')
    self.goBase2 = self:GameObject('p_base_text_02')
    self.goBase3 = self:GameObject('p_base_text_03')

    self.goGroups = {self.goGroup1, self.goGroup2, self.goGroup3}
    self.textAuthoritys = {self.textAuthority1, self.textAuthority2, self.textAuthority3}
    self.imgIconLogoRights = {self.imgIconLogoA, self.imgIconLogoB, self.imgIconLogoC}
    self.textNames = {self.textNameA, self.textNameB, self.textNameC}
    self.textStorys = {self.textStoryA, self.textStoryB, self.textStoryC}
    self.textHints = {self.textHintA, self.textHintB, self.textHintC}
    self.goBases = {self.goBase1, self.goBase2, self.goBase3}
end

function UIFactionArchitectureMediator:OnOpened(param)
    self.compChildPopupBaseL:OnFeedData({title = I18N.Get("sov_structure")})
    self.factionId = param.factionId
    local factionCfg = ConfigRefer.Sovereign:Find(self.factionId)
    g_Game.SpriteManager:LoadSprite(factionCfg:Icon(), self.imgIconLogo)
    local seasonOrgCfg = ConfigRefer.SovereignSeasonOrg:Find(factionCfg:SeasonInfo())
    local orgList = {}
    for i = 1, seasonOrgCfg:SeasonOrgLength() do
        orgList[#orgList + 1] = seasonOrgCfg:SeasonOrg(i):Org()
    end
    local isHasLight = false
    for index = 1, 3  do
        local id = orgList[index]
        local cfg = ConfigRefer.SovereignOrg:Find(id)
        g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.imgIconLogoRights[index])
        local isCanUp = index == ModuleRefer.FactionModule:GetSeason()
        self.textNames[index].text = I18N.Get(cfg:Name())
        self.textHints[index].gameObject:SetActive(isCanUp)
        self.textStorys[index].text = I18N.Get(cfg:Desc())
        local stage, orgReputation = ModuleRefer.FactionModule:GetOrgReputation(self.factionId, index)
        self.textAuthoritys[index].text = I18N.Get(orgReputation:Relation())
        if stage > 1 then
            isHasLight = true
        end
        self.goGroups[index]:SetActive(stage > 1)
        self.goBases[index]:SetActive(stage > 1)
    end
    self.goLine01:SetActive(isHasLight)
end

function UIFactionArchitectureMediator:OnClose()

end

return UIFactionArchitectureMediator