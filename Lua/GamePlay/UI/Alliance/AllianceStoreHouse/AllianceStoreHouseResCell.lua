local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local AllianceCurrencyType = require("AllianceCurrencyType")
local NumberFormatter = require("NumberFormatter")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceStoreHouseResCellParameter
---@field config AllianceCurrencyConfigCell

---@class AllianceStoreHouseResCell:BaseTableViewProCell
---@field new fun():AllianceStoreHouseResCell
---@field super BaseTableViewProCell
local AllianceStoreHouseResCell = class('AllianceStoreHouseResCell', BaseTableViewProCell)

function AllianceStoreHouseResCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._eventAdd = false
    ---@type AllianceStoreHouseResCellParameter
    self._parameter = nil
    ---@type number
    self._currencyId = nil
    ---@type number
    self._allianceId = nil
    self._limitAttrs = nil
    self._speedAttrs = nil
end

function AllianceStoreHouseResCell:OnCreate(param)
    self._p_text_res_name = self:Text("p_text_res_name")
    self._p_icon_res = self:Image("p_icon_res", Delegate.GetOrCreate(self, self.OnClickIcon))
    self._p_text_res_num = self:Text("p_text_res_num")
    self._p_text_res_speed = self:Text("p_text_res_speed")
end

---@param data AllianceStoreHouseResCellParameter
function AllianceStoreHouseResCell:OnFeedData(data)
    self._parameter = data
    local config = data.config
    self._currencyId = config:Id()
    self._currencyType = config:CurrencyType()
    self._p_text_res_name.text = I18N.Get(config:Name())
    local icon = config:Icon()
    if string.IsNullOrEmpty(icon) then
        icon = "sp_icon_missing"
    end
    g_Game.SpriteManager:LoadSprite(icon, self._p_icon_res)
    self._limitAttrs = nil
    self._speedAttrs = nil
    local attrs = ModuleRefer.AllianceModule:GetAllianceCurrencyAttr(self._currencyId)
    if attrs then
        if self._currencyType ~= AllianceCurrencyType.Fund and attrs.limit then
            self._limitAttrs = {attrs.limit}
        end
        if attrs.speed then
            self._speedAttrs = {attrs.speed}
        end
        
    end
    self:ReadCurrencyCount()
    self:ReadSpeedAttrValue()
    self:SetupEvent(true)
end

function AllianceStoreHouseResCell:OnRecycle()
    self:SetupEvent(false)
end

function AllianceStoreHouseResCell:OnClose(param)
    self:SetupEvent(false)
end

function AllianceStoreHouseResCell:SetupEvent(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceCurrency.Currency.MsgPath, Delegate.GetOrCreate(self, self.OnCurrencyChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTechnology.AttrDisplay.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTechnologyAttrDisplayChanged))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceCurrency.Currency.MsgPath, Delegate.GetOrCreate(self, self.OnCurrencyChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTechnology.AttrDisplay.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTechnologyAttrDisplayChanged))
    end
end

---@param entity wds.Alliance
function AllianceStoreHouseResCell:OnCurrencyChanged(entity, changedData)
    if not self._allianceId or not self._currencyId or entity.ID ~= self._allianceId or not changedData then
        return
    end
    if changedData.Add then
        if changedData.Add[self._currencyId] then
            self:ReadCurrencyCount()
            return
        end
    end
    if changedData.Remove then
        if changedData.Remove[self._currencyId] then
            self:ReadCurrencyCount()
            return
        end
    end
end

function AllianceStoreHouseResCell:ReadCurrencyCount()
    local count = NumberFormatter.NumberAbbr(ModuleRefer.AllianceModule:GetAllianceCurrencyById(self._currencyId))
    if self._currencyType == AllianceCurrencyType.Fund then
        self._p_text_res_num.text = count
    else
        local max = NumberFormatter.NumberAbbr(ModuleRefer.AllianceModule:GetAllianceCurrencyMaxCountById(self._currencyId))
        self._p_text_res_num.text = ("%s/%s"):format(count, max)
    end
end

---@param entity wds.Alliance
function AllianceStoreHouseResCell:OnAllianceTechnologyAttrDisplayChanged(entity, changeTable)
    if not self._allianceId or not self._currencyId or entity.ID ~= self._allianceId or not self._attrSet or not changeTable then
        return
    end
    local updateSpeed = false
    local updateLimit = false
    if changeTable.Add then
        if self._limitAttrs then
            for _, v in pairs(self._limitAttrs) do
                if changeTable.Add[v] then
                    updateLimit = true
                    break
                end
            end
        end
        if self._speedAttrs then
            for _, v in pairs(self._speedAttrs) do
                if changeTable.Add[v] then
                    updateSpeed = true
                    break
                end
            end
        end
    end
    if changeTable.Remove then
        if self._limitAttrs and not updateLimit then
            for _, v in pairs(self._limitAttrs) do
                if changeTable.Remove[v] then
                    updateLimit = true
                    break
                end
            end
        end
        if self._speedAttrs and not updateSpeed then
            for _, v in pairs(self._speedAttrs) do
                if changeTable.Remove[v] then
                    updateSpeed = true
                    break
                end
            end
        end
    end
    
    if updateSpeed then
        self:ReadSpeedAttrValue()
    end
    if updateLimit then
        self:ReadCurrencyCount()
    end
end

function AllianceStoreHouseResCell:ReadSpeedAttrValue()
    if not self._speedAttrs then
        self._p_text_res_speed:SetVisible(false)
        return
    end
    self._p_text_res_speed:SetVisible(true)
    local speed = ModuleRefer.AllianceModule:GetAllianceCurrencyAddSpeedById(self._currencyId)
    local ins = ModuleRefer.AllianceModule:GetAllianceCurrencyAutoAddTimeInterval(self._currencyType)
    if not ins or ins <= 0 then
        self._p_text_res_speed.text = I18N.GetWithParams("alliance_resource_xiaoshi", "0")
    else
        if self._currencyType == AllianceCurrencyType.WarCard or self._currencyType == AllianceCurrencyType.BuildCard then
            self._p_text_res_speed.text = I18N.GetWithParams("alliance_xuanzhanchanchu", NumberFormatter.NumberAbbr(math.floor(speed * (1 / ins) + 0.5)))
        else
            self._p_text_res_speed.text = I18N.GetWithParams("alliance_resource_xiaoshi", NumberFormatter.NumberAbbr(math.floor(speed * (3600 / ins))))
        end
    end
end

function AllianceStoreHouseResCell:OnClickIcon()
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.title = I18N.Get(self._parameter.config:Name())
    toastParameter.content = I18N.Get(self._parameter.config:DescTip())
    toastParameter.clickTransform = self._p_icon_res.rectTransform
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

return AllianceStoreHouseResCell