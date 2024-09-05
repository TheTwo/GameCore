using UnityEngine;
using System.Collections;
using UnityEditor;

public class PlaceMap : MonoBehaviour
{
    [MenuItem("Tools/PlacePlane")]
    public static void PlacePlane()
    {
        int index = -8;
        foreach (Object cube in Selection.gameObjects)
        {
            Transform t = (cube as GameObject).transform;
            t.localPosition = new Vector3(index, -0.5f, index + 0.5f);
            index++;
        }
    }

    [MenuItem("Tools/PlaceLeftTree")]
    public static void PlaceLeftTree()
    {
        int count = 8;
        Line line = new Line(1, 7);
        float index = 0;
        GameObject[] selects = Selection.gameObjects;
        for (int i = 0; i < count; i++)
        {
            Transform t = selects[i].transform;
            t.localPosition = new Vector3(index + Random.value / 10, 1f, line.Y(index) + Random.value / 10);
            index += 2.5f  + Random.value / 3;
            t.name = "line_1_" + i;
            t.localRotation = Quaternion.Euler(new Vector3(45, 45, 0));
            t.localScale = Vector3.one * 1.5f;
        }

        Line line2 = new Line(1, 9);
        index = 0;
        for (int j = count; j < count*2; j++)
        {
            Transform t = selects[j].transform;
            t.localPosition = new Vector3(index + Random.value / 10, 1f, line2.Y(index) + Random.value / 10);
            index += 2.5f  + Random.value / 3;
            t.name = "line_2_" + j;
            t.localRotation = Quaternion.Euler(new Vector3(45, 45, 0));
            t.localScale = Vector3.one * 1.5f;
        }

//        Line line3 = new Line(1, 9);
//        index = 0;
//        for (int j = count*2; j < selects.Length; j++)
//        {
//            Transform t = selects[j].transform;
//            t.localPosition = new Vector3(index + Random.value / 10, 1f, line3.Y(index) + Random.value / 10);
//            index += 2f  + Random.value / 3;
//            t.name = "line_3_" + j;
//            t.localRotation = Quaternion.Euler(new Vector3(45, 45, 0));
//            t.localScale = Vector3.one * 2;
//        }
    }

    [MenuItem("Tools/PlaceRightTree")]
    public static void PlaceRightTree()
    {
        int count = 8;
        Line line = new Line(1, -7.5f);
        float index = 0;
        GameObject[] selects = Selection.gameObjects;
        for (int i = 0; i < count; i++)
        {
            Transform t = selects[i].transform;
            t.localPosition = new Vector3(index + Random.value / 10, 1f, line.Y(index) + Random.value / 10);
            index += 2.5f  + Random.value / 3;
            t.name = "line_1_" + i;
            t.localRotation = Quaternion.Euler(new Vector3(45, 45, 0));
            t.localScale = Vector3.one * 1.5f;
        }
        
        Line line2 = new Line(1, -9.5f);
        index = 0;
        for (int j = count; j < count*2; j++)
        {
            Transform t = selects[j].transform;
            t.localPosition = new Vector3(index + Random.value / 10, 1f, line2.Y(index) + Random.value / 10);
            index += 2.5f  + Random.value / 3;
            t.name = "line_2_" + j;
            t.localRotation = Quaternion.Euler(new Vector3(45, 45, 0));
            t.localScale = Vector3.one * 1.5f;
        }
        
//        Line line3 = new Line(1, -9.5f);
//        index = 0;
//        for (int j = count*2; j < selects.Length; j++)
//        {
//            Transform t = selects[j].transform;
//            t.localPosition = new Vector3(index + Random.value / 10, 1f, line3.Y(index) + Random.value / 10);
//            index += 1f  + Random.value / 3;
//            t.name = "line_3_" + j;
//            t.localRotation = Quaternion.Euler(new Vector3(45, 45, 0));
//        }
    }
}
