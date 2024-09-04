local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local CityCitizenManageV3Helper = require('CityCitizenManageV3Helper')
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CastleAssignHouseParameter = require("CastleAssignHouseParameter")
local CityLegoBuildingUIBuffData = require("CityLegoBuildingUIBuffData")
local CastleAddBuildingCitizensParameter = require("CastleAddBuildingCitizensParameter")
local CityLegoBuffSelectUIParameter = require("CityLegoBuffSelectUIParameter")
local UIMediatorNames = require("UIMediatorNames")

local I18N = require("I18N")
local CityLegoI18N = require("CityLegoI18N")
local EventConst = require("EventConst")

---@class CityLegoBuildingUIPage_Room:BaseUIComponent
local CityLegoBuildingUIPage_Room = class('CityLegoBuildingUIPage_Room', BaseUIComponent)

function CityLegoBuildingUIPage_Room:OnCreate()
    self._content = self:Transform("content")
end

---@param legoBuilding CityLegoBuilding
function CityLegoBuildingUIPage_Room:OnFeedData(legoBuilding)
    if legoBuilding and legoBuilding.is then
        local CityLegoBuilding = require("CityLegoBuilding")
        if not legoBuilding:is(CityLegoBuilding) then
            g_Logger.ErrorChannel("CityLegoBuildingUIPage_Room", "传了个预期之外的参数过来")
            g_Logger.ErrorChannel("CityLegoBuildingUIPage_Room", FormatTable(legoBuilding))
            return
        end
    end

    self.legoBuilding = legoBuilding
    self.city = self.legoBuilding.city

    for i = 0, self._p_table_citizen.cellPrefab.Length - 1 do
        local go = self._p_table_citizen.cellPrefab[i]
        go:SetActive(false)
    end

    self._p_text_room_name.text = I18N.Get(self.legoBuilding:GetNameI18N())
    self._p_text_description.text = I18N.Get(self.legoBuilding:GetDescriptionI18N())

    if self.legoBuilding:ShowScore() then
        self._p_score:SetActive(true)
        self._p_progress_score_room.value = self.legoBuilding:GetScoreProgress()
        self._p_text_progress.text = self.legoBuilding:GetScoreText()
        self._p_text_score.text = tostring(self.legoBuilding:GetRoomLevel())
    else
        self._p_score:SetActive(false)
    end

    

    self:UpdateCitizenTableView()
    ModuleRefer.NotificationModule:AttachToGameObject(self.legoBuilding.dynamicNode, self._p_new_set)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._content)
end

function CityLegoBuildingUIPage_Room:OnClickQuicklyFillUpCitizen()
    local emptySlot = self.legoBuilding:GetMaxCitizenCount() - self.legoBuilding.payload.InnerHeroIds:Count()
    if emptySlot == 0 then
        return
    end

    local freeCitizenCont = self.city.cityCitizenManager:GetFreeCitizenCount()
    if freeCitizenCont == 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("citizen_toast_nofree"))
        return
    end

    local citizenMgr = self.city.cityCitizenManager
    local homelessCitizen = {}
    for id, citizenData in pairs(citizenMgr._citizenData) do
        if citizenData._houseId == 0 then
            table.insert(homelessCitizen, id)
        end

        if #homelessCitizen >= emptySlot then
            break
        end
    end

    local param = CastleAddBuildingCitizensParameter.new()
    param.args.Bid = self.legoBuilding.id
    param.args.CitizenIds:AddRange(homelessCitizen)
    param:SendOnceCallback(self._p_btn_max.transform, nil, true, Delegate.GetOrCreate(self, self.UpdateCitizenTableView))
end

function CityLegoBuildingUIPage_Room:OnClickAddCitizen()
    CityCitizenManageV3Helper.ShowUI_Homeless(self.city, Delegate.GetOrCreate(self, self.OnCitizenSelect))
end

---@param citizenData CityCitizenData
function CityLegoBuildingUIPage_Room:OnClickRemoveCitizen(citizenData)
    if citizenData._houseId ~= self.legoBuilding.id then return end

    local param = CastleAssignHouseParameter.new()
    param.args.HouseId = 0
    param.args.CitizenId = citizenData._id
    param:SendWithFullScreenLockAndOnceCallback(nil, true, Delegate.GetOrCreate(self, self.UpdateCitizenTableView))
end

function CityLegoBuildingUIPage_Room:OnCitizenSelect(citizenData)
    local maxCitizenCount = self.legoBuilding:GetMaxCitizenCount()
    local currentCount = self.legoBuilding.payload.InnerHeroIds:Count()
    if citizenData._houseId == 0 then
        local param = CastleAssignHouseParameter.new()
        param.args.HouseId = self.legoBuilding.id
        param.args.CitizenId = citizenData._id
        param:SendWithFullScreenLockAndOnceCallback(nil, true, function(cmd, isSuccess, reply)
            if not isSuccess then return end
            self:UpdateCitizenTableView()
            g_Game.EventManager:TriggerEvent(EventConst.UI_CITIZEN_MANAGE_V3_REFRESH)
        end)
        return maxCitizenCount - currentCount <= 1
    end
    return false
end

function CityLegoBuildingUIPage_Room:UpdateCitizenTableView()
    local citizenCount = self.legoBuilding.payload.InnerHeroIds:Count()
    local maxCitizenCount = self.legoBuilding:GetMaxCitizenCount()
    self._p_text_citizen_quantity.text = string.format("%d/%d", citizenCount, maxCitizenCount)
    self._p_table_citizen:Clear()
    local innerCount = self.legoBuilding.payload.InnerHeroIds:Count()
    for i, v in ipairs(self.legoBuilding.payload.InnerHeroIds) do
        local citizenData = self.city.cityCitizenManager:GetCitizenDataById(v)
        self._p_table_citizen:AppendData({citizenData = citizenData, isEmpty = false, onRemove = Delegate.GetOrCreate(self, self.OnClickRemoveCitizen)})
    end
    for i = 1, maxCitizenCount - innerCount do
        self._p_table_citizen:AppendData({isEmpty = true, onAdd = Delegate.GetOrCreate(self, self.OnClickAddCitizen)})
    end
end



return CityLegoBuildingUIPage_Room