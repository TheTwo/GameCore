local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local ArtResourceUtils = require('ArtResourceUtils')
local UIHelper = require('UIHelper')
local HeroUIUtilities = require('HeroUIUtilities')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local AttrValueType = require('AttrValueType')

---@class PetGeneComp : BaseTableViewProCell
local PetGeneComp = class('PetGeneComp', BaseTableViewProCell)

---@class PetGeneCompData
---@field ConfigId number @pet config id
---@field PetGeneInfo table<number, wds.PetGeneInfo>

function PetGeneComp:ctor()
end

function PetGeneComp:OnCreate()
    self.btn = self:Button('p_btn_dna', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_img_pet = self:Image('p_img_pet')
    self.p_icon1 = self:Image('p_img_1')
    self.p_icon2 = self:Image('p_img_2')
    self.p_icon3 = self:Image('p_img_3')
    self.p_icon4 = self:Image('p_img_4')
    self.p_icon5 = self:Image('p_img_5')
    self.p_icon6 = self:Image('p_img_6')
    self.p_icon7 = self:Image('p_img_7')
    self.p_icon8 = self:Image('p_img_8')
    self.detail1 = self:LuaObject('p_img_1')
    self.detail2 = self:LuaObject('p_img_2')
    self.detail3 = self:LuaObject('p_img_3')
    self.detail4 = self:LuaObject('p_img_4')
    self.detail5 = self:LuaObject('p_img_5')
    self.detail6 = self:LuaObject('p_img_6')
    self.detail7 = self:LuaObject('p_img_7')
    self.detail8 = self:LuaObject('p_img_8')
    self.icons = {self.p_icon1, self.p_icon2, self.p_icon3, self.p_icon4, self.p_icon5, self.p_icon6, self.p_icon7, self.p_icon8}
    self.details = {self.detail1, self.detail2, self.detail3, self.detail4, self.detail5, self.detail6, self.detail7, self.detail8}
    -- self.btn:SetVisible(true)
end

---@param param PetGeneCompData
function PetGeneComp:OnFeedData(param)
    for i = 1, 8 do
        self.icons[i]:SetVisible(false)
    end

    if param then
        self.param = param
        if self.p_img_pet then
            local cfg = ConfigRefer.Pet:Find(param.ConfigId)
            g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(cfg:Icon()), self.p_img_pet)
        end
        local index = 1
        if param.PetGeneInfo then
            for k, v in pairs(param.PetGeneInfo) do
                local data
                self.icons[index]:SetVisible(true)
                local quality = ConfigRefer.PetConsts:PetGeneQuality(v.GeneLevel)
                quality = math.max(1, quality)
                quality = math.min(quality, 3)
                if self.showDetail then
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
                        local valueType = attrElementCfg:ValueType()
                        -- string concat "%%"
                        if valueType ~= AttrValueType.Fix then
                            displayValue = displayValue .. "%"
                        end
                    end

                    data = {quality = quality, index = k, level = v.GeneLevel, name = I18N.Get(geneCfg:Name()), desc = I18N.GetWithParams(geneCfg:Desc(), displayValue)}
                else
                    data = {quality = quality, index = k, level = v.GeneLevel}
                end
                self.details[index]:FeedData(data)

                index = index + 1
            end
        end
    end
end

function PetGeneComp:OnBtnClick()
    if self.showDetail then
        return
    end

    if not self.param.PetGeneInfo or #self.param.PetGeneInfo == 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_gene_none_tips'))
        return
    end

    g_Game.UIManager:Open(UIMediatorNames.PetGeneMediator, self.param)
end

function PetGeneComp:ShowDetail(isShow)
    self.showDetail = isShow
end

return PetGeneComp
