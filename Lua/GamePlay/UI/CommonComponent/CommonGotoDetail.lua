local BaseUIComponent = require("BaseUIComponent")
local CommonGotoDetailDefine = require("CommonGotoDetailDefine")
local Delegate = require("Delegate")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local GuideUtils = require("GuideUtils")
local ModuleRefer = require("ModuleRefer")
---@class CommonGotoDetail:BaseUIComponent
local CommonGotoDetail = class("CommonGotoDetail", BaseUIComponent)
---@scene scene_child_activity_detial

---@class CommonGotoDetailParam
---@field displayMask number @CommonGotoDetailDefine.DISPLAY_MASK, default: ALL
---@field type number @CommonGotoDetailDefine.TYPE
---@field configId number
---@field videoId number | table<number, number> @GuideDemo ConfigId
---@field customGotoText string
---@field customPlayVideoText string
---@field customReplay fun()

---@class CommonGotoDetailCustomParam
---@field displayMask number @CommonGotoDetailDefine.DISPLAY_MASK, default: ALL
---@field customGoto fun()
---@field customPlayVideo fun()
---@field customReplay fun()
---@field customGotoText string
---@field customPlayVideoText string

function CommonGotoDetail:OnCreate()
    self.btnGoto = self:Button("p_btn_hero_detail", Delegate.GetOrCreate(self, self.OnBtnGotoClick))
    self.textGoto = self:Text("p_text_hero_detail")
    self.btnVideo = self:Button("p_btn_video", Delegate.GetOrCreate(self, self.OnBtnVideoClick))
    self.textVideo = self:Text("p_text_video")
    self.btnReplay = self:Button("p_btn_replay", Delegate.GetOrCreate(self, self.OnBtnReplayClick))
end

---@param param CommonGotoDetailParam | CommonGotoDetailCustomParam
function CommonGotoDetail:OnFeedData(param)
    self.param = param
    self.param.displayMask = self.param.displayMask or CommonGotoDetailDefine.DISPLAY_MASK.ALL
    self:UpdateGotoBtn()
    self:UpdateVideoBtn()
    self:UpdateReplayBtn()
end

function CommonGotoDetail:UpdateGotoBtn()
    if CommonGotoDetailDefine.DISPLAY_MASK.BTN_GOTO & self.param.displayMask == 0 then
        self.btnGoto.gameObject:SetActive(false)
        return
    end
    self.btnGoto.gameObject:SetActive(self.param.configId and self.param.configId ~= 0)
    self.textGoto.text = self.param.customGotoText or I18N.Get('first_pay_hero_goto')
end

function CommonGotoDetail:UpdateVideoBtn()
    if CommonGotoDetailDefine.DISPLAY_MASK.BTN_VIDEO & self.param.displayMask == 0 then
        self.btnVideo.gameObject:SetActive(false)
        return
    end
    if type(self.param.videoId) == 'table' then
        self.btnVideo.gameObject:SetActive(self.param.videoId and #self.param.videoId > 0)
    else
        self.btnVideo.gameObject:SetActive(self.param.videoId and self.param.videoId > 0)
    end
    self.textVideo.text = self.param.customPlayVideoText or I18N.Get('first_pay_hero_skill')
end

function CommonGotoDetail:UpdateReplayBtn()
    if CommonGotoDetailDefine.DISPLAY_MASK.BTN_REPLAY & self.param.displayMask == 0 then
        self.btnReplay.gameObject:SetActive(false)
        return
    end
    self.btnReplay.gameObject:SetActive(self.param.customReplay ~= nil)
end

function CommonGotoDetail:OnBtnGotoClick()
    if self.param.customGoto then
        self.param.customGoto()
        return
    end
    if not self.param.configId or self.param.configId == 0 then
        g_Logger.ErrorChannel("CommonGotoDetail", "configId is nil or 0")
        return
    end
    if self.param.type == CommonGotoDetailDefine.TYPE.HERO then
        local heroType = ConfigRefer.Heroes:Find(self.param.configId):Type()
        g_Game.UIManager:Open(UIMediatorNames.UIHeroMainUIMediator, {id = self.param.configId, type = heroType})
    elseif self.param.type == CommonGotoDetailDefine.TYPE.PET then
        ModuleRefer.PetModule:ShowPetPreview(self.param.configId, "sss")
    elseif self.param.type == CommonGotoDetailDefine.TYPE.GUIDE then
        GuideUtils.GotoByGuide(self.param.configId)
    end
end

function CommonGotoDetail:OnBtnVideoClick()
    if self.param.customPlayVideo then
        self.param.customPlayVideo()
        return
    end
    local videoIds
    if type(self.param.videoId) == 'table' then
        videoIds = self.param.videoId
    else
        videoIds = {self.param.videoId}
    end
    local data = {}
    for _, demoId in ipairs(videoIds) do
        local demoCfg = ConfigRefer.GuideDemo:Find(demoId)
        local demo = {
            imageId = demoCfg:Pic(),
            videoId = demoCfg:Video(),
            title = demoCfg:Title(),
            desc = demoCfg:Desc(),
        }
        table.insert(data, demo)
    end
    g_Game.UIManager:Open(UIMediatorNames.GuideDemoUIMediator, {data = data})
end

function CommonGotoDetail:OnBtnReplayClick()
    if self.param.customReplay then
        self.param.customReplay()
        return
    end
end

return CommonGotoDetail