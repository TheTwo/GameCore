local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local GuideUtils = require('GuideUtils')
local PetCollectionAreaComp = class('PetCollectionAreaComp', BaseTableViewProCell)
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local ConfigRefer = require("ConfigRefer")
local EarthRevivalDefine = require('EarthRevivalDefine')

function PetCollectionAreaComp:OnCreate()
    self._p_status = self:StatusRecordParent("")

    -- Open
    self.openIcon = self:Image('p_icon_type')
    self.openText = self:Text('p_text_open')
    self.openGoto = self:Button('p_icon_goto', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.openProgress = self:Slider('p_progress')

    -- -- Close
    self.closeIcon = self:Image('base')
    self.closeText = self:Text('p_text_unopen')
    self.p_text_name = self:Text('p_text_name')

    self.child_reddot_default = self:GameObject('child_reddot_default')
end

function PetCollectionAreaComp:OnShow()
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))

end

function PetCollectionAreaComp:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.PET_COLLECTION_STORY_RED_POINT, Delegate.GetOrCreate(self, self.RefreshRedPoint))
end

function PetCollectionAreaComp:OnFeedData(param)
    self.areaIndex = param.areaIndex
    self.unlock = param.unlock

    local sprite = ConfigRefer.ArtResourceUI:Find(param:BackgroundPic()):Path()
    local areaName = I18N.Get(param:Name())

    if (param.passSys and param.passWorldStage) then
        self._p_status:SetState(0)
        self.p_text_name.text = areaName
        self.openText.text = param.curProgress .. "/" .. param.maxProgress
        self.openProgress.value = param.curProgress / param.maxProgress
        self.gotoStatus = 1

        g_Game.SpriteManager:LoadSprite(sprite, self.openIcon)
    elseif param.passSys then
        self._p_status:SetState(1)
        self.closeText.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookAreaLockedDesc())
        self.p_text_name.text = "???"
        self.gotoStatus = 2

        g_Game.SpriteManager:LoadSprite(sprite, self.closeIcon)
    else
        self._p_status:SetState(1)
        self.closeText.text = I18N.Get(ConfigRefer.PetConsts:PetHandbookAreaUnexploredDesc())
        self.p_text_name.text = "???"
        self.child_reddot_default:SetVisible(false)
        self.gotoStatus = 3

        g_Game.SpriteManager:LoadSprite(sprite, self.closeIcon)
    end

    self:RefreshRedPoint()
end

function PetCollectionAreaComp:OnClickGoto()
    if self.gotoStatus == 1 then
        g_Game.UIManager:Open(UIMediatorNames.PetCollectionPhotoMediator, {areaIndex = self.areaIndex, curIndex = self.areaIndex})
    elseif self.gotoStatus == 2 then
        -- 跳转天下大势系统
        ---@type CommonConfirmPopupMediatorParameter
        local param = {}
        param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        param.title = I18N.Get("equip_warning")
        param.content = I18N.Get("pet_handbook_world_trend_cond_des")
        param.onConfirm = function()
            g_Game.UIManager:Open(UIMediatorNames.WorldTrendTimeLineMediator)
            g_Game.UIManager:CloseByName(UIMediatorNames.CommonConfirmPopupMediator)
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)

    else
        ---@type CommonConfirmPopupMediatorParameter
        local param = {}
        param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        param.title = I18N.Get("equip_warning")
        param.content = I18N.Get("pet_handbook_map_cond_des")
        param.onConfirm = function()
            GuideUtils.GotoByGuide(5033, true)
            g_Game.UIManager:CloseByName(UIMediatorNames.CommonConfirmPopupMediator)
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
        -- 跳转距离玩家最近区域
    end
end

function PetCollectionAreaComp:RefreshRedPoint()
    if self.gotoStatus ~= 1 then
        self.child_reddot_default:SetVisible(false)
        return
    end

end

return PetCollectionAreaComp
