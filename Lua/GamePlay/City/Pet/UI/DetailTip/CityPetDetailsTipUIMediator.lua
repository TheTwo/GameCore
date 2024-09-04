---Scene Name :     
local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityPetDetailsTipI18N = require("CityPetDetailsTipI18N")
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local ChatShareType = require("ChatShareType")
local FPXSDKBIDefine = require("FPXSDKBIDefine")
local NumberFormatter = require("NumberFormatter")
local Utils = require("Utils")
local TipsRectTransformUtils = require("TipsRectTransformUtils")
local CityUtils = require("CityUtils")
local CommonTipPopupDefine = require("CommonTipPopupDefine")

---@class CityPetDetailsTipUIMediator:BaseUIMediator
local CityPetDetailsTipUIMediator = class('CityPetDetailsTipUIMediator', BaseUIMediator)

function CityPetDetailsTipUIMediator:OnCreate()
    ---根节点，用于处理Tip吸附功能
    self._content = self:Transform("content")

    ---@type CommonPetIconSmall @宠物头像
    self._child_card_pet_circle = self:LuaObject("child_card_pet_circle")
    ---宠物名字
    self._p_text_name = self:Text("p_text_name")
    ---Features
    self._p_layout_type = self:Transform("p_layout_type")
    ---@type CityPetDetailsTipFeature
    self._p_type = self:LuaBaseComponent("p_type")
    self._pool_feature = LuaReusedComponentPool.new(self._p_type, self._p_layout_type)
    ---位置
    self._p_position = self:GameObject('p_position')
    self._icon_position = self:GameObject("icon_position")
    self._p_text_position = self:Text("p_text_position")
    ---改名入口
    self._p_btn_change_name = self:Button("p_btn_change_name", Delegate.GetOrCreate(self, self.OnClickChangeName))
    ---宠物属性
    self._p_detail_layout = self:Transform("p_detail_layout")
    ---@type CityPetDetailsTipProperty
    self._p_item_detail = self:LuaBaseComponent("p_item_detail")
    self._pool_property = LuaReusedComponentPool.new(self._p_item_detail, self._p_detail_layout)
    ---宠物详情
    self._p_btn_details = self:Button("p_btn_details", Delegate.GetOrCreate(self, self.OnClickPetDetails))
    self._p_text_details = self:Text("p_text_details", CityPetDetailsTipI18N.UIButton_PetDetails)

    ---宠物工作增益
    ---@type CityPetDetailsTipWorkBenefit
    self._p_work_info = self:LuaBaseComponent("p_work_info")
    ---@type CityPetDetailsTipWorkRemainTime
    self._p_work_remain_time = self:LuaObject("p_work_remain_time")
    ---血条信息
    self._p_blood = self:GameObject("p_blood")
    self._p_progress_blood = self:Image("p_progress_blood")
    ---百分比
    self._p_text_blood_number = self:Text("p_text_blood_number")
    ---血条详情
    self._child_comp_btn_detail = self:GameObject("child_comp_btn_detail")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickHpDetails))
    
    ---底部信息
    self._p_bottom = self:GameObject("p_bottom")
    ---状态描述
    self._p_text_hint = self:Text("p_text_hint")
    ---空闲状态字
    self._p_text_free = self:Text("p_text_free", CityPetDetailsTipI18N.UIHint_Free)
    ---工作状态字
    self._p_text_working = self:Text("p_text_working")
    ---安排工作
    self._p_btn_work = self:Button("p_btn_work", Delegate.GetOrCreate(self, self.OnClickAssignWork))
    self._p_btn_work:SetVisible(false)
    self._p_text = self:Text("p_text", CityPetDetailsTipI18N.UIButton_AssignWork)
    ---移除工作
    self._p_btn_remove = self:Button("p_btn_remove", Delegate.GetOrCreate(self, self.OnClickRemoveWork))
    self._p_btn_remove:SetVisible(false)
    self._p_text_remove = self:Text("p_text_remove", CityPetDetailsTipI18N.UIButton_Remove)
    -- 分享
    self._p_btn_share = self:Button("p_btn_share", Delegate.GetOrCreate(self, self.OnClickShare))
    -- 技能卸下
    self._p_btn_unload = self:Button("p_btn_unload", Delegate.GetOrCreate(self, self.OnClickRemoveSkill))
    self._p_text_unload = self:Text("p_text_unload","pet_skill_unload_name")

    --Test
    -- self._p_btn_share:SetVisible(true)
end

---@class CityPetDetailsTipUIParameter
---@field id number
---@field cfgId number
---@field Level number
---@field removeFunc fun()
---@field workTimeFunc fun(petId:number):string
---@field benefitFunc fun(petId:number):string, string
---@field rectTransform CS.UnityEngine.RectTransform

---@param param CityPetDetailsTipUIParameter
function CityPetDetailsTipUIMediator:OnOpened(param)
    self.city = ModuleRefer.CityModule.myCity
    self.removeFunc = param.removeFunc
    self.petId = param.id
    ---@type fun(petId:number):string, string
    self.benefitFunc = param.benefitFunc
    ---@type fun(petId:number):string
    self.workTimeFunc = param.workTimeFunc
    self.rectTransform = param.rectTransform

    local pet = ModuleRefer.PetModule:GetPetByID(self.petId)
    ---@type UIPetIconData
    local UIPetIconData = {id = self.petId, cfgId = param.cfgId, selected = false, level = param.Level}
    self._child_card_pet_circle:FeedData(UIPetIconData)
    local cfg = ConfigRefer.Pet:Find(param.cfgId)
    self.cfg = cfg
    self._p_text_name.text = ModuleRefer.PetModule:GetPetName(self.petId)

    -- 位置
    self._p_text_position.text = self.city.petManager:GetWorkPosition(self.petId)

    -- 工作类型
    self._pool_feature:HideAll()
    for i = 1, cfg:PetWorksLength() do
        local petWorkCfg = ConfigRefer.PetWork:Find(cfg:PetWorks(i))
        local workType = petWorkCfg:Type()
        local level = petWorkCfg:Level()
        local param = {level = level, name = ModuleRefer.PetModule:GetPetWorkTypeStr(workType), icon = ModuleRefer.PetModule:GetPetWorkTypeIcon(workType)}
        local item = self._pool_feature:GetItem().Lua
        item:FeedData(param)
    end

    -- 基因词条
    self._pool_property:HideAll()
    if pet.PetGeneInfo then
        for k, v in pairs(pet.PetGeneInfo) do
            local geneCfg = ConfigRefer.PetGene:Find(v.GeneTid)
            local attrTemplate = ConfigRefer.AttrTemplate:Find(geneCfg:BuffTemplate())
            local displayValue = 0
            local group = attrTemplate:AttrGroupIdList(v.GeneLevel)
            if group then
                local attrGroupCfg = ConfigRefer.AttrGroup:Find(group)
                local attr = attrGroupCfg:AttrList(1)
                local attrElementCfg = ConfigRefer.AttrElement:Find(attr:TypeId())
                local value = attr:Value()
                displayValue = ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrElementCfg, value)
            end
            local param = {index = k, level = v.GeneLevel, name = I18N.Get(geneCfg:Name()), desc = I18N.Get(geneCfg:Desc()), value = displayValue}
            local item = self._pool_property:GetItem().Lua
            item:FeedData(param)
        end
    end

    -- 工作增益效果
    self._p_work_info:SetVisible(self.benefitFunc ~= nil)
    if self.benefitFunc then
        local icon, value = self.benefitFunc(self.petId)
        self._p_work_info:FeedData({icon = icon, value = value})
    end

    --- 剩余工作时间显示
    self._p_work_remain_time:SetVisible(self.workTimeFunc ~= nil)
    if self.workTimeFunc then
        self._p_work_remain_time:OnFeedData(self.workTimeFunc(self.petId))
    end

    local hp = self.city.petManager:GetHpPercent(self.petId)
    self._p_progress_blood.fillAmount = hp
    self._p_text_blood_number.text = NumberFormatter.Percent(hp)

    local petDatum = self.city.petManager.cityPetData[self.petId]
    local showBottom = petDatum ~= nil
    self._p_bottom:SetVisible(showBottom)
    if showBottom then
        if petDatum:IsExhausted() then
            self._p_text_hint.text = I18N.Get("work_status_desc_01")
        elseif petDatum:IsHungry() then
            self._p_text_hint.text = I18N.Get("work_status_desc_02")
        elseif petDatum:IsSleeping() then
            self._p_text_hint.text = I18N.Get("work_status_desc_07")
        else
            self._p_text_hint.text = I18N.Get("work_status_desc_06")
        end

        local petUnit = self.city.petManager.unitMap[self.petId]
        if not petUnit then
            self._p_text_working:SetVisible(false)
            self._p_text_free:SetVisible(true)
        else
            local isBusy, status = petUnit:GetStatusDesc()
            self._p_text_working:SetVisible(isBusy)
            self._p_text_free:SetVisible(not isBusy)
            self._p_text_working.text = status
        end
    end

    --宠物技能 展示卸下按钮
    if self.removeFunc then
        self._p_bottom:SetVisible(false)
        self._p_blood:SetVisible(false)
        self._p_position:SetVisible(false)
        self._p_btn_unload:SetVisible(true)
    end

    if Utils.IsNotNull(self.rectTransform) then
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._content)
        self:OnLateTick(0)
        g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    end
end

function CityPetDetailsTipUIMediator:OnClose(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
end

function CityPetDetailsTipUIMediator:OnLateTick(dt)
    if Utils.IsNull(self.rectTransform) then return end
    self.lastEdge = TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self.rectTransform, self._content, self.lastEdge)
end

function CityPetDetailsTipUIMediator:OnClickPetDetails(param)
    g_Game.UIManager:CloseByName(UIMediatorNames.UIPetSkillMediator)
    -- g_Game.UIManager:CloseByName(UIMediatorNames.PetSkillPopUpMediator)
    local mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIPetMediator)
    if mediator then
        mediator:GotoPet(self.petId)
    else
        g_Game.UIManager:Open(UIMediatorNames.UIPetMediator, {petId = self.petId})
	end
    g_Game.UIManager:CloseByName(UIMediatorNames.CityPetDetailsTipUIMediator)
end

function CityPetDetailsTipUIMediator:OnClickChangeName(param)
    ModuleRefer.PetModule:RenamePet(self.petId)
    self:CloseSelf()
end

function CityPetDetailsTipUIMediator:OnClickHpDetails(param)
    CityUtils.OpenCommonSimpleTips(I18N.Get("pet_hp_tips"), self._p_btn_detail.transform, CommonTipPopupDefine.ArrowMode.Right)
end

function CityPetDetailsTipUIMediator:OnClickRemoveWork(param)

end

function CityPetDetailsTipUIMediator:OnClickRemoveSkill(param)
    if self.removeFunc then
        self.removeFunc()
    end
end

function CityPetDetailsTipUIMediator:OnClickShare(param)
	if not self.cfg then
		return
	end
	local param = {}
    param.type = ChatShareType.Pet
	param.configID = self.cfg:Id()
	local starLevel, skillLevels = ModuleRefer.PetModule:GetSkillLevelQuality(self.petId)

	local petInfo = ModuleRefer.PetModule:GetPetByID(self.petId)
	local templateIds = petInfo.TemplateIds or {}
	local templateLvs = petInfo.TemplateLevels
	local unlockNum = #petInfo.TemplateIds
	if unlockNum > 0 then
		param.x = templateIds[1]
		param.y = templateLvs[1]
	end
	param.z = petInfo.RandomAttrItemCfgId
    param.skillLevels = skillLevels
	g_Game.UIManager:Open(UIMediatorNames.ShareChannelChooseMediator, param)
	local keyMap = FPXSDKBIDefine.ExtraKey.pet_share
    local extraDic = {}
    extraDic[keyMap.pet_id] = self.petId
	extraDic[keyMap.pet_type] = self.cfg:Type()
	extraDic[keyMap.pet_cfgId] = self.cfg:Id()
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.pet_share, extraDic)
    self:CloseSelf()
end

return CityPetDetailsTipUIMediator
