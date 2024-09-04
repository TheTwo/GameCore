using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.EventSystems;

public class TouchPan : MonoBehaviour, IPointerDownHandler, IPointerUpHandler,
		IScrollHandler
{
	protected Vector2 lastFrameTouchPos;
	protected PointerEventData touch;
	protected int fingetId1 = -1;
	protected int fingetId2 = -1;

	public float gustureZoomSensitivity = -1f;

	public bool isInGestureZoom = false;

	public Action<float> actionZoom;


	public Vector2 pos
	{
		get
		{
			if (touch != null)
			{
				return touch.position;
			}
			return lastFrameTouchPos;
		}
	}

	public static TouchPan Get(GameObject go)
	{
		var listener = go.GetComponent<TouchPan>();
		if (listener == null)
		{
			listener = go.AddComponent<TouchPan>();
		}

		return listener;
	}

	public void OnPointerDown(PointerEventData eventData)
	{
		OnActionPress(eventData);
	}

	public void OnPointerUp(PointerEventData eventData)
	{
		OnActionRelease(eventData);
	}

	private void OnActionPress(PointerEventData eventData)
	{
		if (touch == null)
		{
			touch = eventData;
			lastFrameTouchPos = touch.position;
		}
		if (fingetId1 == -1)
		{
			fingetId1 = eventData.pointerId;
		}
		else if (fingetId2 == -1)
		{
			fingetId2 = eventData.pointerId;
		}
		if (fingetId1 != -1 && fingetId2 != -1)
		{
			isInGestureZoom = true;
		}
	}

	private void OnActionRelease(PointerEventData eventData)
	{
		if (touch == eventData)
		{
			touch = null;
		}
		if (fingetId1 == eventData.pointerId)
		{
			fingetId1 = -1;
		}
		else if (fingetId2 == eventData.pointerId)
		{
			fingetId2 = -1;
		}
		if (fingetId1 == -1 || fingetId2 == -1)
		{
			isInGestureZoom = false;
		}
	}

	public void OnScroll(PointerEventData eventData)
	{
		if (actionZoom != null) actionZoom(eventData.scrollDelta.y);
	}

	private void Update()
	{
		if (isInGestureZoom)
		{
			int tempId1 = Finget2Point(fingetId1);
			int tempId2 = Finget2Point(fingetId2);
			if (tempId1 != -1 && tempId2 != -1)
			{
				Touch touch1 = Input.GetTouch(tempId1);
				Touch touch2 = Input.GetTouch(tempId2);
				if (actionZoom != null)
				{
					float lastDistance = Vector2.Distance((touch1.position - touch1.deltaPosition),
						(touch2.position - touch2.deltaPosition));
					float nowDistance = Vector2.Distance(touch1.position, touch2.position);
					float distance = (nowDistance - lastDistance) * gustureZoomSensitivity;
					actionZoom(distance);

				}
			}
			else
			{
				isInGestureZoom = false;
			}
		}
		if (touch != null)
		{
			lastFrameTouchPos = touch.position;
		}
	}

	private int Finget2Point(int fingetId)
	{
		for (int i = 0; i < Input.touchCount; i++)
		{
			if (Input.GetTouch(i).fingerId == fingetId)
			{
				return i;
			}
		}
		return -1;
	}

	void OnDisable()
	{
		touch = null;
		fingetId1 = -1;
		fingetId2 = -1;
		isInGestureZoom = false;
	}

	public void OnDestroy()
	{
		actionZoom = null;
	}
}
