using CsvHelper.Configuration.Attributes;

namespace CSVConfigReader.Formattor
{
	public sealed class ArtResource
	{
        [Name("Id")]    
		public int Id {get; set;}
        [Name("StringId")]        
        public string StringId {get; set;}
        [Name("注释")]        
        public string Note {get; set;}
        [Name("分包ID")]        
		public string PackId {get; set;}
        [Name("资源类型")]        
		public string Type {get; set;}
        [Name("资源路径")]        
		public string Path {get; set;}
        [Name("Collider高度"), Default(0f)]        
		public float CapsuleHeight {get; set;}
        [Name("Collider半径"), Default(0f)]        
		public float CapsuleRadius {get; set;}
        [Name("ColliderY轴偏移"), Default(0f)]        
		public float CapsuleYOffset {get; set;}
        [Name("NavMeshAgent类型"), Default(0)]        
		public int NmaType {get; set;}
        [Name("NavMeshAgent高度"), Default(0f)]        
		public float NmaHeight {get; set;}
        [Name("NavMeshAgent半径"), Default(0f)]        
		public float NmaRadius {get; set;}
        [Name("血条Y轴偏移"), Default(0f)]        
		public float HpYOffset {get; set;}
        [Name("SLGRVO半径"), Default(0f)]        
		public float SlgRvoRadius {get; set;}
        [Name("SLGBATTLERVO半径"), Default(0f)]        
		public float SlgRvoBattleRadius {get; set;}
        [Name("模型缩放系数"), Default(0f)]        
		public float ModelScale {get; set;}
	}
}
