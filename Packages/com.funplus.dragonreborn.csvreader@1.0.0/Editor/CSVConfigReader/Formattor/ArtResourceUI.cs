using CsvHelper.Configuration.Attributes;

namespace CSVConfigReader.Formattor
{
	public sealed class ArtResourceUI
	{
		[Name("Id")]
		public int Id
		{
			get; set;
		}
		[Name("StringId")]
		public string StringId
		{
			get; set;
		}
		[Name("注释")]
		public string Note
		{
			get; set;
		}
		[Name("分包ID")]
		public string PackId
		{
			get; set;
		}
		[Name("资源类型")]
		public string Type
		{
			get; set;
		}
		[Name("资源名称")]
		public string Path
		{
			get; set;
		}
	}
}
