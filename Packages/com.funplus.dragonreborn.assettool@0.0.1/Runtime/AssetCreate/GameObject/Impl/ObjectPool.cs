using System.Collections.Generic;

namespace DragonReborn.AssetTool
{
	public class ObjectPool<T> where T:class, new()
	{
		private readonly Stack<T> m_Pool = new Stack<T>();

		// allocate an object
		public T Allocate()
		{
			return m_Pool.Count > 0 ? m_Pool.Pop () : new T();
		}

		// release an object
		public void Release(T o)
		{
			if (o == null)
			{
				return;
			}

			m_Pool.Push(o);
		}

		public void Clear()
		{
			m_Pool.Clear();	
		}

        public int CacheSize => m_Pool.Count;
	}
}