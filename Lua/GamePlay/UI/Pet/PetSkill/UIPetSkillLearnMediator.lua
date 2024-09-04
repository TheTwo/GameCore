local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetSkillType = require("PetSkillType")
local CommonDropDown = require('CommonDropDown')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')

---@class UIPetSkillLearnMediator : BaseUIMediator
local UIPetSkillLearnMediator = class('UIPetSkillLearnMediator', BaseUIMediator)
function UIPetSkillLearnMediator:ctor()
    self._rewardList = {}
end

function UIPetSkillLearnMediator:OnCreate()
    ---@type CommonPopupBackLargeComponent
    self.child_popup_base_l = self:LuaObject("child_popup_base_l")
    self.p_text_title = self:Text('p_text_title')
    self.p_text_one = self:Text('p_text_one', "pet_drone_quick_select_name")
    ---@type CommonDropDown
    self.child_dropdown_1 = self:LuaObject('child_dropdown_1')
    self.child_dropdown_2 = self:LuaObject('child_dropdown_2')
    self.p_btn_study = self:Button('p_btn_study', Delegate.GetOrCreate(self, self.OnClickConfirm))
    self.p_btn_one = self:Button('p_btn_one', Delegate.GetOrCreate(self, self.OnClickSelectAll))
    self.p_text = self:Text('p_text')
    ---@type BaseSkillIcon
    self.child_item_skill = self:LuaObject("child_item_skill")
    self.p_text_name = self:Text('p_text_name')
    self.p_text_skill_detail = self:Text('p_text_skill_detail')
    self.p_text_progress = self:Text('p_text_progress', "pet_skill_progress_name")
    self.p_progress = self:Slider('p_progress')
    self.p_progress_add = self:Slider('p_progress_add')
    self.p_table_pet = self:TableViewPro('p_table_pet')

    self.p_text_num = self:Text('p_text_num')
    self.p_text_add = self:Text('p_text_add')
    self.p_icon_arrow = self:Image('p_icon_arrow')

    if self.child_dropdown_1 then
        self.child_dropdown_1:SetVisible(false)
    end

    if self.child_dropdown_2 then
        self.child_dropdown_2:SetVisible(false)
    end

    -- self.vx_trigger = self:BindComponent("vx_trigger", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    self.vx_trigger = self:AnimTrigger("vx_trigger")

    self.p_number_bl = self:GameObject("p_number_bl")
    self.p_text_cost = self:Text("p_text_cost")
    self.p_icon_cost = self:Image("p_icon_cost")

    if self.p_number_bl then
        self.p_number_bl:SetVisible(false)
    end
end

function UIPetSkillLearnMediator:OnShow(param)
    local skill = ModuleRefer.PetModule:GetPetLearnableSkill(param.skillId)
    self.isLearn = not skill.Active
    if self.isLearn then
        local titleCompData = {title = "pet_skill_practice_name"}
        self.child_popup_base_l:FeedData(titleCompData)
        self.p_text.text = I18N.Get("pet_skill_practice_name")
    else
        local titleCompData = {title = "pet_rank_up_name"}
        self.child_popup_base_l:FeedData(titleCompData)
        self.p_text.text = I18N.Get("pet_uplevel")
    end
    self.isLevelUp = false
    self.isLevelUp_temp = false

    self.skillId = param.skillId
    self.cellIndex = param.cellIndex
    self:InitContent(param)
    self:RefreshContent()
end

function UIPetSkillLearnMediator:OnHide(param)
    if self.isLevelUp then
        g_Game.EventManager:TriggerEvent(EventConst.PET_UI_MAIN_REFRESH)
    end
end

function UIPetSkillLearnMediator:InitContent(param)
    self.curPet = ModuleRefer.PetModule:GetCurSelectedPet()
    self.cfg = ConfigRefer.PetLearnableSkill:Find(param.skillId)

    self.selectedNum = 0
    self.p_text_name.text = I18N.Get(self.cfg:Name())

    -- local sortDropDownData = {}
    -- sortDropDownData.items = CommonDropDown.CreateData("", I18N.Get("#1星以下"), "", I18N.Get("#2星以下"), "", I18N.Get("#3星以下"), "", I18N.Get("#4星以下"), "", I18N.Get("#5星以下"),
    --                                                    "", I18N.Get("#全部"))
    -- sortDropDownData.defaultId = 6
    -- sortDropDownData.onSelect = Delegate.GetOrCreate(self, self.OnDropDownSelect)
    -- self.child_dropdown_1:FeedData(sortDropDownData)
    -- self.sortStarNums = sortDropDownData.defaultId
end

function UIPetSkillLearnMediator:RefreshText()
    local curProgress, maxProgress, level, itemGroupId = ModuleRefer.PetModule:GetPetSkillExpAndLevel(self.skillId)
    if self.level and self.level < level then
        self.isLevelUp = true
        self.isLevelUp_temp = true
    end
    self.level = level
    self.curProgress = curProgress
    self.maxNum = maxProgress
    local progressNum = self.curProgress + self.selectedNum
    self.needNum = self.maxNum - progressNum
    local petName = I18N.Get(ConfigRefer.Pet:Find(ConfigRefer.PetType:Find(self.cfg:RefPetType()):SamplePetCfg()):Name())
    -- local colorStr = ModuleRefer.PetModule:GetQualityStr(self.cfg:Quality())
    -- local colorNumStr = needNum.."/"..self.maxNum
    if self.isLearn then
        -- self.p_text_title.text = I18N.GetWithParams("pet_skill_material_desc", colorStr, progressNum, self.maxNum)
    else
        self.p_text_title.text = I18N.GetWithParams("petskill_upgrade_condition", petName, progressNum .. "/" .. self.maxNum)
    end

    local itemGroupCfg = ConfigRefer.ItemGroup:Find(itemGroupId)
    local info = itemGroupCfg:ItemGroupInfoList(1)
    local item = ConfigRefer.Item:Find(info:Items())
    self.levelUpItemId = item:Id()
    -- local iconData = {}
    -- iconData.configCell = ConfigRefer.Item:Find(info:Items())
    local count = 0
    local uid = ModuleRefer.InventoryModule:GetUidByConfigId(self.levelUpItemId)
    if uid then
        count = ModuleRefer.InventoryModule:GetItemInfoByUid(uid).Count
    end
    self.levelUpItemCount = count

    self.p_text_cost.text = I18N.Get("ziyuandi_xiaohao") .. ": " .. self.selectedNum

    if count >= self.selectedNum then
        self.itemEnough = true
    else
        self.itemEnough = false
    end

    g_Game.SpriteManager:LoadSprite(item:Icon(), self.p_icon_cost)

    local curPercent = self.curProgress / self.maxNum
    local finalPercent = (self.selectedNum + self.curProgress) / self.maxNum
    self.p_progress.value = curPercent
    self.p_progress_add.value = finalPercent
    self.p_text_num.text = math.floor(curPercent * 100) .. "%"
    self.p_text_add.text = math.floor(finalPercent * 100) .. "%"
    self.p_text_add:SetVisible(not (curPercent == finalPercent))
    self.p_icon_arrow:SetVisible(not (curPercent == finalPercent))
    self.p_text_skill_detail.text = ModuleRefer.PetModule:GetPetSkillDesc(self.curPet, self.skillId)

    self.child_item_skill:FeedData({
        playNextStarVfx = true,
        playEquipVfx = self.isLevelUp,
        isPet = true,
        index = self.cfg:Id(),
        skillId = self.skillId,
        skillLevel = ModuleRefer.PetModule:GetSkillLevel(self.curPet, false, self.skillId),
    })
end

function UIPetSkillLearnMediator:RefreshContent()

    local pets = ModuleRefer.PetModule:GetPetList()
    self.sortedPets = {}
    self.petsData = {}
    -- 宠物数据排序
    for id, pet in pairs(pets) do
        local cfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
        -- 只有同种宠物会展示
        if self.cfg:RefPetType() == cfg:Type() then
            local bindHeroId = ModuleRefer.PetModule:GetPetLinkHero(id)
            local petQuality = cfg:Quality()
            local qualify = false

            -- 是否绑定
            if self.curPet == id then
                qualify = false
            elseif bindHeroId and bindHeroId > 0 then
                qualify = false
            else
                qualify = self.cfg:RefPetType() == cfg:Type()
            end

            local petTypeCfg = ModuleRefer.PetModule:GetTypeCfg(pet.Type)
            local petTagId = petTypeCfg:PetTagDisplay()

            local data = {
                id = id,
                cfgId = pet.ConfigId,
                onClick = Delegate.GetOrCreate(self, self.OnPetSelected),
                needSelect = true,
                selected = false,
                hideGene = true,
                level = pet.Level,
                rank = pet.rank,
                rarity = petQuality,
                templateIds = pet.TemplateIds,
                heroBind = bindHeroId and bindHeroId > 0,
                qualify = qualify,
                showMask = not qualify,
                isWorking = ModuleRefer.PetModule:IsPetWorking(id),
                isBattle = petTagId > 0,
            }
            self.petsData[id] = data
            table.insert(self.sortedPets, data)
        end
    end
    self:SortPetData()

    -- 添加宠物
    self.p_table_pet:Clear()
    for id, pet in ipairs(self.sortedPets) do
        self.p_table_pet:AppendData(pet)
    end
    -- self.p_table_pet:RefreshAllShownItem()
    self:RefreshText()
end

--- 伙伴数据排序
---@param self UIPetMediator
function UIPetSkillLearnMediator:SortPetData()
    table.sort(self.sortedPets, UIPetSkillLearnMediator.SortSkills)
end

function UIPetSkillLearnMediator.SortSkills(a, b)
    if (a.qualify and not b.qualify) then
        return true
    elseif (not a.qualify and b.qualify) then
        return false
    elseif (a.isWorking ~= b.isWorking) then
        return not a.isWorking
    elseif (a.rarity ~= b.rarity) then
        return a.rarity < b.rarity
    elseif (a.level ~= b.level) then
        return a.level < b.level
    elseif (a.rank ~= b.rank) then
        return a.rank < b.rank
    else
        return a.cfgId < b.cfgId
    end
end

function UIPetSkillLearnMediator:OnPetSelected(data, trans)
    if (not data or not data.qualify) then
        return
    end

    local selected = not self.petsData[data.id].selected
    if selected then
        if self.needNum == 0 then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_select_enough_tips"))
            return false
        end
        if ModuleRefer.PetModule:IsPetLocked(data.id) then
            ---@type CommonConfirmPopupMediatorParameter
            local param = {}
            param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
            param.title = I18N.Get("Energy_DoubleCheck")
            param.content = I18N.Get("pet_locked_tips")
            param.onConfirm = function()
                ModuleRefer.PetModule:SetPetLock(data.id)
                self.selectedNum = self.selectedNum + 1
                self.petsData[data.id].selected = true
                self.p_table_pet:SetMultiSelect(data)
                self:RefreshText()
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)

        elseif data.isWorking and not ModuleRefer.PetModule:GetPetWorkingConfirm() then
            local city = ModuleRefer.CityModule.myCity
            local name = ModuleRefer.PetModule:GetPetName(data.id)
            local furnitureName = city.furnitureManager:GetFurnitureById(data.isWorking).name
            ---@type CommonConfirmPopupMediatorParameter
            local param = {}
            param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn | CommonConfirmPopupMediatorDefine.Style.Toggle
            param.title = I18N.Get("Energy_DoubleCheck")
            param.content = I18N.GetWithParams("mention_popup_pet_remove", name, furnitureName)
            param.onConfirm = function()
                self.selectedNum = self.selectedNum + 1
                self.petsData[data.id].selected = true
                self.p_table_pet:SetMultiSelect(data)
                self:RefreshText()
                return true
            end
            param.toggle = false
            param.toggleDescribe = I18N.Get('alliance_battle_confirm2')
            param.toggleClick = function(context, checked)
                ModuleRefer.PetModule:SetPetWorkingConfirm(checked)
                return checked
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
        else
            self.selectedNum = self.selectedNum + 1
            self.petsData[data.id].selected = true
            self.p_table_pet:SetMultiSelect(data)
        end
    else
        self.petsData[data.id].selected = false
        self.selectedNum = self.selectedNum - 1
        self.p_table_pet:UnSelectMulti(data)
    end
    self:RefreshText()
end

function UIPetSkillLearnMediator:OnClickSelectAll()
    local need = self.maxNum - self.curProgress
    if need == 0 or self.selectedNum == need then
        return
    end

    for k, v in pairs(self.sortedPets) do
        v.selected = false
    end
    self.selectedNum = 0
    local selected = {}
    for k, v in pairs(self.sortedPets) do
        if v.qualify and not v.isWorking and not ModuleRefer.PetModule:IsPetLocked(v.id) then
            need = need - 1
            selected[k] = v.id
            v.selected = false
        end
        if need == 0 then
            break
        end
    end

    if need > 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("getmore_title_c"))
    end
    for k, v in pairs(selected) do
        -- self.sortedPets[k].selected = true
        self.petsData[v].selected = true
        self.selectedNum = self.selectedNum + 1
        self.p_table_pet:SetMultiSelect(self.petsData[v])
    end
    self:RefreshText()
end

function UIPetSkillLearnMediator:OnClickConfirm()
    if not self.itemEnough then
        ---@param itemInfos {id:number, num:number}[]
        local itemInfos = {{id = self.levelUpItemId, num = self.selectedNum - self.levelUpItemCount}}
        ModuleRefer.InventoryModule:OpenExchangePanel(itemInfos)
        return
    end
    local costs = {}
    local hasPet = false
    for k, v in pairs(self.sortedPets) do
        if v.selected then
            table.insert(costs, v.id)
            hasPet = true
        end
    end
    if not hasPet then
        return
    end

    if self.level == 0 then
        ModuleRefer.PetModule:LearnSkill(costs, self.cfg:Id(), function()
            self.selectedNum = 0
            self:RefreshContent()
            if self.curProgress / self.maxNum == 0 then
                g_Game.UIManager:CloseByName("UIPetSkillLearnMediator")
            end
        end)
    else
        ModuleRefer.PetModule:UpgradeSkill(costs, self.cfg:Id(), function()
            self.selectedNum = 0
            self:RefreshContent()
            if self.isLevelUp_temp then
                self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
                self.isLevelUp_temp = false
            end
        end)
    end
end

function UIPetSkillLearnMediator:OnDropDownSelect(id)
    -- self.sortStarNums = id
    self.selectedNum = 0
    self:RefreshContent()
end

return UIPetSkillLearnMediator
