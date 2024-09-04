-- 使用ConfigRefer获取表格Wrap
local ConfigRefer = require("ConfigRefer");

-- 表名与fbs名相同即可
local itemConfig = ConfigRefer.Item;

-- 通过索引获取表格，idx从1开始
local item1 = itemConfig:Cfgs(1);
assert(item1:Name() == "刀（一级）")
assert(item1:Icon() == "10001")

-- 通过id索引表内容
local item2 = itemConfig:Find(2)
assert(item2:Name() == "刀（二级）")
assert(itemConfig.length == 2)

-- 常量表视为一维表，直接操作列字段
local TeamConsts = ConfigRefer.TeamConsts;
assert(TeamConsts:InviteSeconds() == 0)
assert(TeamConsts:ApplySeconds() == 0)

-- 空表
local empty = ConfigRefer.Npc;
assert(empty.length == 0)

-- 通过封装的ipairs()函数遍历表格
for i, v in itemConfig:ipairs() do
    print(i, v:Name());
end

print("test over");