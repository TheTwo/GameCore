using UnityEngine;

namespace DragonReborn
{
	[UnityEngine.Scripting.RequireDerived]
	public class MonoSingleton<T> : MonoBehaviour where T : MonoBehaviour
	{
		private static T _instance = null;

        public static bool IsValid => _instance != null;

		public static T Instance
		{
			get
			{
				if (null == _instance)
				{
					_instance = FindObjectOfType<T>();
				}
				
				if (null == _instance)
				{
					var go = new GameObject(typeof(T).ToString());
					_instance = go.AddComponent<T>();
				}

				return _instance;
			}
		}

		private void Awake()
		{
			DontDestroyOnLoad(gameObject);

			_instance = this as T;
		}

		private void OnDestroy()
		{
			_instance = null;
		}
	}
}