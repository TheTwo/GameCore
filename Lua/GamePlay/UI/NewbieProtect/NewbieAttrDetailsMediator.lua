local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AttrComputeType = require('AttrComputeType')
local Utils = require('Utils')
local ProtectDefine = require('ProtectDefine')
local TimeFormatter = require('TimeFormatter')

---@class NewbieAttrDetailsMediator : BaseUIMediator
local NewbieAttrDetailsMediator = class('NewbieAttrDetailsMediator', BaseUIMediator)

---@class NewbieAttrDetailsParam
---@field attrEndTime number
---@field protectEndTime number


function NewbieAttrDetailsMediator:OnCreate()
    ---@type CommonPopupBackComponent
    self.luaGoPopBase = self:LuaObject("child_popup_base_m")

    self.textInfo = self:Text('p_text_info', I18N.Get("protect_tips_protect_effect"))
    self.textEffect = self:Text('p_text_effect', I18N.Get("protect_info_protective_effect"))
    self.textBeginner = self:Text('p_text_beginner', I18N.Get("protect_info_Novice_help"))
    self.textCommon = self:Text('p_text_common', I18N.Get("protect_info_normal_status"))

    self.tableviewproTbaleContent = self:TableViewPro('p_table_effect')
end

---@param param NewbieAttrDetailsParam
function NewbieAttrDetailsMediator:OnOpened(param)
    if not param then
        return
    end
    ---@type CommonBackButtonData
    local btnData = {
        title = "protect_info_Novice_help"
    }
    self.luaGoPopBase:FeedData(btnData)

    self.attrEndTime = param.attrEndTime
    self.protectEndTime = param.protectEndTime
    ---@type NewbieAttrTimeItemParam
    local data1 = {endtime = self.protectEndTime}
    self.tableviewproTbaleContent:AppendDataEx(data1, 0, 0, 0)

    ---@type NewbieAttrGroupItemParam
    local textParam1Str = ("%dh"):format(Utils.ParseDurationToSecond(ConfigRefer.ConstMain:AddonDurationOnFirstFallCastle()) / 3600)
    local data2 = {textEffectName = I18N.Get("protect_info_War_protection"),
    textParam1 = textParam1Str,
    textParam2 = I18N.Get("protect_info_Protectors_used")}
    self.tableviewproTbaleContent:AppendDataEx(data2, 0, 0, 1)

    local data3 = {endtime = self.attrEndTime}
    self.tableviewproTbaleContent:AppendDataEx(data3, 0, 0, 0)

    local data4 =self:CreateRelocateData()
    self.tableviewproTbaleContent:AppendDataEx(data4, 0, 0, 1)

    local data5 = self:CreateJoinUnionData()
    self.tableviewproTbaleContent:AppendDataEx(data5, 0, 0, 1)

    -- local data6 = {textEffectName = I18N.Get("protect_info_Quickly_move"),
    -- textParam1 = I18N.Get("protect_info_open"),
    -- textParam2 = I18N.Get("protect_info_closed")}
    -- self.tableviewproTbaleContent:AppendDataEx(data6, 0, 0, 1)

end


function NewbieAttrDetailsMediator:OnClose(param)
    --TODO
end

function NewbieAttrDetailsMediator:CreateJoinUnionData()
    local data = {textEffectName = I18N.Get("protect_info_Join_Alliance_Cooldown")}
    local userDefaultConfig = ConfigRefer.UserDefault:Find(ProtectDefine.UserDefault_JoinUnionCDIndex)
    if not userDefaultConfig then
        return data
    end
    local cityTechLevelConifg = ConfigRefer.CityTechLevels:Find(userDefaultConfig:Technology(1))
    if not cityTechLevelConifg then
        return data
    end
    local attrGroupConfig = ConfigRefer.AttrGroup:Find(cityTechLevelConifg:AttributeReward())
    if not attrGroupConfig then
        return data
    end
    self.joinUnionCDBase = attrGroupConfig:AttrList(1):Value() or 0
    data.textParam2 = TimeFormatter.TimerStringFormat(self.joinUnionCDBase)
    local attrList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(ConfigRefer.ConstMain:AddonOnFirstFallCastle())
    data.textParam1 = TimeFormatter.TimerStringFormat(self:CalcAttrValueByAttrlist(attrList, 1))
    return data
end

function NewbieAttrDetailsMediator:CreateRelocateData()
    local data = {textEffectName = I18N.Get("protect_info_relocate_cooldown")}
    local userDefaultConfig = ConfigRefer.UserDefault:Find(ProtectDefine.UserDefault_RelocateCDIndex)
    if not userDefaultConfig then
        return data
    end
    local cityTechLevelConifg = ConfigRefer.CityTechLevels:Find(userDefaultConfig:Technology(1))
    if not cityTechLevelConifg then
        return data
    end
    local attrGroupConfig = ConfigRefer.AttrGroup:Find(cityTechLevelConifg:AttributeReward())
    if not attrGroupConfig then
        return data
    end
    self.relocateCDBase = attrGroupConfig:AttrList(1):Value() or 0
    data.textParam2 = TimeFormatter.TimerStringFormat(self.relocateCDBase)
    local attrList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(ConfigRefer.ConstMain:AddonOnFirstFallCastle())
    data.textParam1 = TimeFormatter.TimerStringFormat(self:CalcAttrValueByAttrlist(attrList, 2))
    return data
end

function NewbieAttrDetailsMediator:CalcAttrValueByAttrlist(attrList, index)
    for i, attr in ipairs(attrList) do
        if index == i then
            local attrCfg = ConfigRefer.AttrElement:Find(attr.type)
            if not attrCfg then
                goto continue
            end
            local baseValue = 0
	        local multiValue = 1
	        local pointValue = 0
            if (attrCfg:ComputeType() == AttrComputeType.Base) then
                baseValue = attr.value
            elseif (attrCfg:ComputeType() == AttrComputeType.Multi) then
                multiValue = 1 + attr.value
            elseif (attrCfg:ComputeType() == AttrComputeType.Point) then
                pointValue = attr.value
            end
            if index == 1 then
                baseValue = baseValue > 0 and baseValue or self.joinUnionCDBase
            elseif index == 2 then
                baseValue = baseValue > 0 and baseValue or self.relocateCDBase
            end

            return baseValue * multiValue + pointValue
        end
        ::continue::
    end
end

return NewbieAttrDetailsMediator