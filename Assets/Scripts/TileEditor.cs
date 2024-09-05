using UnityEngine;

[ExecuteInEditMode]
public class TileEditor : MonoBehaviour
{
    public bool isOverlay;
    // Use this for initialization
    void Start()
    {
    
    }
    
    // Update is called once per frame
    void Update()
    {
#if UNITY_EDITOR
        int x = Mathf.CeilToInt(transform.position.x);
        int z = Mathf.CeilToInt(transform.position.z);

        transform.position = new Vector3(x, -0.64f, z);
#endif
    }
}
