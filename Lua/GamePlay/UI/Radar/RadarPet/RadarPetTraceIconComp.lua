local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ManualUIConst = require('ManualUIConst')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local ConfigRefer = require('ConfigRefer')
local HeroUIUtilities = require('HeroUIUtilities')
local ArtResourceUtils = require('ArtResourceUtils')
local UIHelper = require('UIHelper')
local UIMediatorNames = require('UIMediatorNames')

---@class RadarPetTraceIconComp : BaseTableViewProCell
---@field data HeroConfigCache
local RadarPetTraceIconComp = class('RadarPetTraceIconComp', BaseTableViewProCell)

function RadarPetTraceIconComp:ctor()
end

function RadarPetTraceIconComp:OnCreate()
    self.p_img_empty = self:Image('p_img_empty')
    self.p_base_frame_pet = self:Image('p_base_frame_pet')
    self.p_img_pet = self:Image('p_img_pet')
    self.mask = self:GameObject('mask')
    self.btn = self:Button('p_img_pet', Delegate.GetOrCreate(self, self.OnBtnClick))
end

function RadarPetTraceIconComp:OnFeedData(param)
    self.cfgId = param.cfgId
    if self.cfgId == nil then
        self.mask:SetVisible(false)
        self.p_base_frame_pet:SetVisible(false)
        self.p_img_empty:SetVisible(true)
        g_Game.SpriteManager:LoadSprite("sp_common_icon_details_03", self.p_img_empty)
        return
    end
    self.mask:SetVisible(true)
    self.p_base_frame_pet:SetVisible(true)
    self.p_img_empty:SetVisible(false)

    local cfg = ConfigRefer.Pet:Find(param.cfgId)
    local sprite = cfg:Icon()
    self:LoadSprite(sprite, self.p_img_pet)
    local quality = cfg:Quality()
    local color = HeroUIUtilities.GetQualityColor(quality)
    self.p_base_frame_pet.color = UIHelper.TryParseHtmlString(color)
end

function RadarPetTraceIconComp:OnBtnClick()
    g_Game.UIManager:Open(UIMediatorNames.RadarPetTraceMediator)
end

return RadarPetTraceIconComp
