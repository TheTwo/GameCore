using UnityEngine;
using System.Collections;
using UnityEditor;

public class InstantiateSlections : MonoBehaviour {

    [MenuItem("Tools/AddSlectionsToScene")]
    public static void AddSlectionsToScene()
    {
        foreach(GameObject g in Selection.gameObjects)
        {
            GameObject g1 = Instantiate(g) as GameObject;
            g1.name = g.name;
        }
    }

    [MenuItem("Tools/SaveAsPrefab")]
    public static void SaveAsPrefab()
    {
        foreach(Object g in Selection.objects)
        {
//            PrefabUtility.CreatePrefab(Application.dataPath + "/" +  g.name + ".prefab", g);

            AssetDatabase.CreateAsset(g, Application.dataPath + "/TilePrefabs/" +  g.name);
        }
    }

    [MenuItem("Tools/PlaceTile")]
    public static void PlaceTile()
    {
        int i = 0;
        foreach(GameObject g in Selection.gameObjects)
        {
            g.transform.position = new Vector3(i++ / 12, 0, i % 12);
        }
    }
}
