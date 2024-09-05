using UnityEngine;

public class BorderNode  : MonoBehaviour
{
    void OnTriggerEnter(Collider collider)
    {
        if(collider.GetComponent<HeadNode>() != null)
        {
            FindObjectOfType<Snake>().MeetLandMineBowNode();
        }
    }
}
