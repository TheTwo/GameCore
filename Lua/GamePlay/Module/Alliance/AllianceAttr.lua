local CityAttrType = require("CityAttrType")

---@class AllianceAttr
local AllianceAttr = {}

AllianceAttr.Currency_Fund_Speed = 2002

AllianceAttr.Currency_Wood_Speed = 2004
AllianceAttr.Currency_Wood_Limit = 2003

AllianceAttr.Currency_Iron_Speed = 2006
AllianceAttr.Currency_Iron_Limit = 2005

AllianceAttr.Currency_Food_Speed = 2008
AllianceAttr.Currency_Food_Limit = 2007

AllianceAttr.Currency_WarCard_Speed = 2010
AllianceAttr.Currency_WarCard_Limit = 2009

AllianceAttr.Currency_BuildCard_Speed = 2062
AllianceAttr.Currency_BuildCard_Limit = 2061

-- 联盟货币增量时间间隔
AllianceAttr.Currency_Time_Interval = 2001

-- 联盟科技升级耗时
AllianceAttr.Tech_Upgrade_Time_Cost_multi = 2011
AllianceAttr.Tech_Upgrade_Time_Cost_point = 2012

-- 联盟科技升级消耗资源
AllianceAttr.Tech_Upgrade_Currency_Cost_multi = 2013
AllianceAttr.Tech_Upgrade_Currency_Cost_point = 2014

-- 联盟能量塔建造上限
AllianceAttr.EnergyTower_Lv_1_Count_Limit = 2024
AllianceAttr.EnergyTower_Lv_2_Count_Limit = 2025
AllianceAttr.EnergyTower_Lv_3_Count_Limit = 2026
AllianceAttr.EnergyTower_Lv_4_Count_Limit = 2027
AllianceAttr.EnergyTower_Lv_5_Count_Limit = 2028

-- 联盟防御塔建造上限
AllianceAttr.DefenceTower_Lv_1_Count_Limit = 2029
AllianceAttr.DefenceTower_Lv_2_Count_Limit = 2030
AllianceAttr.DefenceTower_Lv_3_Count_Limit = 2031
AllianceAttr.DefenceTower_Lv_4_Count_Limit = 2032
AllianceAttr.DefenceTower_Lv_5_Count_Limit = 2033

AllianceAttr.Help_SpeedUp_Time = CityAttrType.AllianceHelpsTime

return AllianceAttr