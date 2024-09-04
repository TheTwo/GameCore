local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local Delegate = require('Delegate')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local UIMediatorNames = require('UIMediatorNames')

local CityFurnitureUnlockMediator = class('CityFurnitureUnlockMediator', BaseUIMediator)
function CityFurnitureUnlockMediator:ctor()
    self._rewardList = {}
end

function CityFurnitureUnlockMediator:OnCreate()
    self.p_text_title = self:Text('p_text_title', "citylevel_up")
    self.p_text = self:Text('p_text', "citizen_btn_start")

    self.p_work = self:GameObject("p_work")
    self.p_pet = self:GameObject("p_pet")
    self.p_landform = self:GameObject("p_landform")
    self.p_recipe = self:GameObject("p_recipe")

    self.p_text_title_work = self:Text('p_text_title_work')
    self.p_text_title_pet = self:Text('p_text_title_pet', "citylevel_unlock_preview_animal")
    self.p_text_title_landform = self:Text('p_text_title_landform')
    self.p_text_title_recipe = self:Text('p_text_title_recipe', "citylevel_unlock_preview_recipe")

    self.p_table_work = self:TableViewPro('p_table_work')
    self.p_table_pet = self:TableViewPro('p_table_pet')
    self.p_table_landform = self:TableViewPro('p_table_landform')
    self.p_table_recipe = self:TableViewPro('p_table_recipe')

    self.p_btn = self:Button("p_btn", Delegate.GetOrCreate(self, self.OnBtnClick))
end

function CityFurnitureUnlockMediator:OnOpened(param)
    local level = param.level
    local id = param.furnitureId
    local levelCfg = ConfigRefer.CityFurnitureLevel:Find(tonumber(id) + level - 1)
    local length = levelCfg:UnlockPreviewLength()
    local petType = length > 0 and string.split(levelCfg:UnlockPreview(1), ',') or {}
    local land = length > 1 and levelCfg:UnlockPreview(2) or ""
    local cityWorkProcess = length > 2 and string.split(levelCfg:UnlockPreview(3), ',') or {}
    local slot = length > 3 and levelCfg:UnlockPreview(4) or ""
    local petPos = length > 4 and levelCfg:UnlockPreview(5) or ""

    self.p_pet:SetVisible(#petType > 0)
    self.p_landform:SetVisible(land ~= "")
    self.p_recipe:SetVisible(#cityWorkProcess > 0)
    self.p_work:SetVisible(slot ~= "" or petPos ~= "")

    self.p_table_pet:Clear()
    if #petType > 0 then
        for i = 1, #petType do
            if i > 3 then
                return
            end
            local param = {petTypeId = tonumber(petType[i])}
            self.p_table_pet:AppendData(param)
        end
    end

    self.p_table_landform:Clear()
    if land ~= "" then
        self.landId = tonumber(land)
        local landCfg = ConfigRefer.Land:Find(self.landId)
        local sprite = landCfg:Icon()
        local param = {landId = self.landId, sprite = sprite}
        self.p_text_title_landform.text = I18N.Get(landCfg:Name())
        self.p_table_landform:AppendData(param)

    end

    self.p_table_recipe:Clear()
    if #cityWorkProcess > 0 then
        for i = 1, #cityWorkProcess do
            if i > 3 then
                return
            end
            local itemId = ConfigRefer.CityWorkProcess:Find(tonumber(cityWorkProcess[i])):Output()
            if itemId > 0 then
                local sprite = ConfigRefer.Item:Find(itemId):Icon()
                self.p_table_recipe:AppendData({sprite = sprite})
            end
        end
    end

    self.p_table_work:Clear()
    if slot ~= "" then
        self.p_text_title_work.text = I18N.Get("citylevel_unlock_preview_workslot")
        self.p_table_work:AppendData({})

    elseif petPos ~= "" then
        self.p_text_title_work.text = I18N.Get("citylevel_unlock_preview_team0" .. petPos)
        self.p_table_work:AppendData({})
    end
end

function CityFurnitureUnlockMediator:OnClose()
end

function CityFurnitureUnlockMediator:OnShow(param)
end

function CityFurnitureUnlockMediator:OnHide(param)
end

function CityFurnitureUnlockMediator:OnBtnClick()
    self:CloseSelf()
end

return CityFurnitureUnlockMediator
