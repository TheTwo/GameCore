using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

class TileEditorWindow : EditorWindow
{
    static TileEditorWindow _windowInstance; 

    [MenuItem ("Tools/TileEditorWindow")] 
    public static void  ShowWindow()
    {
        if(_windowInstance == null)
        {
            _windowInstance = EditorWindow.GetWindow(typeof(TileEditorWindow)) as TileEditorWindow;  
            SceneView.onSceneGUIDelegate = SceneUpdate;

            TileEditor[] objs = FindObjectsOfType<TileEditor>();

            foreach(TileEditor g in objs)
            {
                if(_windowInstance.sceneObjects.ContainsKey(g.transform.position))
                {
                    DestroyImmediate(_windowInstance.sceneObjects[g.transform.position]);

                    _windowInstance.sceneObjects.Remove(g.transform.position);
                }

                _windowInstance.sceneObjects.Add(g.transform.position, g);
            }
        }
    }

    static void SceneUpdate(SceneView sceneview)
    {
        _windowInstance.OnSceneGUI(sceneview);
    }

    private List<GameObject> tiles = new List<GameObject>();
    private GameObject currentTile;
    public Dictionary<Vector3, TileEditor> sceneObjects = new Dictionary<Vector3, TileEditor>();
    
    void OnGUI()
    {
        if (GUILayout.Button("Add Select Tiles"))
        {
            foreach(GameObject g in Selection.gameObjects)
            {
                tiles.Add(g);
            }
        }

        for(int i = 0; i < tiles.Count; i++)
        {
            GUILayout.BeginHorizontal();
            GUILayout.Label(tiles[i].name);

            if(GUILayout.Button("Choose", GUILayout.Width(100)))
            {
                currentTile = tiles[i];
            }

            GUILayout.EndHorizontal();
        }

        GUILayout.Space(100);

        GUILayout.Label(currentTile == null ? "" : currentTile.name);
    }

    void OnSceneGUI(SceneView sceneview)
    {
        Event e = Event.current;

        Ray r = Camera.current.ScreenPointToRay(new Vector3(e.mousePosition.x, -e.mousePosition.y + Camera.current.pixelHeight));
        Vector3 mousePos = r.origin;

        if(e.isKey && e.keyCode == KeyCode.Space)
        {
            GameObject tile = Instantiate(currentTile) as GameObject;
            tile.transform.position = new Vector3(mousePos.x, -0.64f , mousePos.z);

            Vector3 key = new Vector3(Mathf.CeilToInt(mousePos.x), -0.64f, Mathf.CeilToInt(mousePos.z));

            TileEditor editor = tile.GetComponent<TileEditor>();

            if(sceneObjects.ContainsKey(key) )
            {
                if(!editor.isOverlay)
                {
                    DestroyImmediate(sceneObjects[key].gameObject);
                }
                sceneObjects.Remove(key);
            }

            sceneObjects.Add(key, editor);
        }
        else if(e.isKey && e.keyCode == KeyCode.D)
        {
            Vector3 key = new Vector3(Mathf.CeilToInt(mousePos.x), -0.64f, Mathf.CeilToInt(mousePos.z));
            if(sceneObjects.ContainsKey(key))
            {
                DestroyImmediate(sceneObjects[key].gameObject);
                sceneObjects.Remove(key);
            }
        }
    }
}