local CommonChooseHelper = {}
local CommonChoosePopupDefine = require('CommonChoosePopupDefine')
local PersonaliseDefine = require('PersonaliseDefine')
local UIHelper = require('UIHelper')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')

local CommonFilterFunc = {
    [CommonChoosePopupDefine.FilterType.Own] = {
        [CommonChoosePopupDefine.FilterEnum.Personalise] = ModuleRefer.PersonaliseModule.GetItemListWithOwnFilter,
    },
    [CommonChoosePopupDefine.FilterType.Quality] = {
        [CommonChoosePopupDefine.FilterEnum.Personalise] = ModuleRefer.PersonaliseModule.GetItemListWithQualityFilter,
    },   
}

local CommonDefaultFilterCode = {}

function CommonChooseHelper.GetFilterFunc(filterType, filterEnum)
    return CommonFilterFunc[filterType][filterEnum]
end

function CommonChooseHelper.GetItemListWithFilterData(itemList, filterData)
    for k, v in pairs(filterData) do
        local filterFunc = CommonChooseHelper.GetFilterFunc(k, CommonChoosePopupDefine.FilterEnum.Personalise)
        itemList = filterFunc(ModuleRefer.PersonaliseModule, itemList, v)
    end
    return itemList
end

function CommonChooseHelper.GetFilterCode(filterData)
    local code = 0
    for k, v in pairs(filterData) do
        code = code | CommonChooseHelper.GetFilterCodeWithType(k, v)
    end
    return code
end

function CommonChooseHelper.GetFilterDataByCode(filterCode)
    local data = {}
    local filterTypeMax = 4      --防止死循环
    local index = 1
    while filterCode > 0 and filterTypeMax >= index do
        local filterType = CommonChooseHelper.GetFilterTypeByIndex(index)
        local subFilterLength = CommonChoosePopupDefine.SubFilterLength[index]
        data[filterType] = filterCode & (2 ^ subFilterLength - 1)
        filterCode = filterCode >> subFilterLength
        index = index + 1
    end
    return data
end

function CommonChooseHelper.GetFilterTypeByIndex(index)
    if index == 1 then
        return CommonChoosePopupDefine.FilterType.Own
    elseif index == 2 then
        return CommonChoosePopupDefine.FilterType.Quality
    elseif index == 3 then
        return CommonChoosePopupDefine.FilterType.HeroBattleType
    elseif index == 4 then
        return CommonChoosePopupDefine.FilterType.HeroAssociatedTag
    end
end

function CommonChooseHelper.GetFilterCodeWithType(filterType, subFilterCode)
    local code = 0
    if filterType == CommonChoosePopupDefine.FilterType.Own then
        code = code | subFilterCode
    elseif filterType == CommonChoosePopupDefine.FilterType.Quality then
        code = code | (subFilterCode << 3)
    elseif filterType == CommonChoosePopupDefine.FilterType.HeroBattleType then
        code = code | (subFilterCode << CommonChoosePopupDefine.FilterTypeOffset.HeroBattleType)
    elseif filterType == CommonChoosePopupDefine.FilterType.HeroAssociatedTag then
        code = code | (subFilterCode << CommonChoosePopupDefine.FilterTypeOffset.HeroAssociatedTag)
    end
    return code
end

function CommonChooseHelper.GetSubFilterCodeByFilterCode(filterType, filterCode)
    local subFilterCode = nil
    if not filterCode then
        return subFilterCode
    end
    if filterType == CommonChoosePopupDefine.FilterType.Own then
        subFilterCode = 0x07 & filterCode
    elseif filterType == CommonChoosePopupDefine.FilterType.Quality then
        subFilterCode = 0x0f & (filterCode >> 3)
    elseif filterType == CommonChoosePopupDefine.FilterType.HeroBattleType then
        subFilterCode = 0x07 & (filterCode >> CommonChoosePopupDefine.FilterTypeOffset.HeroBattleType)
    elseif filterType == CommonChoosePopupDefine.FilterType.HeroAssociatedTag then
        subFilterCode = 0x07 & (filterCode >> CommonChoosePopupDefine.FilterTypeOffset.HeroAssociatedTag)
    end
    return subFilterCode
end

---@param filterData table<number, number> @key filterType, value subFilterCode
---@return table<number,table<number, bool>> @key filterType, value table<number, bool> @key subFilterIndex, value isSelect
function CommonChooseHelper.GetFilterStateByFilterData(filterData)
    local filterState = {}
    for filterType, subFilterCode in pairs(filterData) do
        local subFilterDefine = nil
        if filterType == CommonChoosePopupDefine.FilterType.Own then
            subFilterDefine = CommonChoosePopupDefine.OwnSubFilterTypeName
        elseif filterType == CommonChoosePopupDefine.FilterType.Quality then
            subFilterDefine = CommonChoosePopupDefine.QualitySubFilterTypeName
        elseif filterType == CommonChoosePopupDefine.FilterType.HeroBattleType then
            subFilterDefine = CommonChoosePopupDefine.HeroBattleTypeSubFilterTypeName
        elseif filterType == CommonChoosePopupDefine.FilterType.HeroAssociatedTag then
            subFilterDefine = CommonChoosePopupDefine.HeroAssociatedTagSubFilterTypeName
        end

        if subFilterDefine then
            local subFilterState = {}
            for i = 1, #subFilterDefine do
                if subFilterCode > 0 then
                    subFilterState[i] = (subFilterCode & (1 << (i - 1))) > 0
                else
                    subFilterState[i] = true
                end
            end
            filterState[filterType] = subFilterState
        end
    end
    return filterState
end

--是否拥有的筛选条件模版
function CommonChooseHelper.GetOwnSubFilterTypeList(filterType, subFilterCode, min, max)
    ---@type SubFilterParam[]
    local subFilterTypeList = {}
    local filterCode = 0
    min = min or 1
    max = max or 4
    local subFilterData1 = {
        name = I18N.Get(CommonChoosePopupDefine.OwnSubFilterTypeName[1]),
        subTypeIndex = filterType << 0,
        chooseStyle = CommonChoosePopupDefine.ChooseStyle.Dot,
        color = nil,
    }
    --此处有坑 a and b or c 并不能当做条件判断语句来使用 ex: true and false or true = true
    -- subFilterData1.isSelect = subFilterCode and (subFilterCode & subFilterData1.subTypeIndex > 0) or true
    if subFilterCode then
        subFilterData1.isSelect = subFilterCode & subFilterData1.subTypeIndex > 0
    else
        subFilterData1.isSelect = true
    end
    filterCode = subFilterData1.isSelect and filterCode | subFilterData1.subTypeIndex or filterCode
    if min <= 1 and 1 <= max then
        table.insert(subFilterTypeList, subFilterData1)
    end

    local subFilterData2 = {
        name = I18N.Get(CommonChoosePopupDefine.OwnSubFilterTypeName[2]),
        subTypeIndex = filterType << 1,
        chooseStyle = CommonChoosePopupDefine.ChooseStyle.Dot,
        color = nil,
    }
    if subFilterCode then
        subFilterData2.isSelect = subFilterCode & subFilterData2.subTypeIndex > 0
    else
        subFilterData2.isSelect = false
    end
    filterCode = subFilterData2.isSelect and filterCode | subFilterData2.subTypeIndex or filterCode
    if min <= 2 and 2 <= max then
        table.insert(subFilterTypeList, subFilterData2)
    end

    local subFilterData3 = {
        name = I18N.Get(CommonChoosePopupDefine.OwnSubFilterTypeName[3]),
        subTypeIndex = filterType << 2,
        chooseStyle = CommonChoosePopupDefine.ChooseStyle.Dot,
        color = nil,
    }
    if subFilterCode then
        subFilterData3.isSelect = subFilterCode & subFilterData3.subTypeIndex > 0
    else
        subFilterData3.isSelect = false
    end
    filterCode = subFilterData3.isSelect and filterCode | subFilterData3.subTypeIndex or filterCode
    if min <= 3 and 3 <= max then
        table.insert(subFilterTypeList, subFilterData3)
    end

    if not CommonDefaultFilterCode[filterType] then
        CommonDefaultFilterCode[filterType] = filterCode
    end
    return subFilterTypeList
end

--品质筛选条件模版
function CommonChooseHelper.GetQualitySubFilterTypeList(filterType, subFilterCode, min, max)
    ---@type SubFilterParam[]
    local subFilterTypeList = {}
    local filterCode = 0
    local offset = CommonChoosePopupDefine.FilterTypeOffset.Quality
    min = min or 1
    max = max or 4
    for i = 1, 4 do
        local subFilterData = {
            name = I18N.Get(CommonChoosePopupDefine.QualitySubFilterTypeName[i]),
            subTypeIndex = filterType << (i - 1),
            chooseStyle = CommonChoosePopupDefine.ChooseStyle.Tick,
            color = CommonChoosePopupDefine.QualitySubFilterTypeColor[i],
        }
        if subFilterCode then
            subFilterData.isSelect = subFilterCode & (subFilterData.subTypeIndex >> offset) > 0
        else
            subFilterData.isSelect = false
        end
        filterCode = subFilterData.isSelect and filterCode | subFilterData.subTypeIndex or filterCode
        if min <= i and i <= max then
            table.insert(subFilterTypeList, subFilterData)
        end
    end

    if not CommonDefaultFilterCode[filterType] then
        CommonDefaultFilterCode[filterType] = filterCode
    end
    return subFilterTypeList
end

function CommonChooseHelper.GetHeroBattleTypeSubFilterTypeList(filterType, subFilterCode, min, max)
    ---@type SubFilterParam[]
    local subFilterTypeList = {}
    local filterCode = 0
    local offset = CommonChoosePopupDefine.FilterTypeOffset.HeroBattleType
    min = min or 1
    max = max or 3
    for i = 1, 3 do
        local subFilterData = {
            name = I18N.Get(CommonChoosePopupDefine.HeroBattleTypeSubFilterTypeName[i]),
            subTypeIndex = filterType << (i - 1),
            chooseStyle = CommonChoosePopupDefine.ChooseStyle.Tick,
            -- color = CommonChoosePopupDefine.HeroBattleTypeSubFilterTypeColor[i],
            icon = CommonChoosePopupDefine.HeroBattleTypeSubFilterTypeIcon[i],
        }
        if subFilterCode then
            subFilterData.isSelect = subFilterCode & (subFilterData.subTypeIndex >> offset) > 0
        else
            subFilterData.isSelect = false
        end
        filterCode = subFilterData.isSelect and filterCode | subFilterData.subTypeIndex or filterCode
        if min <= i and i <= max then
            table.insert(subFilterTypeList, subFilterData)
        end
    end

    if not CommonDefaultFilterCode[filterType] then
        CommonDefaultFilterCode[filterType] = filterCode
    end
    return subFilterTypeList
end


function CommonChooseHelper.GetHeroAssociatedTagSubFilterTypeList(filterType, subFilterCode, min, max)
    ---@type SubFilterParam[]
    local subFilterTypeList = {}
    local filterCode = 0
    local offset = CommonChoosePopupDefine.FilterTypeOffset.HeroAssociatedTag
    min = min or 1
    max = max or 3
    for i = 1, 3 do
        local subFilterData = {
            name = I18N.Get(CommonChoosePopupDefine.HeroAssociatedTagSubFilterTypeName[i]),
            subTypeIndex = filterType << (i-1),
            chooseStyle = CommonChoosePopupDefine.ChooseStyle.Tick,
            -- color = CommonChoosePopupDefine.HeroAssociatedTagSubFilterTypeColor[i],
            icon = CommonChoosePopupDefine.HeroAssociatedTagSubFilterTypeIcon[i],
        }
        if subFilterCode then
            subFilterData.isSelect = subFilterCode & (subFilterData.subTypeIndex >> offset) > 0
        else
            subFilterData.isSelect = false
        end
        filterCode = subFilterData.isSelect and filterCode | subFilterData.subTypeIndex or filterCode
        if min <= i and i <= max then
            table.insert(subFilterTypeList, subFilterData)
        end
    end
    
    if not CommonDefaultFilterCode[filterType] then
        CommonDefaultFilterCode[filterType] = filterCode
    end
    return subFilterTypeList
end


function CommonChooseHelper.GetSubFilterTypeListByType(filterType, filterCode, min, max)
    local subFilterCode = CommonChooseHelper.GetSubFilterCodeByFilterCode(filterType, filterCode)
    if filterType == CommonChoosePopupDefine.FilterType.Own then
        return CommonChooseHelper.GetOwnSubFilterTypeList(filterType, subFilterCode, min, max)
    elseif filterType == CommonChoosePopupDefine.FilterType.Quality then
        return CommonChooseHelper.GetQualitySubFilterTypeList(filterType, subFilterCode, min, max)
    elseif filterType == CommonChoosePopupDefine.FilterType.HeroBattleType then
        return CommonChooseHelper.GetHeroBattleTypeSubFilterTypeList(filterType, subFilterCode, min, max)
    elseif filterType == CommonChoosePopupDefine.FilterType.HeroAssociatedTag then
        return CommonChooseHelper.GetHeroAssociatedTagSubFilterTypeList(filterType, subFilterCode, min, max)
    end
end

function CommonChooseHelper.GetDefaultFilterCodeByType(filterType)
    return CommonDefaultFilterCode[filterType] or -1
end


return CommonChooseHelper