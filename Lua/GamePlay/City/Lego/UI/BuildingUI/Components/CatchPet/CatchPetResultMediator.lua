---@sceneName:scene_catch_pet_show_ten
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local GuideUtils = require('GuideUtils')
local UIMediatorNames = require("UIMediatorNames")

---@class CatchPetResultMediatorParameter
---@field result wrpc.AutoCatchPetReward

---@class CatchPetResultMediator:BaseUIMediator
---@field new fun():CatchPetResultMediator
---@field super BaseUIMediator
local CatchPetResultMediator = class('CatchPetResultMediator', BaseUIMediator)

local THRESHOLD = 5
local TIME_PER_PET = 0.2
local TIME_BASE = 0.5

---@param param CatchPetResultMediatorParameter
function CatchPetResultMediator:OnCreate(param)
    self.txtTitle = self:Text("p_text_title", 'pet_drone_acquired_pets_name')
    self.txtHint = self:Text("p_text_hint", 'activity_24h_free_hero_6')
    self.txtHint:SetVisible(false)

    self.btnClose = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnBtnCloseClicked))

    self.tableBig = self:TableViewPro("p_table_list")
    self.tableSmall = self:TableViewPro("p_table_list_center")

    self.vxTrigger = self:AnimTrigger('trigger')
end

---@param param CatchPetResultMediatorParameter
function CatchPetResultMediator:OnOpened(param)
    self.param = param

    self:ShowCaughtPets()
end

function CatchPetResultMediator:OnClose()
    if self.param.isEgg then
        if ModuleRefer.GuideModule:IsGuideFinished(39) then
            return
        end
        GuideUtils.GotoByGuide(39)
    end
end

function CatchPetResultMediator:ShowCaughtPets()
    -- 去掉白底
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)

    ---@type CS.TableViewPro
    local currTable = nil
    local catchPetsCount = self.param.result.RewardPets:Count()
    self.tableBig:SetVisible(catchPetsCount >= THRESHOLD)
    self.tableSmall:SetVisible(catchPetsCount < THRESHOLD)
    if catchPetsCount >= THRESHOLD then
        currTable = self.tableBig
    else
        currTable = self.tableSmall
    end

    currTable:Clear()
    for i = 1, catchPetsCount do
        local petCompId = self.param.result.RewardPets[i].PetCompId
        local petCfgId = self.param.result.RewardPets[i].PetId
        local pet = ModuleRefer.PetModule:GetPetByID(petCompId)
        ---@type CatchPetResultCellData
        local cellData = {}
        cellData.isNew = ModuleRefer.PetModule:IsNewPet(petCompId)
        ---@type CommonPetIconBaseData
        cellData.petIconData = {
            id = petCompId,
            cfgId = petCfgId,
            onClick = function(data, rectTransform)
                ---@type CityPetDetailsTipUIParameter
                local param = {
                    id = petCompId,
                    cfgId = petCfgId,
                    Level = pet.Level,
                    removeFunc = nil,
                    workTimeFunc = nil,
                    benefitFunc = nil,
                    rectTransform = rectTransform,
                }
                g_Game.UIManager:Open(UIMediatorNames.CityPetDetailsTipUIMediator, param)
            end,
            selected = false,
            level = pet.Level,
            rank = pet.RankLevel,
            showMask = false,
            showDelete = false,
        }
        currTable:AppendData(cellData)
    end

    TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.DelayUnlockClose), TIME_BASE)
end

function CatchPetResultMediator:DelayUnlockClose()
    self.canClose = true
    self.txtHint:SetVisible(true)
    ModuleRefer.ToastModule:IngoreBlockPower()
end

function CatchPetResultMediator:OnBtnCloseClicked()
    if self.canClose then
        self:CloseSelf()
    end
end

return CatchPetResultMediator