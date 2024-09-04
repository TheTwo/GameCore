//#define DEBUG_GESTURE
//#define DEBUG_GESTURE_DRAG

using System;
using HedgehogTeam.EasyTouch;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

namespace DragonReborn
{
	public class GestureManager : MonoSingleton<GestureManager>, IManager
    {
        private readonly PointerEventData _pointerEventData = new PointerEventData(EventSystem.current);
        private readonly List<RaycastResult> _rayCastResults = new List<RaycastResult>();

        private readonly List<IGestureListener> _listeners = new List<IGestureListener>();
        private bool _pinching;
        private bool _dragging;
        private int _ignoreLayer;
        
        private const float ScrollFactor = 30;

        public bool enable
        {
            set => EasyTouch.instance.enable = value;

            get => EasyTouch.instance.enable;
        }

        public bool EnableMouseScroll { get; set; }

        public void Reset()
        {
            Clear();
            InitEasyTouch();
            
#if UNITY_EDITOR || UNITY_STANDALONE_OSX || UNITY_STANDALONE_WIN
            EnableMouseScroll = true;
#endif
        }

        private void Clear()
        {
            _listeners.Clear();
            _ignoreLayer = 0;
            _pinching = false;
            _dragging = false;
            
            EasyTouch.On_TouchStart -= OnPressDown;
            EasyTouch.On_TouchDown -= OnPress;
            EasyTouch.On_TouchUp -= OnRelease;
            EasyTouch.On_SimpleTap -= OnClick;
            EasyTouch.On_Pinch -= OnPinch;
            EasyTouch.On_SwipeStart -= OnSwipeStart;
            EasyTouch.On_Swipe -= OnSwipe;
            EasyTouch.On_SwipeEnd -= OnSwipeEnd;
            EasyTouch.On_OverUIElement -= OnOverUIElement;
            EasyTouch.On_UIElementTouchUp -= OnUIElementTouchUp;
        }

        private void InitEasyTouch()
        {
	        EasyTouch.instance.doubleTapDetection = EasyTouch.DoubleTapDetection.ByTime;
	        EasyTouch.instance.doubleTapTime = 0f;
	        EasyTouch.instance.enableTwist = false;
            EasyTouch.On_TouchStart += OnPressDown;
            EasyTouch.On_TouchDown += OnPress;
            EasyTouch.On_TouchUp += OnRelease;
            EasyTouch.On_SimpleTap += OnClick;
            EasyTouch.On_Pinch += OnPinch;
            EasyTouch.On_SwipeStart += OnSwipeStart;
            EasyTouch.On_Swipe += OnSwipe;
            EasyTouch.On_SwipeEnd += OnSwipeEnd;
            EasyTouch.On_OverUIElement += OnOverUIElement;
            EasyTouch.On_UIElementTouchUp += OnUIElementTouchUp;
        }

        public void AddIgnoreLayer(int layer)
        {
            int mask = 1 << layer;
            _ignoreLayer |= mask;

	        EasyTouch.instance.uGUILayers = _ignoreLayer;
        }

        public void RemoveIgnoreLayer(int layer)
        {
            int mask = 1 << layer;
            _ignoreLayer &= (~mask);

            EasyTouch.instance.uGUILayers = _ignoreLayer;
        }

        public void AddListener(IGestureListener listener)
        {
            if (listener == null)
            {
                Log("AddListener: listener can not be null.");
                return;
            }

            _listeners.Add(listener);
        }

        public void RemoveListener(IGestureListener listener)
        {
            _listeners.Remove(listener);
        }

        public void SimulateClick()
        {
            var tapGesture = new TapGesture
            {
                position = Input.mousePosition
            };

            var invokes = _listeners.GetRange(0, _listeners.Count);
            foreach (var listener in invokes)
            {
                listener.OnClick(tapGesture);
            }
        }

        public void SimulateClick(Vector3 screenPos)
        {
	        var tapGesture = new TapGesture
	        {
		        position = screenPos
	        };

	        var invokes = _listeners.GetRange(0, _listeners.Count);
	        foreach (var listener in invokes)
	        {
		        listener.OnClick(tapGesture);
	        }
        }

        public Vector3 GetCurrentPosition()
        {
            return Input.mousePosition;
        }

        public bool IsPointerOverGameObject(Vector2 screenPosition)
        {
            // 清空射线相交结果
            _rayCastResults.Clear();

            //将点击位置的屏幕坐标赋值给点击事件  
            _pointerEventData.position = new Vector2(screenPosition.x, screenPosition.y);

            //向点击处发射射线
            try
            {
                if (EventSystem.current)
                {
                    EventSystem.current.RaycastAll(_pointerEventData, _rayCastResults);
                }
            }
            catch (Exception e)
            {
                NLogger.TraceChannel("GestureManager", "[GestureManager] IsPointerOverGameObject: {0}", e);
            }

            var count = 0;
            foreach (var result in _rayCastResults)
            {
                var layer = result.gameObject.layer;
                var mask = 1 << layer;
                if ((_ignoreLayer & mask) != mask)
                {
                    ++count;
                }
            }

            return count > 0;
        }

        // Gesture Events
        private void OnPressDown(Gesture current)
        {
            var tapGesture = new TapGesture
            {
                position = current.position
            };

            var invokes = _listeners.GetRange(0, _listeners.Count);
            foreach (var listener in invokes)
            {
                listener.OnPressDown(tapGesture);
            }
        }
        
        private void OnPress(Gesture current)
        {
            var tapGesture = new TapGesture
            {
                position = current.position
            };

            var invokes = _listeners.GetRange(0, _listeners.Count);
            foreach (var listener in invokes)
            {
                listener.OnPress(tapGesture);
            }
        }

        private void OnRelease(Gesture current)
        {
            var tapGesture = new TapGesture
            {
                position = current.position
            };

            var invokes = _listeners.GetRange(0, _listeners.Count);
            foreach (var listener in invokes)
            {
                listener.OnRelease(tapGesture);
            }

            if (_pinching)
            {
                _pinching = false;

                var pinchGesture = new PinchGesture
                {
                    position = current.position,
                    phase = GesturePhase.Ended,
                    delta = current.deltaPinch
                };

                Log("OnPinch: Ended - Delta = {0}", pinchGesture.delta);

                foreach (var listener in invokes)
                {
                    listener.OnPinch(pinchGesture);
                }
            }
        }

        private void OnClick(Gesture current)
        {
            var tapGesture = new TapGesture();
            tapGesture.position = current.position;

            var invokes = _listeners.GetRange(0, _listeners.Count);
            foreach (var listener in invokes)
            {
                listener.OnClick(tapGesture);
            }
        }

        private void OnPinch(Gesture current)
        {
            var pinchGesture = new PinchGesture();
            pinchGesture.position = current.position;
            
            var invokes = _listeners.GetRange(0, _listeners.Count);
            if (!_pinching)
            {
                _pinching = true;
                pinchGesture.phase = GesturePhase.Started;
                pinchGesture.delta = current.deltaPinch;

                Log("OnPinch: Started - Delta = {0}", pinchGesture.delta);

                foreach (var listener in invokes)
                {
                    listener.OnPinch(pinchGesture);
                }
            }
            else
            {
                pinchGesture.phase = GesturePhase.Updated;
                pinchGesture.delta = current.deltaPinch;

                Log("OnPinch: Updated - Delta = {0}", pinchGesture.delta);

                foreach (var listener in invokes)
                {
                    listener.OnPinch(pinchGesture);
                }
            }
        }

        private void OnSwipeStart(Gesture current)
        {
            if (current.touchCount == 1)
            {
#if DEBUG_GESTURE_DRAG
	            Log("OnDrag: Started");
#endif

	            _dragging = false;

                var dragGesture = new DragGesture
                {
                    phase = GesturePhase.Started,
                    position = current.position,
                    lastPosition = current.position - current.deltaPosition,
                    delta = current.deltaPosition
                };

                var invokes = _listeners.GetRange(0, _listeners.Count);
                foreach (var listener in invokes)
                {
                    listener.OnDrag(dragGesture);
                }
            }
        }

        private void OnSwipe(Gesture current)
        {
	        if (current.touchCount == 1)
	        {
		        if (current.deltaPosition.sqrMagnitude > 0)
		        {
			        _dragging = true;

			        var dragGesture = new DragGesture
			        {
				        phase = GesturePhase.Updated,
				        position = current.position,
				        lastPosition = current.position - current.deltaPosition,
				        delta = current.deltaPosition,
			        };

#if DEBUG_GESTURE_DRAG
                    Log("OnDrag: Updated - Last = {0}, Current = {1}, Delta = {2}",
                        dragGesture.lastPosition, dragGesture.position, dragGesture.delta);
#endif

			        var invokes = _listeners.GetRange(0, _listeners.Count);
			        foreach (var listener in invokes)
			        {
				        listener.OnDrag(dragGesture);
			        }
		        }
		        else
		        {
			        if (_dragging)
			        {
#if DEBUG_GESTURE_DRAG
						Log("OnDrag: Pause");
#endif
				        var dragGesture = new DragGesture
				        {
					        phase = GesturePhase.Pause,
					        position = current.position,
					        lastPosition = current.position - current.deltaPosition,
					        delta = current.deltaPosition,
				        };

				        var invokes = _listeners.GetRange(0, _listeners.Count);
				        foreach (var listener in invokes)
				        {
					        listener.OnDrag(dragGesture);
				        }

				        _dragging = false;
			        }
		        }
	        }
        }

        private void OnSwipeEnd(Gesture current)
        {
            if (current.touchCount == 1)
            {
#if DEBUG_GESTURE_DRAG
                Log("OnDrag: Ended");
#endif

                var dragGesture = new DragGesture
                {
                    phase = GesturePhase.Ended,
                    position = current.position,
                    lastPosition = current.position - current.deltaPosition,
                    delta = current.deltaPosition
                };

                var invokes = _listeners.GetRange(0, _listeners.Count);
                foreach (var listener in invokes)
                {
                    listener.OnDrag(dragGesture);
                }

                _dragging = false;
            }
        }

        private void OnOverUIElement(Gesture gesture)
        {
	        //TODO
        }

        private void OnUIElementTouchUp(Gesture gesture)
        {
	        if (gesture.touchCount == 1)
	        {
#if DEBUG_GESTURE_DRAG
                Log("OnDrag: Ended");
#endif

		        var uiTapGesture = new UITapGesture()
		        {
			        tapGameObj = gesture.pickedUIElement
		        };

		        var invokes = _listeners.GetRange(0, _listeners.Count);
		        foreach (var listener in invokes)
		        {
			        listener.OnUIElementTouchUp(uiTapGesture);
		        }
	        }
        }

        private bool _scrolling;
        private void Update()
        {
            if (EnableMouseScroll)
            {
                HandleMouseScroll();
            }
        }

#if UNITY_EDITOR
        private static System.Func<UnityEditor.EditorWindow, bool> _contains;
        private bool _lastCanScroll;
        
        private static bool CheckCanScroll()
        {
            var w = UnityEditor.EditorWindow.focusedWindow;
            if (!w) return false;
            if (w != UnityEditor.EditorWindow.mouseOverWindow) return false;
            if (_contains != null) return null != _contains && _contains(w);
            var playView = typeof(UnityEditor.EditorWindow).Assembly.GetType("UnityEditor.PlayModeView");
            if (null == playView) return null != _contains && _contains(w);
            var container = playView.GetField("s_PlayModeViews", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Public);
            if (null == container) return null != _contains && _contains(w);
            if (container.GetValue(null) is System.Collections.IList sPlayModeViews)
            {
                _contains = window => sPlayModeViews.Contains(window);
            }
            return null != _contains && _contains(w);
        }
#endif
        
        private void HandleMouseScroll()
        {
            if (!enable)
            {
                return;
            }

            if (IsPointerOverGameObject(Input.mousePosition))
            {
                return;
            }

            //////////////////////////////////////////////////
            // Scroll
            //////////////////////////////////////////////////
            var scrollGesture = new PinchGesture();
            var scrollData = Input.mouseScrollDelta.y * ScrollFactor;
            
#if UNITY_EDITOR
	        var canScroll = CheckCanScroll();
	        if (!canScroll || !_lastCanScroll)
	        {
		        scrollData = 0;
	        }

	        _lastCanScroll = canScroll;
#endif
	            
	        if (Mathf.Abs(scrollData) > GestureUtils.PinchTolerance)
            {
                if (!_scrolling)
                {
                    _scrolling = true;
                    scrollGesture.phase = GesturePhase.Started;
                }
                else
                {
                    scrollGesture.phase = GesturePhase.Updated;
                }

                scrollGesture.position = Input.mousePosition;
                scrollGesture.delta = scrollData;

                var invokes = _listeners.GetRange(0, _listeners.Count);
                foreach (var listener in invokes)
                {
                    listener.OnPinch(scrollGesture);
                }
            }
            else
            {
                if (_scrolling)
                {
                    _scrolling = false;

                    scrollGesture.phase = GesturePhase.Ended;
                    scrollGesture.position = Input.mousePosition;
                    scrollGesture.delta = 0f;

                    var invokes = _listeners.GetRange(0, _listeners.Count);
                    foreach (var listener in invokes)
                    {
                        listener.OnPinch(scrollGesture);
                    }
                }
            }
        }

        private static void Log(string log, params object[] args)
        {
#if DEBUG_GESTURE
            NLogger.TraceChannel("GestureManager", log, args);
#endif
        }

        public void OnGameInitialize(object configParam)
        {
            Reset();
        }

        [System.Diagnostics.Conditional("UNITY_EDITOR")]
        public void OnDestroy()
        {
#if UNITY_EDITOR
            Clear();       
#endif   
        }

		public void OnLowMemory()
		{

		}
        
        public bool IsFingerOverUI(int fingerIndex)
        {
            return EasyTouch.IsFingerOverUIElement(fingerIndex);
        }
	}
}
