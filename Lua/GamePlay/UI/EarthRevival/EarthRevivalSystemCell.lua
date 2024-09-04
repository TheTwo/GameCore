local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class EarthRevivalSystemCell : BaseTableViewProCell
local EarthRevivalSystemCell = class('EarthRevivalSystemCell', BaseTableViewProCell)

function EarthRevivalSystemCell:OnCreate()
    self.btnSystem = self:Button('', Delegate.GetOrCreate(self, self.OnClickSystem))
    self.imgSystem = self:Image('p_icon_system')
end

function EarthRevivalSystemCell:OnFeedData(systemid)
    self.id = systemid
    self.configInfo = ConfigRefer.SystemEntry:Find(systemid)
    if not self.configInfo then
        return 
    end
    if not string.IsNullOrEmpty(self.configInfo:Icon()) then
        g_Game.SpriteManager:LoadSprite(self.configInfo:Icon(), self.imgSystem)
    end
end

function EarthRevivalSystemCell:OnClickSystem()
    if not self.configInfo then
        self.configInfo = ConfigRefer.SystemEntry:Find(self.id)
    end
    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnSystem:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = I18N.Get(self.configInfo:SystemTips())
    ModuleRefer.ToastModule:ShowTextToast(param)
end

return EarthRevivalSystemCell