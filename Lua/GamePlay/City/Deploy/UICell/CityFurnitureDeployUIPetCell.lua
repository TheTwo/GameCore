local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityFurnitureDeployI18N = require("CityFurnitureDeployI18N")

---@class CityFurnitureDeployUIPetCell:BaseTableViewProCell @城市家具驻派界面宠物单元
local CityFurnitureDeployUIPetCell = class('CityFurnitureDeployUIPetCell', BaseTableViewProCell)

function CityFurnitureDeployUIPetCell:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    self._p_btn_pet = self:Button("p_btn_pet", Delegate.GetOrCreate(self, self.OnClick))

    ---已驻派节点
    self._status_accredit = self:GameObject("status_accredit")
    self._p_text_pet_name = self:Text("p_text_pet_name")
    self._p_text_time = self:Text("p_text_time")
    ---@type CommonPetIconSmall
    self._p_pet = self:LuaObject("p_pet")
    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickDelete))
    self._p_btn_hint = self:GameObject("p_btn_hint")
    self._p_text_baseline_pet = self:Text("p_text_baseline_pet", "pet_sync_name")

    ---未驻派节点
    self._icon_add = self:GameObject("icon_add")
    self._p_text_empty = self:Text("p_text_empty", CityFurnitureDeployI18N.UIHint_ClickToDeploy)
    self._p_text_time_empty = self:Text("p_text_time_empty")

    ---未解锁节点
    self._status_lock = self:GameObject("status_lock")
    self._p_text_lock = self:Text("p_text_lock")
    self._p_text_time_lock = self:Text("p_text_time_lock")
end

---@param data CityFurnitureDeployPetCellData
function CityFurnitureDeployUIPetCell:OnFeedData(data)
    self.data = data

    local status = data:GetStatus()
    self._statusRecord:ApplyStatusRecord(status)

    if status == 0 then
        local isShow = data:IsShowLockCondition()
        self._p_text_lock:SetVisible(isShow)
        if isShow then
            self._p_text_lock.text = data:GetLockConditionStr()
        end

        isShow = data:IsShowLockTime()
        self._p_text_time_lock:SetVisible(isShow)
        if isShow then
            self._p_text_time_lock.text = data:GetLockTimeStr()
        end
    elseif status == 1 then
        local isShow = data:IsShowNonDeployTime()
        self._p_text_time_empty:SetVisible(isShow)
        if isShow then
            self._p_text_time_empty.text = data:GetNonDeployTimeStr()
        end
    elseif status == 2 then
        self._p_text_pet_name.text = data:GetPetName()
        self._p_text_time.text = data:GetDeployTimeStr()
        self._p_pet:FeedData(data:GetPetData())
        self._p_btn_delete:SetVisible(data:ShowDeleteButton())
        self._p_btn_hint:SetActive(data:IsLandNotFit())
        self._p_text_baseline_pet:SetVisible(data:IsShowShare())
    end
end

function CityFurnitureDeployUIPetCell:OnClick()
    if self.data:OnClick(self) then
        self:OnFeedData(self.data)
    end
end

function CityFurnitureDeployUIPetCell:OnClickDelete()
    if self.data:OnClickDelete(self) then
        self:OnFeedData(self.data)
    end
end

return CityFurnitureDeployUIPetCell