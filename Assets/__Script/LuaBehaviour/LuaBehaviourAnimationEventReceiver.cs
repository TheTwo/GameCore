using System;
using UnityEngine.Scripting;
using XLua;

// ReSharper disable once CheckNamespace
namespace DragonReborn
{
	public class LuaBehaviourAnimationEventReceiver : LuaBehaviour
	{
		private Action<LuaTable,string> _onAnimationEvent; 
		protected override bool LoadScript()
		{
			var isLoad = base.LoadScript();
			if (isLoad)
			{
				Instance?.Get(nameof(OnAnimationEvent), out _onAnimationEvent);
			}
			return isLoad;
		}
		
		protected override void Cleanup()
		{
			_onAnimationEvent = null;
			base.Cleanup();
		}

		[Preserve]
		private void OnAnimationEvent(string parameter)
		{
			_onAnimationEvent?.Invoke(Instance, parameter);
		}
	}
}
