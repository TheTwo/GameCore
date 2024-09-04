local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')
---@class KCWarDetailCellTroopData
---@field id number
---@field playerId number
---@field playerName string
---@field portrait number
---@field iconName string
---@field allianceAbbr string
---@field heroId number
---@field heroLvl number
---@field starLvl number
---@field count number
---@field maxCount number
---@param portraitInfo wds.PortraitInfo|wrpc.PortraitInfo

---@class KCWarDetailCell : BaseTableViewProCell
---@field troops wds.Troop[]
---@field goGroup CS.UnityEngine.GameObject[]            
---@field compChildCardHero HeroInfoItemComponent[]  
---@field textNamePlayer CS.UnityEngine.UI.Text[]     
---@field textNameOneself CS.UnityEngine.UI.Text[]    
---@field compPlayerInfo PlayerInfoComponent[]       
---@field textQuantity CS.UnityEngine.UI.Text[]       
---@field sliderGroupProgress CS.UnityEngine.UI.Slider[]
local KCWarDetailCell = class('KCWarDetailCell', BaseTableViewProCell)

function KCWarDetailCell:ctor()

end

function KCWarDetailCell:OnCreate()
    
    self.goGroup = {}    
    ---@see HeroInfoItemSmallComponent[]        
    self.compChildCardHero = {}  
    self.textNamePlayer = {}     
    self.textNameOneself = {}    
    ---@see PlayerInfoComponent[]
    self.compPlayerInfo = {}       
    self.textQuantity = {}       
    self.sliderGroupProgress = {}
    self.ids = {}

    self.goGroup[1]               = self:GameObject('p_group_l')
    self.compChildCardHero[1]     = self:LuaBaseComponent('child_card_hero_l')
    self.textNamePlayer[1]        = self:Text('p_text_name_player_l')
    self.textNameOneself[1]       = self:Text('p_text_name_oneself_l')
    self.compPlayerInfo[1]        = self:LuaBaseComponent('child_ui_head_playerl')
    self.textQuantity[1]          = self:Text('p_text_quantity_l')
    self.sliderGroupProgress[1]   = self:Slider('group_progress_l')
    
    self.goGroup[2]               = self:GameObject('p_group_r')
    self.compChildCardHero[2]     = self:LuaBaseComponent('child_card_hero_r')
    self.textNamePlayer[2]        = self:Text('p_text_name_player_r')
    self.textNameOneself[2]       = self:Text('p_text_name_oneself_r')
    self.compPlayerInfo[2]        = self:LuaBaseComponent('child_ui_head_player_r')
    self.textQuantity[2]          = self:Text('p_text_quantity_r')
    self.sliderGroupProgress[2]   = self:Slider('group_progress_r')
end


function KCWarDetailCell:OnShow(param)
end

function KCWarDetailCell:OnHide(param)
end

function KCWarDetailCell:OnOpened(param)
end

function KCWarDetailCell:OnClose(param)
end

---@param param WarGroupData
function KCWarDetailCell:OnFeedData(param)
    if param == nil then 
        self.goGroup[1]:SetVisible(false)
        self.goGroup[2]:SetVisible(false)
        return 
    end

    if param.Attacker then        
        self:UpdateTroopData(param.Attacker,1)
    else
        self:UpdateTroopData(nil,1)        
    end
    
    if param.Defender then
        self:UpdateTroopData(param.Defender,2)
    else
        self:UpdateTroopData(nil,2)
    end

end

---@param cellData KCWarDetailCellTroopData
function KCWarDetailCell:UpdateTroopData(cellData,index)
    
    self.goGroup[index]:SetVisible(cellData ~= nil) 
    if not cellData then
        return
    end

    if not self.ids[index] or self.ids[index] ~= cellData.id then
        self.ids[index] = cellData.id
        local heroCfg = ConfigRefer.Heroes:Find(cellData.heroId)
        local heroResCfg =ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
        ---@type HeroInfoData
        local heroInfoData = {}
        heroInfoData.heroData = {}
        heroInfoData.heroData.id = cellData.heroId
        heroInfoData.heroData.configCell = heroCfg
        heroInfoData.heroData.resCell = heroResCfg
        heroInfoData.heroData.lv = cellData.heroLvl
        heroInfoData.heroData.star = cellData.starLvl
        heroInfoData.hideExtraInfo = true
        self.compChildCardHero[index]:FeedData(heroInfoData)
        if cellData.portraitInfo then
            self.compPlayerInfo[index]:FeedData(cellData.portraitInfo)
        else
            self.compPlayerInfo[index]:FeedData({
                iconId = cellData.portrait,
                iconName = cellData.iconName,
            })
        end

        if ModuleRefer.PlayerModule:IsMineById(cellData.playerId) then
            self.textNamePlayer[index].enabled = false
            self.textNameOneself[index].enabled = true
            self.textNameOneself[index].text = ModuleRefer.PlayerModule.FullName(cellData.allianceAbbr,cellData.playerName)
        else
            self.textNamePlayer[index].enabled = true
            self.textNameOneself[index].enabled = false
            self.textNamePlayer[index].text =  ModuleRefer.PlayerModule.FullName(cellData.allianceAbbr,cellData.playerName)        
        end   
    end

    self.textQuantity[index].text = tostring(cellData.count)    
    local hpPct = cellData.count / cellData.maxCount
    self.sliderGroupProgress[index].value = hpPct
    ---@type CS.UnityEngine.UI.ColorBlock
    local colorBlock = self.sliderGroupProgress[index].colors
    if hpPct > 0.1 then
        colorBlock.normalColor = CS.UnityEngine.Color.white
    else
        colorBlock.normalColor = CS.UnityEngine.Color(1,0.3333333,0.3333333,1)
    end
    self.sliderGroupProgress[index].colors = colorBlock
    --tmp Dead Effect
    UIHelper.SetGray(self.compChildCardHero[index].gameObject,cellData.count < 1)
    
end




return KCWarDetailCell
