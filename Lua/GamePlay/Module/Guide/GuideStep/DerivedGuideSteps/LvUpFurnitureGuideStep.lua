local BaseGuideStep = require("BaseGuideStep")
---@class LvUpFurnitureGuideStep : BaseGuideStep
local LvUpFurnitureGuideStep = class("LvUpFurnitureGuideStep", BaseGuideStep)

function LvUpFurnitureGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_LvUpFurniture: %d)', self.cfg:Id())
    if self.cfg:StringParamsLength() ~= 1 then
        g_Logger.Error('GuideModule','ExeGuideStep_LvUpFurniture 参数 StringParams长度不是1')
        self:Stop()
        return
    end

    local strParam = self.cfg:StringParams(1)
    local typCfgId = (not string.IsNullOrEmpty(strParam)) and tonumber(strParam) or 0
    if typCfgId == 0 then
        g_Logger.Error('GuideModule','ExeGuideStep_LvUpFurniture 参数 StringParams1:%s 不是一个id', strParam)
        self:Stop()
        return
    end

    local city = self:FindMyCity()
    local furnitures = city.furnitureManager:GetFurnituresByTypeCfgId(typCfgId, true)
    if #furnitures == 0 then
        g_Logger.Error('GuideModule','ExeGuideStep_LvUpFurniture typCfgId:%s 没有对应的家具', typCfgId)
        self:Stop()
        return
    end

    local furniture = furnitures[1]
    if not furniture:TryOpenLvUpUI() then
        g_Logger.Error('GuideModule','ExeGuideStep_LvUpFurniture typCfgId:%s 家具升级界面打开失败', typCfgId)
        self:Stop()
        return
    end
    self:End()
end

return LvUpFurnitureGuideStep