using System;
using System.Collections;
using System.Collections.Generic;
using Screen = UnityEngine.Device.Screen;
using UnityEngine;

public class CameraSize : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    private void OnEnable()
    {
        // 根据屏幕大小，调整 camera 的 size
        // iphone12 pro: 2532 x 1170
        var size = Screen.height / (2532.0f / 1170.0f * Screen.width) * 13.5f;
        Camera.main.orthographicSize = size;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
