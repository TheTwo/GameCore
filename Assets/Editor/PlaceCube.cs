using UnityEngine;
using System.Collections;
using UnityEditor;

public class PlaceCube : MonoBehaviour
{
    [MenuItem("Tools/PlaceCube")]
    public static void PlaceSelected()
    {
        foreach(Object cube in Selection.gameObjects)
        {
            Transform t = (cube as GameObject).transform;
            t.position = new Vector3(Mathf.RoundToInt(t.position.x), 0, Mathf.RoundToInt(t.position.z));
        }
    }
     
}
