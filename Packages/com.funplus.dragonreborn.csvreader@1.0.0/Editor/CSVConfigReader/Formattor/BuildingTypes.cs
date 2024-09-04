using CsvHelper.Configuration.Attributes;

namespace CSVConfigReader.Formattor
{
	public sealed class BuildingTypes
	{
		[Name("Id")]
		public int Id { get; set; }
		[Name("StringId")]
		public string StringId{ get; set; }
		[Name("注释")]
		public string Note{ get; set; }
		[Name("类型")]
		public string Type{ get; set; }
		[Name("大类")]
		public string Catagory{ get; set; }
		[Name("显示排序")]
		public int DisplaySort{ get; set; }
		[Name("名称")]
		public string Name{ get; set; }
		[Name("大写名称")]
		public string UpperCaseName{ get; set; }
		[Name("描述")]
		public string Description{ get; set; }
		[Name("简述")]
		public string BriefDescription{ get; set; }
		[Name("图片")]
		public string Image{ get; set; }
		[Name("繁荣度界面图片")]
		public string ProsperityUiImage{ get; set; }
		[Name("未解锁外观")]
		public string UnlockAppearance{ get; set; }
		[Name("是否可以移动")]
		public bool Moveable{ get; set; }
		[Name("最大数量")]
		public int MaxNum{ get; set; }
		[Name("最大等级")]
		public int MaxLevel{ get; set; }
	}
}
