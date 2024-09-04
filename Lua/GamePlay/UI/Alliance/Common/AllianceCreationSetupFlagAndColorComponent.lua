local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local AllianceModule = require("AllianceModule")
local ColorUtility = CS.UnityEngine.ColorUtility

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceCreationSetupFlagAndColorComponentParameter
---@field flag CommonAllianceLogoComponent
---@field areaImage CS.UnityEngine.UI.Image
---@field originData wds.AllianceFlag
---@field onCancel fun()
---@field onConfirm fun(newValue:wds.AllianceFlag, btnTrans:CS.UnityEngine.Transform)
---@field disableConfirmWhenNoChange boolean

---@class AllianceCreationSetupFlagAndColorComponent:BaseUIComponent
---@field new fun():AllianceCreationSetupFlagAndColorComponent
---@field super BaseUIComponent
local AllianceCreationSetupFlagAndColorComponent = class('AllianceCreationSetupFlagAndColorComponent', BaseUIComponent)


function AllianceCreationSetupFlagAndColorComponent:ctor()
    BaseUIComponent.ctor(self)
    ---@type AllianceCreationSetupFlagAndColorComponentParameter
    self._parameter = nil
    ---@type AllianceBadgeAppearanceConfigCell[]
    self._appearanceCells = {}
    ---@type AllianceBadgePatternConfigCell[]
    self._patternCells = {}
    ---@type AllianceTerritoryColorCellData[]
    self._territoryColorCells = {}
    ---@type wds.AllianceFlag
    self._editData = wds.AllianceFlag.New()
    self._blockChange = false
end

function AllianceCreationSetupFlagAndColorComponent:OnCreate(param)
    self._p_text_pattern_1 = self:Text("p_text_pattern_1", "league_pattern_1")
    self._p_text_pattern_2 = self:Text("p_text_pattern_2", "league_pattern_2")
    self._p_text_color = self:Text("p_text_color", "territory_color")
    self._p_table_logo = self:TableViewPro("p_table_logo")
    self._p_table_logo:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedAppearance))
    self._p_table_pattern = self:TableViewPro("p_table_pattern")
    self._p_table_pattern:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedPattern))
    self._p_table_color = self:TableViewPro("p_table_color")
    self._p_table_color:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedTerritoryColor))
    self._p_comp_btn_cancle = self:Button("p_comp_btn_cancle", Delegate.GetOrCreate(self, self.OnClickCancelBtn))
    self._p_comp_btn_confirm = self:Button("p_comp_btn_confirm", Delegate.GetOrCreate(self, self.OnClickConfirmBtn))
    self._p_text_cancel_logo = self:Text("p_text_cancel_logo", "cancle")
    self._p_text_confirm_logo = self:Text("p_text_confirm_logo", "confirm")
    
    for _, v in ConfigRefer.AllianceBadgeAppearance:ipairs() do
        table.insert(self._appearanceCells, v)
    end
    for _, v in ConfigRefer.AllianceBadgePattern:ipairs() do
        table.insert(self._patternCells, v)
    end
    for _, v in ConfigRefer.AllianceTerritoryColor:ipairs() do
        local success,color = ColorUtility.TryParseHtmlString(v:Color())
        ---@type AllianceTerritoryColorCellData
        local cellData = {
            Id = v:Id(),
            color = success and color or CS.UnityEngine.Color.white
        }
        table.insert(self._territoryColorCells, cellData)
    end
end

function AllianceCreationSetupFlagAndColorComponent:OnClose(param)
    self._p_table_logo:SetSelectedDataChanged(nil)
    self._p_table_pattern:SetSelectedDataChanged(nil)
    self._p_table_color:SetSelectedDataChanged(nil)
end

---@param data AllianceCreationSetupFlagAndColorComponentParameter
function AllianceCreationSetupFlagAndColorComponent:OnFeedData(data)
    self._parameter = data

    AllianceModule.CopyFlagSetting(data.originData, self._editData)
    
    self._p_table_logo:Clear()
    self._p_table_pattern:Clear()
    self._p_table_color:Clear()
    self._blockChange = true
    local currentSelected
    local index = 0
    for _, v in ipairs(self._appearanceCells) do
        self._p_table_logo:AppendData(v)
        if v:Id() == self._editData.BadgeAppearance then
            currentSelected = index
        end
        index = index + 1
    end
    if currentSelected then
        self._p_table_logo:SetToggleSelectIndex(currentSelected)
    end
    self._p_table_logo:Play(true)
    currentSelected = nil
    index = 0
    for _, v in ipairs(self._patternCells) do
        self._p_table_pattern:AppendData(v)
        if v:Id() == self._editData.BadgePattern then
            currentSelected = index
        end
        index = index + 1
    end
    if currentSelected then
        self._p_table_pattern:SetToggleSelectIndex(currentSelected)
    end
    self._p_table_pattern:Play(true)
    currentSelected = nil
    index = 0
    for _, v in ipairs(self._territoryColorCells) do
        self._p_table_color:AppendData(v)
        if v.Id == self._editData.TerritoryColor then
            currentSelected = index
        end
        index = index + 1
    end
    if currentSelected then
        self._p_table_color:SetToggleSelectIndex(currentSelected)
    end
    self._p_table_color:Play(true)
    self:UpdatePreview()
    self._blockChange = false
end

function AllianceCreationSetupFlagAndColorComponent:OnClickCancelBtn()
    AllianceModule.CopyFlagSetting(self._parameter.originData, self._editData)
    self:UpdatePreview()
    self._parameter.onCancel()
end

function AllianceCreationSetupFlagAndColorComponent:OnClickConfirmBtn()
    self._parameter.onConfirm(self._editData, self._p_comp_btn_confirm.transform)
end

---@param selectedData AllianceBadgeAppearanceConfigCell
function AllianceCreationSetupFlagAndColorComponent:OnSelectedAppearance(last, selectedData)
    if self._blockChange then
        return
    end
    if not selectedData then
        return
    end
    self._editData.BadgeAppearance = selectedData:Id()
    self:UpdatePreview()
end

---@param selectedData AllianceBadgePatternConfigCell
function AllianceCreationSetupFlagAndColorComponent:OnSelectedPattern(last, selectedData)
    if self._blockChange then
        return
    end
    if not selectedData then
        return
    end
    self._editData.BadgePattern = selectedData:Id()
    self:UpdatePreview()
end

---@param selectedData AllianceTerritoryColorCellData
function AllianceCreationSetupFlagAndColorComponent:OnSelectedTerritoryColor(last, selectedData)
    if self._blockChange then
        return
    end
    if not selectedData then
        return
    end
    self._editData.TerritoryColor = selectedData.Id
    self:UpdatePreview()
end

function AllianceCreationSetupFlagAndColorComponent:UpdatePreview()
    self._parameter.flag:FeedData(self._editData)
    local cfg = ConfigRefer.AllianceTerritoryColor:Find(self._editData.TerritoryColor)
    if cfg then
        local success,color = ColorUtility.TryParseHtmlString(cfg:Color())
        self._parameter.areaImage.color = success and color or CS.UnityEngine.Color.white
    end
    if self._parameter.disableConfirmWhenNoChange then
        local originData = self._parameter.originData
        local editData = self._editData
        if originData.TerritoryColor == editData.TerritoryColor
                and originData.BadgeAppearance == editData.BadgeAppearance
                and originData.BadgePattern == editData.BadgePattern then
            self._p_comp_btn_confirm.interactable = false
        else
            self._p_comp_btn_confirm.interactable = true
        end
    end
end

return AllianceCreationSetupFlagAndColorComponent