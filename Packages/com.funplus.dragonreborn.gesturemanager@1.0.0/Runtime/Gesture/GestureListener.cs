//#define DEBUG_GESTURE

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DragonReborn
{
	public class GestureListener : IGestureListener
	{
		public virtual void OnPressDown(TapGesture gesture)
		{
			
		}
		public virtual void OnPress (TapGesture gesture)
		{
			#if DEBUG_GESTURE
			Logger.Log ("OnPress");
			#endif
		}

		public virtual void OnRelease (TapGesture gesture)
		{
			#if DEBUG_GESTURE
			Logger.Log ("OnRelease");
			#endif
		}

		public virtual void OnClick (TapGesture gesture)
		{
			#if DEBUG_GESTURE
			Logger.Log ("OnClick");
			#endif
		}

		public virtual void OnDrag(DragGesture gesture)
		{
			#if DEBUG_GESTURE
			Logger.Log ("OnDrag:" + gesture.delta);
			#endif
		}

		public virtual void OnPinch(PinchGesture gesture)
		{
			#if DEBUG_GESTURE
			Logger.Log ("OnPinch:" + gesture.delta);
			#endif
		}

		public void OnUIElementTouchUp(UITapGesture gesture)
		{
			#if DEBUG_GESTURE
			Logger.Log ("OnUIElementTouchUp:" + gesture.delta);
			#endif
		}
	}
}