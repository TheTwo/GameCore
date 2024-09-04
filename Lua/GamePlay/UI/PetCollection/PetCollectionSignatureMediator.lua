local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local TimeFormatter = require("TimeFormatter")
local TimerUtility = require('TimerUtility')

local PetCollectionSignatureMediator = class('PetCollectionSignatureMediator', BaseUIMediator)
function PetCollectionSignatureMediator:ctor()

end

function PetCollectionSignatureMediator:OnCreate()
    self.p_icon_pet = self:Image('p_icon_pet')
    self.p_text_num = self:Text('p_text_num')
    self.p_tag_special = self:GameObject('p_tag_special')
    self.p_text_player_name = self:Text('p_text_player_name')
    self.p_text_date = self:Text('p_text_date')
    self.vfx_pet_book_sign = self:GameObject('vfx_pet_book_sign')
end

function PetCollectionSignatureMediator:OnShow(param)
    local icon = ConfigRefer.ArtResourceUI:Find(param:ShowPortrait()):Path()
    g_Game.SpriteManager:LoadSprite(icon, self.p_icon_pet)

    self.p_text_num.text = "NO." .. param:Id()
    self.p_tag_special:SetVisible(false or param:IsVip())
    self.p_text_player_name.text = ModuleRefer.PlayerModule:GetPlayer().Basics.Name
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.p_text_date.text = TimeFormatter.TimeToDateTimeStringUseFormat(curTime, "yyyy/MM/dd HH:mm:ss")

    TimerUtility.DelayExecute(function()
        g_Game.UIManager:CloseByName("PetCollectionSignatureMediator")
    end, 3)
end

function PetCollectionSignatureMediator:OnHide(param)

end

return PetCollectionSignatureMediator
