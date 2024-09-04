local BaseActivityPack = require("BaseActivityPack")
local ActivityShopConst = require("ActivityShopConst")
local CommonGotoDetailDefine = require("CommonGotoDetailDefine")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
---@class ActivityPetPack : BaseActivityPack
local ActivityPetPack = class("ActivityPetPack", BaseActivityPack)

local QUALITY_IMG = {
    [1] = "",
    [2] = "",
    [3] = "",
    [4] = "sp_shop_base_activity_round_purple",
    [5] = "sp_shop_base_activity_round_golden",
}

function ActivityPetPack:ctor()
    self.generatedSpine = nil
    self.petId = nil
    ---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
    self.creater = GameObjectCreateHelper.Create()
end

function ActivityPetPack:OnHide()
    self:ReleaseSpine()
end

function ActivityPetPack:PostOnCreate()
    self.goBackGround = self:GameObject("v_base")
    self.btnClose = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnClickClose))
    self.goSpineParent = self:GameObject("p_spine")
    self.imgPet = self:Image("p_img_hero")
end

function ActivityPetPack:PostInitGroupInfoParam()
    self.groupInfoParam.type = ActivityShopConst.GROUP_DETAIL_TYPE.PET
end

function ActivityPetPack:PostInitGotoDetailParam()
    self.gotoDetailParam.type = CommonGotoDetailDefine.TYPE.PET
    self.gotoDetailParam.configId = (self.tabCfg or self.popCfg):GotoPet()
    self.petId = self.gotoDetailParam.configId
end

function ActivityPetPack:InitQualityBase()
    self.imgQuality.gameObject:SetActive(true)
    local packId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(self.packGroupId)
    local packCfg = ConfigRefer.PayGoods:Find(packId)
    local quality = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(packCfg:ItemGroupId())[1].configCell:Quality()
    g_Game.SpriteManager:LoadSprite(QUALITY_IMG[quality], self.imgQuality)
end

function ActivityPetPack:PostOnFeedData(param)
    self.goBackGround:SetActive(param.isShop)
    self.btnClose.gameObject:SetActive(not param.isShop)
    self:ReleaseSpine()
    self:InitPetPortrait()
end

function ActivityPetPack:OnClickClose()
    self:GetParentBaseUIMediator():CloseSelf()
end

function ActivityPetPack:InitPetPortrait()
    local petCfg = ConfigRefer.Pet:Find(self.petId)
    local petSpineCell = ConfigRefer.ArtResourceUI:Find(petCfg:Spine())
    if petSpineCell then
        self.goSpineParent:SetActive(true)
        self.imgPet.gameObject:SetActive(false)
        UIHelper.SimpleCreateSpine(self.creater, self.goSpineParent.transform, petSpineCell, function (go)
            self.generatedSpine = go
        end)
    else
        self.goSpineParent:SetActive(false)
        self.imgPet.gameObject:SetActive(true)
        self:LoadSprite(petCfg:ShowPortrait(), self.imgPet)
    end
end

function ActivityPetPack:ReleaseSpine()
    if self.generatedSpine then
        GameObjectCreateHelper.DestroyGameObject(self.generatedSpine)
        self.generatedSpine = nil
    end
end

return ActivityPetPack