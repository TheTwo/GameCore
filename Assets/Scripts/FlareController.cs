using UnityEngine;

public class FlareController : MonoBehaviour
{
    public void OnAnimationComplete()
    {
        GameObject.Destroy(gameObject);
    }
}
