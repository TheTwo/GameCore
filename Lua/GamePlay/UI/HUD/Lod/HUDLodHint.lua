local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')

---@class HUDLodHint : BaseUIComponent
local HUDLodHint = class("HUDLodHint", BaseUIComponent)

function HUDLodHint:OnCreate(param)
    self.p_icon_self = self:Image("p_icon_self")
    self.p_icon_ally = self:Image("p_icon_ally")
    self.p_icon_enemy = self:Image("p_icon_enemy")
    self.p_text_icon_self = self:Text("p_text_icon_self", "lod_jifang")
    self.p_text_icon_ally = self:Text("p_text_icon_ally", "lod_mengyou")
    self.p_text_icon_enemy = self:Text("p_text_icon_enemy", "lod_difang")

    g_Game.SpriteManager:LoadSprite("sp_icon_slg_home_1", self.p_icon_self)
    g_Game.SpriteManager:LoadSprite("sp_icon_slg_home_3", self.p_icon_ally)
    g_Game.SpriteManager:LoadSprite("sp_icon_slg_home_2", self.p_icon_enemy)
end

function HUDLodHint:OnShow(param)
end

function HUDLodHint:OnHide(param)
end

return HUDLodHint