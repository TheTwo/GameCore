using UnityEngine;
using System.Collections;
using UnityEditor;
using UnityEngine.UI;

public class FontSize : MonoBehaviour
{
    [MenuItem("Tools/CheckFontSize")]
    public static void CheckFontSize()
    {
        Text[] texts = Selection.gameObjects [0].GetComponentsInChildren<Text>();

        foreach (var text in texts)
        {
            if (text.fontSize != 60 || text.fontStyle != FontStyle.Normal)
            {
                Debug.Log(text.name);
            }
        }
    }
}
