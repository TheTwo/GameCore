using UnityEngine;

namespace DragonReborn.AssetTool
{
	public abstract class BaseRefCounter : IRefCounter
	{
		protected int _referenceCount;

		public virtual void Increase(string log = "")
		{
			_referenceCount++;
		}

		public virtual bool Decrease(string log = "")
		{
			_referenceCount--;
			if (_referenceCount <= 0)
			{
				_referenceCount = 0;
				return true;
			}

			return false;
		}

		public int GetRefCount()
		{
			return _referenceCount;
		}

		public void ResetRefCount()
		{
			_referenceCount = 0;
		}
    }
}
