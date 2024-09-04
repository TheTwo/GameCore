namespace DragonReborn
{
	public interface IGestureListener
	{
		void OnPressDown(TapGesture gesture);
		void OnPress (TapGesture gesture);
		void OnRelease (TapGesture gesture);
		void OnClick (TapGesture gesture);
		void OnDrag (DragGesture gesture);
		void OnPinch (PinchGesture gesture);
		void OnUIElementTouchUp(UITapGesture gesture);
	}
}