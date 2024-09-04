local BaseUIMediator = require('BaseUIMediator')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local CommonPlayerDefine = require('CommonPlayerDefine')
local ModifyPlayerIconParameter = require('ModifyPlayerIconParameter')
local HeadChangeMediator = class('HeadChangeMediator',BaseUIMediator)

function HeadChangeMediator:OnCreate()
    self.compChildPopupBaseS = self:LuaObject('child_popup_base_s')
    self.goSelect1 = self:GameObject('p_base_select_1')
    self.textUsing1 = self:Text('p_text_using_1')
    self.compChildUiHeadPlayer1 = self:LuaObject('child_ui_head_player_1')
    self.goSelect2 = self:GameObject('p_base_select_2')
    self.textUsing2 = self:Text('p_text_using_2')
    self.compChildUiHeadPlayer2 = self:LuaObject('child_ui_head_player_2')

    self.compChildUiHeadPlayer1:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnClickPlayerHead1))
    self.compChildUiHeadPlayer2:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnClickPlayerHead2))
end

function HeadChangeMediator:OnOpened()
    self.compChildPopupBaseS:FeedData({title = I18N.Get("avatar_modifyprofile")})
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local isBoy = player.Basics.PortraitInfo.PlayerPortrait == CommonPlayerDefine.HEAD_TYPES.BOY
    self.goSelect1:SetActive(isBoy)
    self.goSelect2:SetActive(not isBoy)
    self:RefreshText(isBoy)
    self.compChildUiHeadPlayer1:FeedData({iconId = 1})
    self.compChildUiHeadPlayer2:FeedData({iconId = 2})
end

function HeadChangeMediator:OnShow()

end

function HeadChangeMediator:OnClose(param)

end

function HeadChangeMediator:RefreshText(isBoy)
    if isBoy then
        self.textUsing1.text = I18N.Get("avatar_using")
        self.textUsing2.text = I18N.Get("avatar_profile_b")
    else
        self.textUsing1.text = I18N.Get("avatar_profile_a")
        self.textUsing2.text = I18N.Get("avatar_using")
    end
end

function HeadChangeMediator:OnClickPlayerHead1()
    self.goSelect1:SetActive(true)
    self.goSelect2:SetActive(false)
    self:RefreshText(true)
    local param = ModifyPlayerIconParameter.new()
    param.args.IconId = CommonPlayerDefine.HEAD_TYPES.BOY
    param:Send()
end

function HeadChangeMediator:OnClickPlayerHead2()
    self.goSelect1:SetActive(false)
    self.goSelect2:SetActive(true)
    self:RefreshText(false)
    local param = ModifyPlayerIconParameter.new()
    param.args.IconId = CommonPlayerDefine.HEAD_TYPES.GIRL
    param:Send()
end

return HeadChangeMediator
