using UnityEngine;

public class ScrollController : MonoBehaviour
{  
    private float startY;
    private Transform cameraTransform;

    // Use this for initialization
    void Start()
    {
        cameraTransform = Camera.main.transform;
        startY = Vector3.Dot(new Vector3(1,0, 1).normalized, (new Vector3(cameraTransform.position.x, 0, cameraTransform.position.z) - transform.position).normalized) * Vector3.Distance(transform.position, new Vector3(cameraTransform.position.x, 0, cameraTransform.position.z));
    }
    
    // Update is called once per frame
    void Update()
    {
        float dot = Vector3.Dot(new Vector3(1, 0, 1).normalized, (new Vector3(cameraTransform.position.x, 0, cameraTransform.position.z) - transform.position).normalized);
        float distance = Vector3.Distance(transform.position, new Vector3(cameraTransform.position.x, 0, cameraTransform.position.z));
        float offsetY = dot * distance;

        if (offsetY - startY > 1.414 * 20f)
        {
//            int move = (int)(1/ 1.414f * Camera.main.orthographicSize * 2);
//            gameObject.isStatic = false;
//            transform.position += new Vector3(19, 0, 19);

//            gameObject.isStatic = false;

//            transform.position += new Vector3(19, 0, 19);
//            Destroy(gameObject);
            transform.Translate(new Vector3(20, 0, 20));
        }
    }
}
