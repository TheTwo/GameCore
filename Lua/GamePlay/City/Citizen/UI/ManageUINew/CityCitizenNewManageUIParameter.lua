---@class CityCitizenNewManageUIParameter
---@field new fun(city, workCfgId, workId, onSelect, showWorkingCitizen, showMask):CityCitizenNewManageUIParameter
local CityCitizenNewManageUIParameter = class("CityCitizenNewManageUIParameter")

---@param city MyCity
---@param onSelect fun(citizenId:number, lockable:CS.UnityEngine.RectTransform|nil):boolean 返回true时代表选择完毕，关闭管理界面
function CityCitizenNewManageUIParameter:ctor(city, workCfgId, workId, onSelect, showWorkingCitizen, showMask)
    self.city = city
    self.workCfgId = workCfgId
    self.workId = workId
    self.needShowWorkingAbout = self.workCfgId ~= nil
    self.onSelect = onSelect
    self.showWorkingCitizen = showWorkingCitizen
    self.showMask = showMask

    if self.workId then
        self.citizenWorkData = city.cityWorkManager:GetCitizenWorkData(workId)
        self.targetId, self.targetType = self.citizenWorkData:GetTarget()
    end
end

function CityCitizenNewManageUIParameter:SetWorkCfgId(workCfgId)
    self.workCfgId = workCfgId
    self.needShowWorkingAbout = self.workCfgId ~= nil
    return self
end

function CityCitizenNewManageUIParameter:SetCityAndWorkId(city, workId)
    self.city = city
    self.workId = workId
    if self.city and self.workId then
        self.citizenWorkData = self.city.cityWorkManager:GetCitizenWorkData(workId)
        self.targetId, self.targetType = self.citizenWorkData:GetTarget()
    else
        self.citizenWorkData = nil
        self.targetId = nil
        self.targetType = nil
    end
    return self
end

function CityCitizenNewManageUIParameter:SetOnSelect(onSelect)
    self.onSelect = onSelect
    return self
end

function CityCitizenNewManageUIParameter:SetShowWorkingCiziten(flag)
    self.showWorkingCitizen = flag
    return self
end

function CityCitizenNewManageUIParameter:SetShowMask(flag)
    self.showMask = flag
    return self
end

return CityCitizenNewManageUIParameter