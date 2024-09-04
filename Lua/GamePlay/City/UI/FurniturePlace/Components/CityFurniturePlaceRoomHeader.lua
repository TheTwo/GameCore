local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityFurniturePlaceRoomHeader:BaseUIComponent
local CityFurniturePlaceRoomHeader = class('CityFurniturePlaceRoomHeader', BaseUIComponent)

function CityFurniturePlaceRoomHeader:OnCreate()
    --- 名字预览
    self._p_text_name_old = self:Text("p_text_name_old")
    self._p_icon_arrow = self:GameObject("p_icon_arrow")
    self._p_text_name_new = self:Text("p_text_name_new")

    --- 评分根节点，空房间不显示
    self._p_score_root = self:GameObject("p_score_root")

    --- 房间Buff等级
    self._p_text_lv_score = self:Text("p_text_lv_score")

    --- 房间得分进度条
    self._p_progress_score = self:Slider("p_progress_score")
    --- 当前操作节点的进度预览
    self._p_progress_add = self:Image("p_progress_add")

    --- 房间得分文本
    self._p_text_score = self:Text("p_text_score")
end

---@param legoBuilding CityLegoBuilding
function CityFurniturePlaceRoomHeader:ShowBuildingNormal(legoBuilding)
    self._p_text_name_old.text = I18N.Get(legoBuilding:GetNameI18N())
    self._p_icon_arrow:SetActive(false)
    self._p_text_name_new:SetVisible(false)

    if legoBuilding:ShowScore() then
        self._p_score_root:SetActive(true)
        self._p_text_lv_score.text = tostring(legoBuilding.roomLevel)
        self._p_progress_score.value = legoBuilding:GetScoreProgress()

        self._p_progress_add:SetVisible(false)
        self._p_text_score.text = legoBuilding:GetScoreText(true)
    else
        self._p_score_root:SetActive(false)
    end
end

function CityFurniturePlaceRoomHeader:UpdateName(legoBuilding)
    self._p_text_name_old.text = I18N.Get(legoBuilding:GetNameI18N())
end

---@param legoBuilding CityLegoBuilding
---@param furLvCfg CityFurnitureLevelConfigCell
---显示添加一个家具进入房间的情况
function CityFurniturePlaceRoomHeader:ShowBuildingPlusFurniture(legoBuilding, furLvCfg)
    if not legoBuilding:ShowScore() then return end

    self._p_text_name_old.text = I18N.Get(legoBuilding:GetNameI18N())
    
    local oldRoomCfgId = legoBuilding.roomCfgId
    local newRoomCfgId = legoBuilding.roomCfgId
    --- 如果放入的是主家具，且原房间中没有主家具，则需要考虑刷新成新的房间来判断Buff
    if legoBuilding.payload.MainFurnitureId == 0 then
        if ModuleRefer.CityLegoBuffModule:IsMainFurnitureOfSize(furLvCfg:Type(), legoBuilding:GetRoomSizeEnum()) then
            newRoomCfgId = ModuleRefer.CityLegoBuffModule:GetMainFurnitureToRoomCfgId(furLvCfg:Type(), legoBuilding:GetRoomSizeEnum())
        end
    end
    local oldBuffCfgIdForName = legoBuilding.payload.BuffList[1] or 0
    local newBuffList, targetLvCfg = ModuleRefer.CityLegoBuffModule:GetNewBuffCfgListByAddFurniture(legoBuilding, furLvCfg)
    local newBuffCfgIdForName = newBuffList[1] and newBuffList[1]:Id() or 0
    
    local changeBuff = oldBuffCfgIdForName ~= newBuffCfgIdForName
    local changeRoom = oldRoomCfgId ~= newRoomCfgId

    self._p_icon_arrow:SetActive(changeBuff or changeRoom)
    self._p_text_name_new:SetVisible(changeBuff or changeRoom)
    local newRoomCfg = ConfigRefer.Room:Find(newRoomCfgId)
    if changeBuff then
        self._p_text_name_new.text = I18N.Get(newBuffList[1]:BuffName())
    elseif changeRoom then
        self._p_text_name_new.text = I18N.Get(newRoomCfg:Name())
    end

    if changeBuff or changeRoom then
        self:GetParentBaseUIMediator():PlayNameWillChangeVX()
    end

    ---@type RoomLevelInfoConfigCell
    local currentLvCfg = nil
    local currentScore = legoBuilding.payload.Score
    for i = 1, newRoomCfg:LevelInfosLength() do
        local lvCfgId = newRoomCfg:LevelInfos(i)
        if lvCfgId == 0 then goto continue end

        local lvCfg = ConfigRefer.RoomLevelInfo:Find(lvCfgId)
        if currentLvCfg == nil and lvCfg:Score() <= currentScore then
            currentLvCfg = lvCfg
        elseif currentLvCfg:Level() < lvCfg:Level() and lvCfg:Score() <= currentScore then
            currentLvCfg = lvCfg
        end
        ::continue::
    end

    self._p_text_lv_score.text = tostring(targetLvCfg:Level())
    if currentLvCfg:Level() == targetLvCfg:Level() then
        local nextLvCfg = legoBuilding.manager:GetRoomLevelCfg(newRoomCfgId, currentLvCfg:Level() + 1)
        if nextLvCfg ~= nil then
            targetLvCfg = nextLvCfg
            local total = targetLvCfg:Score() - currentLvCfg:Score()
            local current = currentScore - currentLvCfg:Score()
            local target = currentScore + furLvCfg:AddScore() - currentLvCfg:Score()

            self._p_progress_score.value = math.clamp01(current / total)
            self._p_progress_add:SetVisible(true)
            self._p_progress_add.fillAmount = math.clamp01(target / total)
        else
            self._p_progress_score.value = legoBuilding:GetScoreProgress()
            self._p_progress_add:SetVisible(true)
            self._p_progress_add.fillAmount = 1
        end
    else
        local nextLvCfg = legoBuilding.manager:GetRoomLevelCfg(newRoomCfgId, targetLvCfg:Level() + 1)
        if nextLvCfg ~= nil then
            local total = nextLvCfg:Score() - targetLvCfg:Score()
            local target = currentScore + furLvCfg:AddScore() - targetLvCfg:Score()
            targetLvCfg = nextLvCfg
            self._p_progress_score.value = 0
            self._p_progress_add:SetVisible(true)
            self._p_progress_add.fillAmount = math.clamp01(target / total)
        else
            self._p_progress_score.value = legoBuilding:GetScoreProgress()
            self._p_progress_add:SetVisible(true)
            self._p_progress_add.fillAmount = 1
        end
        self:GetParentBaseUIMediator():PlayWillLevelUpVX()
    end

    self._p_text_score.text = string.format("%d/%d", legoBuilding.payload.Score + furLvCfg:AddScore(), targetLvCfg:Score())
    return changeBuff
end

return CityFurniturePlaceRoomHeader