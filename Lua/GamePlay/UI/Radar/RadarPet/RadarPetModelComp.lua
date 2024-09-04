local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local HeroUIUtilities = require('HeroUIUtilities')
local ArtResourceUtils = require('ArtResourceUtils')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
---@class RadarPetModelComp : BaseTableViewProCell
---@field data HeroConfigCache
local RadarPetModelComp = class('RadarPetModelComp', BaseTableViewProCell)

function RadarPetModelComp:ctor()
end

function RadarPetModelComp:OnCreate()
    self.p_img_frame = self:Image('p_img_frame')
    self.p_img_pet = self:Image('p_img_pet')
    self.btn = self:Button('p_img_pet', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnClickDetail))
end

function RadarPetModelComp:OnFeedData(param)
    self.cfgId = param.cfgId
    self.p_img_pet:SetVisible(self.cfgId ~= nil)
    self.p_img_frame:SetVisible(self.cfgId ~= nil)
    self.p_btn_detail:SetVisible(self.cfgId ~= nil)
    if self.cfgId == nil then
        return
    end
    local petCfg = ModuleRefer.PetModule:GetPetCfg(param.cfgId)
    local sprite = ConfigRefer.Pet:Find(param.cfgId):ShowPortrait()
    local quality = petCfg:Quality()
    local frame = HeroUIUtilities.GetRadarPetTraceFrameSpriteID(quality)

    self:LoadSprite(sprite, self.p_img_pet)
    g_Game.SpriteManager:LoadSprite(frame, self.p_img_frame)

end

function RadarPetModelComp:OnBtnClick()
    if self.cfgId == nil then
        return
    end

    g_Game.EventManager:TriggerEvent(EventConst.RADAR_TRACE_PET_SWAP, self.cfgId)

end

function RadarPetModelComp:OnBtnClickDetail()
    ModuleRefer.PetModule:ShowPetPreview(self.cfgId, "sss")
end

return RadarPetModelComp
