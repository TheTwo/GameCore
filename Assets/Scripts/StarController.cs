using UnityEngine;

public class StarController : MonoBehaviour
{

    // Use this for initialization
    void Start()
    {
        RandomMove();
    }
    
    private void RandomMove()
    {
        Vector3 moveTarget = new Vector3(Random.value * 5, Random.value * 5, 0);
        iTween.MoveBy(gameObject, iTween.Hash("amount", moveTarget,"time", 2f,"oncomplete", "oncomplete"));
//        iTween.MoveAdd(gameObject, moveTarget, 2);
    }

    private void oncomplete()
    {
        RandomMove();
    }
}
