local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local Utils = require('Utils')
local UIHelper = require("UIHelper")

---@class GuideDemoData
---@field imageId number
---@field videoId number
---@field title string
---@field desc string
---@field videoLockRange number


---@class GuideDemoUIMediator : BaseUIMediator
local GuideDemoUIMediator = class('GuideDemoUIMediator', BaseUIMediator)

function GuideDemoUIMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type number|nil
    self._tickCloseProgressTotal = nil
    ---@type number|nil
    self._tickCloseProgressCurrent = nil
end

function GuideDemoUIMediator:OnCreate()
    self.goGroupDetail = self:GameObject("p_group_detail")
    self.goGroupCenter = self:GameObject("p_group_center")
    self.imgImg = self:Image('p_img')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnLeftClicked))
    self.btnRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnRightClicked))
    self.iconClose = self:Image("p_icon_close")
    self.closeProgress = self:GameObject("p_progress_close")
    self.closeProgressFill = self:Image("p_fill")
    self.textTitle = self:Text('p_text_title')
    self.textDetail = self:Text('p_text_detail')
    self.textTitleL = self:Text('p_text_title_l')
    self.tableviewproTableBar = self:TableViewPro('p_table_bar')

    ---@type CS.VideoPlayerMediator
    self.playerMediator = self:BindComponent("", typeof(CS.VideoPlayerMediator))
    self.goDrawer = self:GameObject("p_drawer")
    self.videoDrawerRect = self:RectTransform('mask')
end

---@param param table:{ data: {GuideDemoData}, ... }
function GuideDemoUIMediator:OnShow(param)
    if param then
        if param.data then
            self.demoData = param.data
        end
    end
    if Utils.IsNull(self.demoData) then
        local curGuideInfo = ModuleRefer.GuideModule.curInfo
        if not curGuideInfo or not curGuideInfo.stepCfg then
            self:CloseSelf()
            return
        end
        local cfg = ModuleRefer.GuideModule.curInfo.stepCfg
        local demoCount = cfg:DemoLength()
        ---@type GuideDemoMediatorData
        self.demoData = {}
        for i = 1, demoCount do
            local cfgId = cfg:Demo(i)
            local demoCfg = ConfigRefer.GuideDemo:Find(cfgId)
            if demoCfg then
            ---@type GuideDemoData
                local data = {
                    imageId = demoCfg:Pic(),
                    videoId = demoCfg:Video(),
                    title = demoCfg:Title(),
                    desc = demoCfg:Desc(),
                    videoLockRange = demoCfg:BlockSkipPercent(),
                }
                table.insert(self.demoData,data)
            end
        end
    end
    self.count = #self.demoData
    self.index = 1
    self:SetupDemo(self.demoData[self.index])

    g_Game:AddFrameTicker(Delegate.GetOrCreate(self,self.Tick))
end

function GuideDemoUIMediator:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self,self.Tick))
end

function GuideDemoUIMediator:OnOpened(param)

end

function GuideDemoUIMediator:OnClose(param)

end

--local Input = CS.UnityEngine.Input
function GuideDemoUIMediator:Tick(dt)
    if self._tickCloseProgressTotal and self._tickCloseProgressCurrent then
        self._tickCloseProgressCurrent = self._tickCloseProgressCurrent - dt
        local p = math.inverseLerp(0, self._tickCloseProgressTotal, self._tickCloseProgressCurrent)
        self.closeProgressFill.fillAmount = p
        if self._tickCloseProgressCurrent <= 0 then
            self._tickCloseProgressCurrent = nil
            self._tickCloseProgressTotal = nil
            self.closeProgress:SetVisible(false)
            UIHelper.SetGray(self.iconClose.gameObject, false)
        end
    end
    --if Input.GetKeyDown(CS.UnityEngine.KeyCode.A) then
    --    --require('StoryActionUtils').TemporaryUIRootInteractable(false)
    --    local a = 12
    --end
end

function GuideDemoUIMediator:OnBtnCloseClicked(args)
    if self._tickCloseProgressCurrent then
        return
    end
    self:CloseSelf()
end

function GuideDemoUIMediator:OnBtnLeftClicked(args)
    self.index = self.index - 1
    if self.index < 1 then
        self.index = self.count
    end
    self:SetupDemo(self.demoData[self.index])
end

function GuideDemoUIMediator:OnBtnRightClicked(args)
    self.index = self.index + 1
    if self.index > self.count then
        self.index = 1
    end
    self:SetupDemo(self.demoData[self.index])
end

---@param data GuideDemoData
function GuideDemoUIMediator:SetupDemo(data)
    self._tickCloseProgressCurrent = nil
    self._tickCloseProgressTotal = nil
    local inCloseBlockCount = false
    if data.videoId and data.videoId > 0 then
        self.imgImg:SetVisible(false)
        self.goDrawer:SetVisible(true)
        local videoCfg = ConfigRefer.Movie:Find(data.videoId)
        local videoAssetName = videoCfg:Path()
        local videoType = videoCfg:SrcType()
        --TODO Play VideoStreaming From URL
        local videoClip = g_Game.VideoClipManager:LoadVideoClip(videoAssetName)
        if not Utils.IsNullOrEmpty(videoClip) then
            -- self.playerMediator:Play(videoClip, nil , g_Game.UIManager:GetUICamera())
            local vWidth,vHeight
            if self.videoDrawerRect then
                vWidth = 1280
                vHeight = 720
            end
            if data.videoLockRange and data.videoLockRange > 0 then
                inCloseBlockCount = true
                self.closeProgressFill.fillAmount = 1
                self._tickCloseProgressCurrent = videoClip.length * math.clamp01(data.videoLockRange)
                self._tickCloseProgressTotal = videoClip.length
            end
            self.playerMediator:PlayOnUI(videoClip, nil , nil,vWidth,vHeight)
        end
    elseif data.imageId then
        self.imgImg:SetVisible(true)
        self.goDrawer:SetVisible(false)
        self:LoadSprite(data.imageId,self.imgImg)
    end
    self.closeProgress:SetVisible(inCloseBlockCount)
    UIHelper.SetGray(self.iconClose.gameObject, inCloseBlockCount)

    self.textTitleL.text = I18N.Get(data.title)
    self.textDetail.text = I18N.Get(data.desc)
    self.goGroupDetail:SetActive(string.IsNullOrEmpty(data.desc) == false)

    if self.count >= 2 then
        self.tableviewproTableBar:SetVisible(true)
        self.btnLeft:SetVisible(true)
        self.btnRight:SetVisible(true)
        self.tableviewproTableBar:Clear()
        for i = 1, self.count do
            self.tableviewproTableBar:AppendData(i == self.index)
        end
    else
        self.tableviewproTableBar:SetVisible(false)
        self.btnLeft:SetVisible(false)
        self.btnRight:SetVisible(false)
    end
end

return GuideDemoUIMediator
