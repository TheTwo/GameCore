using DragonReborn;
using XLua;

public class LuaGestureListener : IGestureListener
{
    private readonly LuaTable _table;
    private readonly LuaFunction _onPressDown;
    private readonly LuaFunction _onPress;
    private readonly LuaFunction _onRelease;
    private readonly LuaFunction _onClick;
    private readonly LuaFunction _onDrag;
    private readonly LuaFunction _onPinch;
    private readonly LuaFunction _onUITouchUp;

    public LuaGestureListener(LuaTable table)
    {
        _table = table;
        _onPressDown = table.FastGetFunction("OnPressDown");
        _onPress = table.FastGetFunction("OnPress");
        _onRelease = table.FastGetFunction("OnRelease");
        _onClick = table.FastGetFunction("OnClick");
        _onDrag = table.FastGetFunction("OnDrag");
        _onPinch = table.FastGetFunction("OnPinch");
        _onUITouchUp = table.FastGetFunction("OnUITouchUp");
    }
    public void OnPressDown(TapGesture gesture)
    {
        _onPressDown?.Action(_table, gesture);
    }
    public void OnPress(TapGesture gesture)
    {
        _onPress?.Action(_table, gesture);
    }

    public void OnRelease(TapGesture gesture)
    {
        _onRelease?.Action(_table, gesture);
    }

    public void OnClick(TapGesture gesture)
    {
        _onClick?.Action(_table, gesture);
    }

    public void OnDrag(DragGesture gesture)
    {
        _onDrag?.Action(_table, gesture);
    }

    public void OnPinch(PinchGesture gesture)
    {
        _onPinch?.Action(_table, gesture);
    }

    public void OnUIElementTouchUp(UITapGesture gesture)
    {
	    _onUITouchUp?.Action(_table, gesture);
    }
}