using CsvHelper.Configuration.Attributes;

namespace CSVConfigReader.Formattor
{
	public sealed class BuildingLevels
	{
        [Name("Id"), Default(0)]
		public int Id {get; set;}
        [Name("StringId")]
        public string StringId {get; set;}
        [Name("注释")]
        public string Note {get; set;}
        [Name("等级"), Default(0)]
        public int Level {get; set;}
        [Name("下一等级"), Default("")]
        public string NextLevel {get; set;}
        [Name("类型")]
        public string Type {get; set;}
        [Name("描述")]
        public string Description {get; set;}
        [Name("尺寸（X）"), Default(0)]
        public int SizeX {get; set;}
        [Name("尺寸（Y）"), Default(0)]
        public int SizeY {get; set;}
        [Name("室内基准点x 坐标"), Default(0)]
        public int InnerPosX {get; set;}
        [Name("室内基准点y 坐标"), Default(0)]
        public int InnerPosY {get; set;}
        [Name("室内尺寸（X）"), Default(0)]
        public int InnerSizeX {get; set;}
        [Name("室内尺寸（Y）"), Default(0)]
        public int InnerSizeY {get; set;}
        [Name("升级效果描述"), Default("")]
        public string UpdataDescription {get; set;}
        [Name("发现前置条件1建筑类型"), Default("")]
        public string ShowPrecondition1BuildingType {get; set;}
        [Name("发现前置条件1等级"), Default(0)]
        public int ShowPrecondition1Level {get; set;}
        [Name("发现前置条件1数量"), Default(0)]
        public int ShowPrecondition1Count {get; set;}
        [Name("发现前置条件2建筑类型"), Default("")]
        public string ShowPrecondition2BuildingType {get; set;}
        [Name("发现前置条件2等级"), Default(0)]
        public int ShowPrecondition2Level {get; set;}
        [Name("发现前置条件2数量"), Default(0)]
        public int ShowPrecondition2Count {get; set;}
        [Name("发现前置条件3建筑类型"), Default("")]
        public string ShowPrecondition3BuildingType {get; set;}
        [Name("发现前置条件3等级"), Default(0)]
        public int ShowPrecondition3Level {get; set;}
        [Name("发现前置条件3数量"), Default(0)]
        public int ShowPrecondition3Count {get; set;}
        [Name("解锁前置条件1建筑类型"), Default("")]
        public string UnlockPrecondition1BuildingType {get; set;}
        [Name("解锁前置条件1等级"), Default(0)]
        public int UnlockPrecondition1Level {get; set;}
        [Name("解锁前置条件1数量"), Default(0)]
        public int UnlockPrecondition1Count {get; set;}
        [Name("解锁前置条件2建筑类型"), Default("")]
        public string UnlockPrecondition2BuildingType {get; set;}
        [Name("解锁前置条件2等级"), Default(0)]
        public int UnlockPrecondition2Level {get; set;}
        [Name("解锁前置条件2数量"), Default(0)]
        public int UnlockPrecondition2Count {get; set;}
        [Name("解锁前置条件3建筑类型"), Default("")]
        public string UnlockPrecondition3BuildingType {get; set;}
        [Name("解锁前置条件3等级"), Default(0)]
        public int UnlockPrecondition3Level {get; set;}
        [Name("解锁前置条件3数量"), Default(0)]
        public int UnlockPrecondition3Count {get; set;}
        [Name("消耗"), Default("")]
        public string CostItemGroupCfgId {get; set;}
        [Name("建设时间"), Default("")]
        public string BuildDuration {get; set;}
        [Name("装饰上限1家具类型"), Default("")]
        public string FurnitureLimits1FurnitureType {get; set;}
        [Name("装饰上限1数量"), Default(0)]
        public int FurnitureLimits1Count {get; set;}
        [Name("装饰上限1互斥家具类型"), Default("")]
        public string[] FurnitureLimits1incompatibility {get; set;}
        [Name("装饰上限2家具类型"), Default("")]
        public string FurnitureLimits2FurnitureType {get; set;}
        [Name("装饰上限2数量"), Default(0)]
        public int FurnitureLimits2Count {get; set;}
        [Name("装饰上限2互斥家具类型"), Default("")]
        public string[] FurnitureLimits2incompatibility {get; set;}
        [Name("装饰上限3家具类型"), Default("")]
        public string FurnitureLimits3FurnitureType {get; set;}
        [Name("装饰上限3数量"), Default(0)]
        public int FurnitureLimits3Count {get; set;}
        [Name("装饰上限3互斥家具类型"), Default("")]
        public string FurnitureLimits3incompatibility {get; set;}
        [Name("装饰上限4家具类型"), Default("")]
        public string FurnitureLimits4FurnitureType {get; set;}
        [Name("装饰上限4数量"), Default(0)]
        public int FurnitureLimits4Count {get; set;}
        [Name("装饰上限4互斥家具类型"), Default("")]
        public string FurnitureLimits4incompatibility {get; set;}
        [Name("装饰上限5家具类型"), Default("")]
        public string FurnitureLimits5FurnitureType {get; set;}
        [Name("装饰上限5数量"), Default(0)]
        public int FurnitureLimits5Count {get; set;}
        [Name("装饰上限5互斥家具类型"), Default("")]
        public string FurnitureLimits5incompatibility {get; set;}
        [Name("增加装饰1家具类型"), Default("")]
        public string FurnitureAdds1FurnitureType {get; set;}
        [Name("增加装饰1坐标x 坐标"), Default(0)]
        public int FurnitureAdds1PosX {get; set;}
        [Name("增加装饰1坐标y 坐标"), Default(0)]
        public int FurnitureAdds1PosY {get; set;}
        [Name("增加装饰2家具类型"), Default("")]
        public string FurnitureAdds2FurnitureType {get; set;}
        [Name("增加装饰2坐标x 坐标"), Default(0)]
        public int FurnitureAdds2PosX {get; set;}
        [Name("增加装饰2坐标y 坐标"), Default(0)]
        public int FurnitureAdds2PosY {get; set;}
        [Name("增加装饰3家具类型"), Default("")]
        public string FurnitureAdds3FurnitureType {get; set;}
        [Name("增加装饰3坐标x 坐标"), Default(0)]
        public int FurnitureAdds3PosX {get; set;}
        [Name("增加装饰3坐标y 坐标"), Default(0)]
        public int FurnitureAdds3PosY {get; set;}
        [Name("增加装饰4家具类型"), Default("")]
        public string FurnitureAdds4FurnitureType {get; set;}
        [Name("增加装饰4坐标x 坐标"), Default(0)]
        public int FurnitureAdds4PosX {get; set;}
        [Name("增加装饰4坐标y 坐标"), Default(0)]
        public int FurnitureAdds4PosY {get; set;}
        [Name("增加装饰5家具类型"), Default("")]
        public string FurnitureAdds5FurnitureType {get; set;}
        [Name("增加装饰5坐标x 坐标"), Default(0)]
        public int FurnitureAdds5PosX {get; set;}
        [Name("增加装饰5坐标y 坐标"), Default(0)]
        public int FurnitureAdds5PosY {get; set;}
        [Name("家具组合"), Default("")]
        public string FurnitureCombinations {get; set;}
        [Name("获得能力"), Default("")]
        public string AbilityReward {get; set;}
        [Name("模型美术资源"), Default("")]
        public string ModelArtRes {get; set;}
        [Name("建造动作"), Default("")]
        public string ConstructAction {get; set;}
        [Name("交互位置"), Default("")]
        public string CollectPos {get; set;}
        [Name("入口所在墙面"), Default(0)]
        public int EntryWall {get; set;}
        [Name("入口所在位置"), Default(0f)]
        public float EntryOffset {get; set;}
	}
}
