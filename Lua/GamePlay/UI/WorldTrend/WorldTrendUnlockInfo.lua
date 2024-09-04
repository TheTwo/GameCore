local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local GuideUtils = require("GuideUtils")


---@class WorldTrendUnlockInfo : BaseUIComponent
local WorldTrendUnlockInfo = class('WorldTrendUnlockInfo', BaseUIComponent)
---@class WorldTrendUnlockParam
---@field stageID number


function WorldTrendUnlockInfo:ctor()

end

function WorldTrendUnlockInfo:OnCreate()
    self.goLockCondition1 = self:GameObject('p_unlock_01')
    -- self.textLockCondition1 = self:Text('p_text_unlock_01')
    self.imgLockConditionIcon1 = self:Image('p_icon_01')
    self.btnLockDetail1 = self:Button('p_btn_unlock_detail_01', Delegate.GetOrCreate(self, self.OnClickLockDetail1))
    self.goLockCondition2 = self:GameObject('p_unlock_02')
    -- self.textLockCondition2 = self:Text('p_text_unlock_02')
    self.imgLockConditionIcon2 = self:Image('p_icon_02')
    self.btnLockDetail2 = self:Button('p_btn_unlock_detail_02', Delegate.GetOrCreate(self, self.OnClickLockDetail2))

    self.txtUnlock = self:Text('p_text_unlock_subtitle', I18N.Get("WorldStage_unlockSystem_title"))
end

---@param param WorldTrendUnlockParam
function WorldTrendUnlockInfo:OnFeedData(param)
    if not param then
        return
    end
    self.stageID = param.stageID
    self:ShowUnlockCondition()
end

function WorldTrendUnlockInfo:ShowUnlockCondition()
    local config = ConfigRefer.WorldStage:Find(self.stageID)
    if not config then
        self.txtUnlock:SetVisible(false)
        return
    end
    if config:UnlockSystemsLength() > 0 then
        local systemEntryConfig_1 = ConfigRefer.SystemEntry:Find(config:UnlockSystems(1))
        if systemEntryConfig_1 then
            self.goLockCondition1:SetActive(true)
            local spriteName = systemEntryConfig_1:Icon()
            if not string.IsNullOrEmpty(spriteName) then
                g_Game.SpriteManager:LoadSprite(spriteName, self.imgLockConditionIcon1)
            end
        end
        self.txtUnlock:SetVisible(true)
    else
        self.goLockCondition1:SetActive(false)
        self.txtUnlock:SetVisible(false)
    end

    if config:UnlockSystemsLength() > 1 then
        local systemEntryConfig_2 = ConfigRefer.SystemEntry:Find(config:UnlockSystems(2))
        if systemEntryConfig_2 then
            self.goLockCondition2:SetActive(true)
            local spriteName = systemEntryConfig_2:Icon()
            if not string.IsNullOrEmpty(spriteName) then
                g_Game.SpriteManager:LoadSprite(spriteName, self.imgLockConditionIcon2)
            end
        end
    else
        self.goLockCondition2:SetActive(false)
    end
end

function WorldTrendUnlockInfo:OnClickLockDetail1()
    local config = ConfigRefer.WorldStage:Find(self.stageID)
    if not config then
        return
    end
    if config:UnlockSystemTipsLength() > 0 and not string.IsNullOrEmpty(config:UnlockSystemTips(1)) then
        ---@type TextToastMediatorParameter
        local param = {}
        param.clickTransform = self.btnLockDetail1:GetComponent(typeof(CS.UnityEngine.RectTransform))
        param.content = I18N.Get(config:UnlockSystemTips(1))
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
end

function WorldTrendUnlockInfo:OnClickLockDetail2()
    local config = ConfigRefer.WorldStage:Find(self.stageID)
    if not config then
        return
    end
    if config:UnlockSystemTipsLength() > 1 and not string.IsNullOrEmpty(config:UnlockSystemTips(2)) then
        ---@type TextToastMediatorParameter
        local param = {}
        param.clickTransform = self.btnLockDetail2:GetComponent(typeof(CS.UnityEngine.RectTransform))
        param.content = I18N.Get(config:UnlockSystemTips(2))
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
end

return WorldTrendUnlockInfo
