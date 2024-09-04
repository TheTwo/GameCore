local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require('UIMediatorNames')
local Delegate = require('Delegate')
---@class HeroCardPreviewPet : BaseUIComponent
local HeroCardPreviewPet = class('HeroCardPreviewPet', BaseUIComponent)

local PAGE_DETAIL_BASIC = 0
local PAGE_DETAIL_WORLD = 1
local PAGE_DETAIL_PRODUCTION = 2

local ATTR_DISP_ID_ATTACK = 15
local ATTR_DISP_ID_DEFENSE = 18
local ATTR_DISP_ID_HP = 27
local ATTR_DISP_ID_SE_MOVE_SPEED = 39

function HeroCardPreviewPet:OnCreate()
    self.imgPet = self:Image('p_img_pet')
    self.textName = self:Text("p_text_name")
    self.detailPageController = self:BindComponent("p_scroll_pet", typeof(CS.PageViewController))
	self.detailPageController.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)
    self.detailSENodes = {}
	self.detailSENodes[1] = self:GameObject("p_addition_1")
	self.detailSENodes[2] = self:GameObject("p_addition_2")
	self.detailSENodes[3] = self:GameObject("p_addition_3")
	self.detailSENodes[4] = self:GameObject("p_addition_4")
	self.detailSEIcons = {}
	self.detailSEIcons[1] = self:Image("p_icon_1")
	self.detailSEIcons[2] = self:Image("p_icon_2")
	self.detailSEIcons[3] = self:Image("p_icon_3")
	self.detailSEIcons[4] = self:Image("p_icon_4")
	self.detailSETexts = {}
	self.detailSETexts[1] = self:Text("p_text_lv_1")
	self.detailSETexts[2] = self:Text("p_text_lv_2")
	self.detailSETexts[3] = self:Text("p_text_lv_3")
	self.detailSETexts[4] = self:Text("p_text_lv_4")
	self.detailSENumbers = {}
	self.detailSENumbers[1] = self:Text("p_text_num_1")
	self.detailSENumbers[2] = self:Text("p_text_num_2")
	self.detailSENumbers[3] = self:Text("p_text_num_3")
	self.detailSENumbers[4] = self:Text("p_text_num_4")
    self.detailSECard = self:LuaObject("child_card_skill")

    self.textDetailWorldTitle = self:Text("p_text_title_map", "pet_attr_slg")
	self.textDetailWorldText = self:Text("p_text_detail_map")

	self.textDetailProductionTitle = self:Text("p_text_title_process", "pet_attr_city")
	self.textDetailProductionText = self:Text("p_text_detail_process")

	self.buttonDetailBasicToggle = self:Button("p_btn_01", Delegate.GetOrCreate(self, self.OnDetailBasicToggleButtonClick))
	self.buttonDetailBasicSelected = self:GameObject("p_btn_select_01")
	self.buttonDetailWorldToggle = self:Button("p_btn_02", Delegate.GetOrCreate(self, self.OnDetailWorldToggleButtonClick))
	self.buttonDetailWorldSelected = self:GameObject("p_btn_select_02")
	self.buttonDetailProductionToggle = self:Button("p_btn_03", Delegate.GetOrCreate(self, self.OnDetailProductionToggleButtonClick))
	self.buttonDetailProductionSelected = self:GameObject("p_btn_select_03")
    -- self.quality = self:Image("p_icon_quality")
	self.textQuality = self:Text("p_text_quality")

    -- 临时屏蔽后两页属性
	self.detailPageController.enabled = false

	-- 临时隐藏物理防御力
	self.detailSENodes[3]:SetActive(false)
	self.imgPet.gameObject:SetActive(false)
end

function HeroCardPreviewPet:OnFeedData(param)
    local petId = param.petId
	local petCfg = ModuleRefer.PetModule:GetPetCfg(petId)
	self.textName.text = I18N.Get(petCfg:Name())
	self.textName.color = UIHelper.TryParseHtmlString(ConfigRefer.ColorConst:Find(petCfg:PetColor()):ColorStr())
	self.textQuality.text = I18N.Get(ModuleRefer.PetModule:GetQualityI18N(petCfg:Quality()))
	self.textQuality.color = ModuleRefer.PetModule:GetQualityColor(petCfg:Quality() + 1)
    self.detailSECard:FeedData({
		cardId = petCfg:CardId(),
		onClick = Delegate.GetOrCreate(self, self.OnPetCardClick),
	})

    local attrList = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(petCfg:Attr(), 1)
	local dispConfAttack = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_ATTACK)
	local attack = ModuleRefer.AttrModule:GetDisplayValueWithData(dispConfAttack, attrList)
	self.detailSENumbers[1].text = tostring(attack)
	self.detailSETexts[1].text = I18N.Get(dispConfAttack:DisplayAttr())
	local dispConfDefense = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_DEFENSE)
	local defense = ModuleRefer.AttrModule:GetDisplayValueWithData(dispConfDefense, attrList)
	self.detailSENumbers[3].text = tostring(defense)
	self.detailSETexts[3].text = I18N.Get(dispConfDefense:DisplayAttr())
	local dispConfHp = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_HP)
	local hp = ModuleRefer.AttrModule:GetDisplayValueWithData(dispConfHp, attrList)
	self.detailSENumbers[2].text = tostring(hp)
	self.detailSETexts[2].text = I18N.Get(dispConfHp:DisplayAttr())
	local dispConfSeSpeed = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_SE_MOVE_SPEED)
	local seSpeed = ModuleRefer.AttrModule:GetDisplayValueWithData(dispConfSeSpeed, attrList)
	self.detailSENumbers[4].text = tostring(seSpeed)
	self.detailSETexts[4].text = I18N.Get(dispConfSeSpeed:DisplayAttr())
	self:Show3DModel(petCfg)
end

function HeroCardPreviewPet:Show3DModel(petCfg)
    -- if (petCfg) then
	-- 	local artConf = ConfigRefer.ArtResource:Find(petCfg:ShowModel())
    --     g_Game.UIManager:CloseUI3DModelView()
    --     g_Game.UIManager:SetupUI3DModelView(artConf:Path(),
	-- 			ConfigRefer.ArtResource:Find(petCfg:ShowBackground()):Path(),
	-- 			nil, function(viewer)
    --         self.ui3dModel = viewer
    --         self.ui3dModel:SetLitAngle(CS.UnityEngine.Vector3(30,322.46,0))
    --         self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(artConf:ModelPosition(1), artConf:ModelPosition(2), artConf:ModelPosition(3)))
	-- 		self.ui3dModel:InitVirtualCameraSetting(self:Get3DCameraSettings())
    --         self.ui3dModel:RefreshEnv()
	-- 		self:Play3DModelBgAnim()
    --     end)
    -- end
end

function HeroCardPreviewPet:OnClose(param)
	self.detailPageController.onPageChanged = nil
	-- if self.ui3dModel then
    -- 	g_Game.UIManager:CloseUI3DModelView()
	-- end
end

function HeroCardPreviewPet:Play3DModelBgAnim()
	if (not self.ui3dModel) then return end
	local anim = self.ui3dModel.curEnvGo.transform:Find("vx_w_hero_main/all/vx_ui_hero_main"):GetComponent(typeof(CS.UnityEngine.Animation))
	if (anim) then
		anim:Play("anim_vx_w_hero_main_open")
	end
end

--- 获取3D相机参数
---@param self UIPetMediator
function HeroCardPreviewPet:Get3DCameraSettings()
    local cameraSetting = {}
    for i = 1, 2 do
        local setting = {}
        setting.fov = 3
        setting.nearCp = 40
        setting.farCp = 48
		setting.localPos = CS.UnityEngine.Vector3(0.065423, 3.751282, -43.87342)
        cameraSetting[i] = setting
    end
    return cameraSetting
end

function HeroCardPreviewPet:OnPetCardClick(cardId)
	---@type UICommonPopupCardDetailParam
	local param = {
		type = 1,
		cfgId = cardId,
	}
	g_Game.UIManager:Open(UIMediatorNames.UICommonPopupCardDetailMediator, param)
end

--- 切换到指定属性页
---@param self HeroCardPreviewPet
---@param page number
---@param scroll boolean
function HeroCardPreviewPet:SwitchToDetailPage(page, scroll)
	if (page == PAGE_DETAIL_BASIC) then
		self.buttonDetailBasicToggle.gameObject:SetActive(false)
		self.buttonDetailBasicSelected:SetActive(true)

		self.buttonDetailWorldToggle.gameObject:SetActive(true)
		self.buttonDetailWorldSelected:SetActive(false)

		self.buttonDetailProductionToggle.gameObject:SetActive(true)
		self.buttonDetailProductionSelected:SetActive(false)
	elseif (page == PAGE_DETAIL_WORLD) then
		self.buttonDetailBasicToggle.gameObject:SetActive(true)
		self.buttonDetailBasicSelected:SetActive(false)

		self.buttonDetailWorldToggle.gameObject:SetActive(false)
		self.buttonDetailWorldSelected:SetActive(true)

		self.buttonDetailProductionToggle.gameObject:SetActive(true)
		self.buttonDetailProductionSelected:SetActive(false)
	elseif (page == PAGE_DETAIL_PRODUCTION) then
		self.buttonDetailBasicToggle.gameObject:SetActive(true)
		self.buttonDetailBasicSelected:SetActive(false)

		self.buttonDetailWorldToggle.gameObject:SetActive(true)
		self.buttonDetailWorldSelected:SetActive(false)

		self.buttonDetailProductionToggle.gameObject:SetActive(false)
		self.buttonDetailProductionSelected:SetActive(true)
	end
	if (scroll) then
		self.detailPageController:ScrollToPage(page)
	end
end

function HeroCardPreviewPet:OnDetailBasicToggleButtonClick(args)
	self:SwitchToDetailPage(PAGE_DETAIL_BASIC, true)
end

function HeroCardPreviewPet:OnDetailWorldToggleButtonClick(args)
	-- 临时屏蔽后两页属性
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_toast0"))
	--self:SwitchToDetailPage(PAGE_DETAIL_WORLD, true)
end

function HeroCardPreviewPet:OnDetailProductionToggleButtonClick(args)
	-- 临时屏蔽后两页属性
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_toast0"))
	--self:SwitchToDetailPage(PAGE_DETAIL_PRODUCTION, true)
end

function HeroCardPreviewPet:OnPageChanged(old, new)
	self:SwitchToDetailPage(new)
end

return HeroCardPreviewPet
