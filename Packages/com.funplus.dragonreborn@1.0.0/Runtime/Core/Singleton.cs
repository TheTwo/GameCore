namespace DragonReborn
{
	[UnityEngine.Scripting.RequireDerived]
	public class Singleton<T> where T : class ,new()
	{
        private static readonly object Locker = new object();

		private static T _instance;

		public static T Instance
		{
			get
			{
                lock(Locker)
                {
	                return _instance ??= new T();
                }
			}
		}

		public static void DestroyInstance()
		{
			lock (Locker)
			{
				_instance = null;
			}
		}
	}
}