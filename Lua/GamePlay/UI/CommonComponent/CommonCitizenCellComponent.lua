-- scene:scene_child_item_resident

local Delegate = require('Delegate')
local I18N = require('I18N')
local ArtResourceUtils = require("ArtResourceUtils")
local CityCitizenDefine = require("CityCitizenDefine")
local UIHelper = require("UIHelper")
local TimeFormatter = require("TimeFormatter")
local ArtResourceUIConsts = require("ArtResourceUIConsts")

local BaseUIComponent = require ('BaseUIComponent')

---@class CommonCitizenCellComponentParameter
---@field citizenData CityCitizenData
---@field citizenWork CityCitizenWorkData
---@field workCfgId number
---@field onClickSelf fun()
---@field onClickRecall fun()
---@field onClickRecover fun()
---@field allowShowBuffDetail boolean

---@class CommonCitizenCellComponent:BaseUIComponent
---@field super BaseUIComponent
local CommonCitizenCellComponent = class('CommonCitizenCellComponent', BaseUIComponent)

function CommonCitizenCellComponent:ctor()
    ---@type CommonCitizenCellComponentParameter
    self._cellParameter= nil
    self._allowShowReCall = false
    self._allowShowBuffDetail = false
    self._buffCellsReady = false
    self._needTick = false
    self._tickFainting = false
    self._needTickInInfection = false
end

function CommonCitizenCellComponent:OnCreate()
    self.goGroupSelect = self:GameObject('p_group_select')
    self.btnBack = self:Button('p_btn_back', Delegate.GetOrCreate(self, self.OnBtnBackClicked))
    self.textBack = self:Text('p_text_back', 'citizen_btn_recall')
    self.tableviewproTableDetail = self:TableViewPro('p_table_detail')
    self.imgBase = self:Image('p_base')
    self.goBaseRecover = self:GameObject('p_base_recover')
    self.goStatusA = self:GameObject('p_status_a')
    self.imgImgResidentA = self:Image('p_img_resident_a')
    self.goStatusB = self:GameObject('p_status_b')
    self.imgImgResidentB = self:Image('p_img_resident_b')
    self.sliderProgressTimeHealthB = self:Slider('p_progress_time_health_b')
    self.sliderProgressTimeInfectionB = self:Slider('p_progress_time_infection_b')
    self.goStatusC = self:GameObject('p_status_c')
    self.goRecover = self:GameObject('p_recover')
    self.imgImgResidentC = self:Image('p_img_resident_c')
    self.btnRecover = self:Button('p_btn_recover', Delegate.GetOrCreate(self, self.OnBtnRecoverClicked))
    self.textTime = self:Text('p_text_time')
    self.textStatus = self:Text('p_text_status', I18N.Temp().text_citizen_recovering)
    self.sliderProgress = self:Slider('p_progress')
    self.imgIconRefugee = self:Image('p_icon_refugee')
    self.textNameResident = self:Text('p_text_name_resident')
    self.btnBtn = self:Button('p_btn', Delegate.GetOrCreate(self, self.OnBtnSelfClicked))
    self.goGroupSelect:SetVisible(false)
end

function CommonCitizenCellComponent:OnShow(param)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
end

function CommonCitizenCellComponent:OnHide(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSecond))
end

---@param param CommonCitizenCellComponentParameter
function CommonCitizenCellComponent:OnFeedData(param) 
    self._cellParameter = param
    local HealthStatusEnum = CityCitizenDefine.HealthStatus
    self.btnBack:SetVisible(false)
    self.btnBtn:SetVisible(true)
    self._allowShowReCall = param.onClickRecall and true or false
    self._allowShowBuffDetail = param.allowShowBuffDetail and true or false
    self._tickFainting = false
    self._needTickInInfection = false
    local config = param.citizenData._config
    self.textNameResident.text = I18N.Get(config:Name())
    local isAssigned = param.citizenData:IsAssignedHouse()
    self.imgIconRefugee:SetVisible(not isAssigned)
    local healthStatus = param.citizenData:GetHealthStatusLocal()
    if healthStatus == HealthStatusEnum.Fainting then
        self.goStatusA:SetVisible(false)
        self.goStatusB:SetVisible(false)
        self.goStatusC:SetVisible(true)
        self.textTime:SetVisible(true)
        self.textStatus:SetVisible(true)
        self._tickFainting = true
        self._needTick = true
        UIHelper.SetGray(self.imgImgResidentC.gameObject, true)
        g_Game.SpriteManager:LoadSprite(config:SubIcon(), self.imgImgResidentC)
    elseif healthStatus == HealthStatusEnum.FaintingReadyWakeUp then
        self.btnBtn:SetVisible(false)
        self.goStatusA:SetVisible(false)
        self.goStatusB:SetVisible(false)
        self.goStatusC:SetVisible(true)
        self.textTime:SetVisible(false)
        self.textStatus:SetVisible(false)
        UIHelper.SetGray(self.imgImgResidentC.gameObject, true)
        g_Game.SpriteManager:LoadSprite(config:SubIcon(), self.imgImgResidentC)
    elseif param.citizenWork then
        self._needTick = true
        self.goStatusA:SetVisible(false)
        self.goStatusB:SetVisible(true)
        self.goStatusC:SetVisible(false)
        self.textTime:SetVisible(true)
        self.textStatus:SetVisible(false)
        self.sliderProgressTimeHealthB:SetVisible(healthStatus == HealthStatusEnum.Health)
        self.sliderProgressTimeInfectionB:SetVisible(healthStatus ~= HealthStatusEnum.Health)
        self.sliderProgressTimeHealthB.value = 0
        self.sliderProgressTimeInfectionB.value = 0
        g_Game.SpriteManager:LoadSprite(config:SubIcon(), self.imgImgResidentB)
        self._needTickInInfection = param.citizenData:IsWorkingWithInfection()
    else
        self._needTick = false
        self.goStatusA:SetVisible(true)
        self.goStatusB:SetVisible(false)
        self.goStatusC:SetVisible(false)
        self.textTime:SetVisible(false)
        self.textStatus:SetVisible(false)
        g_Game.SpriteManager:LoadSprite(config:SubIcon(), self.imgImgResidentA)
    end
    local iconBg = ArtResourceUIConsts.sp_city_citizen_base_normal
    if healthStatus == HealthStatusEnum.UnHealth then
        iconBg = ArtResourceUIConsts.sp_city_citizen_base_red
    elseif healthStatus == HealthStatusEnum.Health then
        iconBg = ArtResourceUIConsts.sp_city_citizen_base_green
    end
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(iconBg), self.imgBase)
    self.sliderProgress:SetVisible(healthStatus ~= HealthStatusEnum.Health and healthStatus ~= HealthStatusEnum.FaintingReadyWakeUp)
    self.goRecover:SetVisible(healthStatus == HealthStatusEnum.Fainting)
    self.btnRecover:SetVisible(healthStatus == HealthStatusEnum.FaintingReadyWakeUp)
    self.goBaseRecover:SetVisible(self._needTickInInfection)
    self.sliderProgress.value = self._cellParameter.citizenData:GetInfectionPercentLocal()
    self:TickSecond()
    self._buffCellsReady = false
end

function CommonCitizenCellComponent:OnBtnBackClicked(args)
    if self._cellParameter and self._cellParameter.onClickRecall then
        self._cellParameter.onClickRecall()
    end
end

function CommonCitizenCellComponent:OnBtnRecoverClicked(args)
    if self._cellParameter and self._cellParameter.onClickRecover then
        self._cellParameter.onClickRecover()
    end
end

function CommonCitizenCellComponent:OnBtnSelfClicked(args)
    if self._cellParameter and self._cellParameter.onClickSelf then
        self._cellParameter.onClickSelf()
    end
end

function CommonCitizenCellComponent:SetSelected(isSelected)
    if isSelected then
        self.goGroupSelect:SetVisible(true)
        if self._allowShowReCall then
            self.btnBack:SetVisible(true)
        end
        if self._allowShowBuffDetail then
            self:ShowBuffDetail()
        end
    else
        if self._allowShowBuffDetail then
            self:HideBuffDetail()
        end
        self.btnBack:SetVisible(false)
        self.goGroupSelect:SetVisible(false)
    end
end

function CommonCitizenCellComponent:ShowBuffDetail()
    self.tableviewproTableDetail:SetVisible(true)
    self:PrepareBuffCellsReady()
end

function CommonCitizenCellComponent:HideBuffDetail()
    self.tableviewproTableDetail:SetVisible(false)
end

function CommonCitizenCellComponent:PrepareBuffCellsReady()
    if self._buffCellsReady then
        return
    end
    self.tableviewproTableDetail:Clear()
    if not self._cellParameter.citizenData:IsAssignedHouse() then
        ---@type CityCitizenStatusDetailCellData
        local cellData = {}
        cellData.buffIconFlag = 2
        cellData.nameField = I18N.Get("citizen_homeless")
        cellData.valueFiled = I18N.GetWithParams("citizen_homeless_debuff", tostring(50))
        cellData.icon = "sp_city_icon_refugee"
        self.tableviewproTableDetail:AppendData(cellData)
    end
    self._buffCellsReady = true
end

function CommonCitizenCellComponent:TickSecond()
    if not self._needTick or not self._cellParameter then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if self._tickFainting then
        if self._cellParameter.citizenData._faintTime > nowTime then
            self.textTime.text = TimeFormatter.SimpleFormatTime(self._cellParameter.citizenData._faintTime - nowTime)
        else
            self.textTime.text = string.Empty
            self._needTick = false
        end
        return
    end
    if self._needTickInInfection then
        if not self._cellParameter.citizenData:IsWorkingWithInfection() then
            self._needTickInInfection = false
            self.goBaseRecover:SetVisible(false)
        end
    end
    self.sliderProgress.value = self._cellParameter.citizenData:GetInfectionPercentLocal()
    if not self._cellParameter.citizenWork or self._cellParameter.citizenWork._isInfinity then
        return
    end
    local rate,leftTime = self._cellParameter.citizenWork:GetMakeProgress(nowTime)
    self.sliderProgressTimeHealthB.value = rate
    self.sliderProgressTimeInfectionB.value = rate
    self.textTime.text = TimeFormatter.SimpleFormatTime(leftTime)
end

function CommonCitizenCellComponent:BindDrag(onBeginDrag,onDrag,onEndDrag, dragParentList)
    self:DragEvent("p_btn", onBeginDrag, onDrag, onEndDrag, dragParentList)
end

return CommonCitizenCellComponent
