local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local FunctionClass = require('FunctionClass')
local UIMediatorNames = require('UIMediatorNames')
local HeroCardPreviewMediator = class('HeroCardPreviewMediator',BaseUIMediator)

function HeroCardPreviewMediator:OnCreate()
    BaseUIMediator.OnCreate(self)
    self.btnSkip = self:Button('p_btn_back', Delegate.GetOrCreate(self, self.OnBtnBackClicked))
    self.compGroupHero = self:LuaObject('p_group_hero')
    self.compGroupPet = self:LuaObject('p_group_pet')
end

function HeroCardPreviewMediator:OnOpened(param)
    self.closeCallback = param.closeCallback
    local cardMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardMediator)
    if cardMediator then
        cardMediator:SetVisible(false)
    end
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if hudMediator then
        hudMediator:SetVisible(false)
    end
    -- local selectMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardSelectMediator)
    -- if selectMediator then
    --     selectMediator:SetVisible(false)
    -- end
    local itemCfg = ConfigRefer.Item:Find(param.itemId)
    if itemCfg:FunctionClass() == FunctionClass.AddHero then
        local heroId = tonumber(itemCfg:UseParam(1))
        self.compGroupHero:SetVisible(true)
        self.compGroupPet:SetVisible(false)
        self.compGroupHero:FeedData({heroId = heroId})
    elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
        local petId = tonumber(itemCfg:UseParam(1))
        self.compGroupHero:SetVisible(false)
        self.compGroupPet:SetVisible(true)
        self.compGroupPet:FeedData({petId = petId})
    end
end

function HeroCardPreviewMediator:OnBtnBackClicked(args)
    self:CloseSelf()
end

function HeroCardPreviewMediator:GetSelectHero()
    return self.compGroupHero:GetSelectHero()
end

function HeroCardPreviewMediator:OnClose(param)
    local cardMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardMediator)
    if cardMediator then
        cardMediator:SetVisible(true)
    end
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if hudMediator then
        hudMediator:SetVisible(true)
    end
    -- local selectMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardSelectMediator)
    -- if selectMediator then
    --     selectMediator:SetVisible(true)
    -- end
    if self.closeCallback then
        self.closeCallback()
    end
end

return HeroCardPreviewMediator