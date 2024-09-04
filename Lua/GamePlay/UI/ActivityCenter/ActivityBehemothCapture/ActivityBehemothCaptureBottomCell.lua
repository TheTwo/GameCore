local BaseTableViewProCell = require("BaseTableViewProCell")
local ActivityBehemothConst = require("ActivityBehemothConst")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
---@class ActivityBehemothCaptureBottomCell : BaseTableViewProCell
local ActivityBehemothCaptureBottomCell = class("ActivityBehemothCaptureBottomCell", BaseTableViewProCell)

---@class ActivityBehemothCaptureBottomCellParam
---@field type number
---@field isDeviceBuilt boolean
---@field isLocked boolean
---@field beheMothCfg KmonsterDataConfigCell
---@field beheMothCageCfg FixedMapBuildingConfigCell
---@field showProgress boolean
---@field progress number
---@field isSelect boolean
---@field index number
---@field isOccupied boolean

function ActivityBehemothCaptureBottomCell:OnCreate()
    self.sliderProgress = self:Slider("p_sld_time")
    self.imgDevice = self:Image("p_icon_alliance_device")
    self.imgBehemoth = self:Image("p_icon_behemoth_head")
    self.goSelect = self:GameObject("p_select")
    self.goLock = self:GameObject("p_lock")
    self.goFinish = self:GameObject("p_build")
    self.btnCell = self:Button("p_btn_cell", Delegate.GetOrCreate(self, self.OnBtnCellClick))
    self.luaNotifyNode = self:LuaObject("child_reddot_default")
end

---@param param ActivityBehemothCaptureBottomCellParam
function ActivityBehemothCaptureBottomCell:OnFeedData(param)
    self.param = param
    self.type = param.type
    self.isDeviceBuilt = param.isDeviceBuilt
    self.isLocked = param.isLocked
    self.beheMothCageCfg = param.beheMothCageCfg
    self.beheMothCfg = param.beheMothCfg
    self.showProgress = param.showProgress
    self.progress = param.progress
    self.sliderProgress.gameObject:SetActive(self.showProgress)
    self.sliderProgress.value = self.progress
    self.isSelect = param.isSelect
    self.index = param.index
    self.isOccupied = param.isOccupied
    if self.isSelect then
        self:SelectSelf()
    end
    if self.type == ActivityBehemothConst.BOTTOM_CELL_TYPE.DEVICE then
        self:InitDeviceInfo()
        self.luaNotifyNode:SetVisible(ModuleRefer.ActivityBehemothModule:IsDeviceBuildRewardCanClaim())
    elseif self.type == ActivityBehemothConst.BOTTOM_CELL_TYPE.BEHEMOTH then
        self:InitBehemothInfo()
        self.luaNotifyNode:SetVisible(false)
    end
end

function ActivityBehemothCaptureBottomCell:Select()
    self.goSelect:SetActive(true)
    g_Game.EventManager:TriggerEvent(EventConst.ON_ACTIVITY_BEHEMOTH_CELL_SELECT, self.index)
end

function ActivityBehemothCaptureBottomCell:UnSelect()
    self.goSelect:SetActive(false)
end

function ActivityBehemothCaptureBottomCell:OnBtnCellClick()
    self:SelectSelf()
end

function ActivityBehemothCaptureBottomCell:InitDeviceInfo()
    local deviceCfg = ModuleRefer.ActivityBehemothModule:GetBehemothDeviceCfgs()[1]
    -- local icon = ConfigRefer.ArtResourceUI:Find(deviceCfg:Image()):Path()
    local icon = "sp_behemoth_icon_device_l"
    self.imgDevice.gameObject:SetActive(true)
    self.imgBehemoth.gameObject:SetActive(false)
    g_Game.SpriteManager:LoadSprite(icon, self.imgDevice)
    self.goLock:SetActive(false)
    self.goFinish:SetActive(self.isDeviceBuilt)
end

function ActivityBehemothCaptureBottomCell:InitBehemothInfo()
    -- local _, icon = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(self.beheMothCfg)
    local icon = "sp_behemoth_icon_lion_l"
    self.imgBehemoth.gameObject:SetActive(true)
    self.imgDevice.gameObject:SetActive(false)
    g_Game.SpriteManager:LoadSprite(icon, self.imgBehemoth)
    self.goLock:SetActive(self.isLocked)
    self.goFinish:SetActive(self.isOccupied)
end

return ActivityBehemothCaptureBottomCell