using UnityEngine;

[ExecuteInEditMode]
public class DesignTool : MonoBehaviour
{
    void Update()
    {
        Debug.DrawLine(Vector3.zero, new Vector3(200, 0, 200));

        Debug.DrawLine(Vector3.zero - new Vector3(0, 0, 7), new Vector3(200, 0, 200) - new Vector3(0, 0, 7));

        Debug.DrawLine(Vector3.zero + new Vector3(0, 0, 7), new Vector3(200, 0, 200) + new Vector3(0, 0, 7));
    }
}
