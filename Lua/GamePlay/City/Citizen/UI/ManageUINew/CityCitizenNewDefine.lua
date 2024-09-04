local CityCitizenNewDefine = {}

CityCitizenNewDefine.ManageToggleType = {
    Free = 1 << 0,
    Working = 1 << 1,
}
CityCitizenNewDefine.ManageToggleType.All = table.sumValues(CityCitizenNewDefine.ManageToggleType)

return CityCitizenNewDefine