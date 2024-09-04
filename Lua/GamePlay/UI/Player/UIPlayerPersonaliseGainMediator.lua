local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class UIPlayerPersonaliseGainMediator : BaseUIMediator
local UIPlayerPersonaliseGainMediator = class('UIPlayerPersonaliseGainMediator', BaseUIMediator)


function UIPlayerPersonaliseGainMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaObject("child_popup_base_m")

    self.goContent = self:GameObject('p_group_content')
    self.textContent = self:Text('p_text_content', 'skincollection_increase_name')
    self.textContentNum = self:Text('p_text_number', 'skincollection_increase_value')
    self.tableviewproDetails = self:TableViewPro('p_table_detail')

    self.goEmpty = self:GameObject('p_group_empty')
    self.textEmpty = self:Text('p_text_number_1', 'skincollection_increases_none')
end


function UIPlayerPersonaliseGainMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local btnData = {
        title = I18N.Get("skincollection_increases")
    }
    self.compChildPopupBaseM:FeedData(btnData)

    local gainBuffList = ModuleRefer.PersonaliseModule:GetGainBuffList()
    if #gainBuffList > 0 then
        self:ShowContent(gainBuffList)
    else
        self:ShowEmpty()
    end
end


function UIPlayerPersonaliseGainMediator:OnClose()
    --TODO
end

---@param gainBuffList {type:number, value:number}[]
function UIPlayerPersonaliseGainMediator:ShowContent(gainBuffList)
    self.goContent:SetActive(true)
    self.goEmpty:SetActive(false)

    for i = 1, #gainBuffList do
        local gainBuff = gainBuffList[i]
        local cellData = {
            type = gainBuff.type,
            gainNum = gainBuff.value,
            index = i
        }

        self.tableviewproDetails:AppendData(cellData)
    end
end

function UIPlayerPersonaliseGainMediator:ShowEmpty()
    self.goContent:SetActive(false)
    self.goEmpty:SetActive(true)
end


return UIPlayerPersonaliseGainMediator