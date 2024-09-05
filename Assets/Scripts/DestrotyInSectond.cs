using UnityEngine;

public class DestrotyInSectond : MonoBehaviour
{
    public float second;
    // Use this for initialization
    void Start()
    {
        Invoke("DestorySelf", second);
    }

    private void DestorySelf()
    {
        Destroy(gameObject);
    }
}
