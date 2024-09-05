using UnityEngine;

public class CameralFollow : MonoBehaviour
{
    public Transform target;
    public float offset;
    public float Speed;

    private Vector3 currentVelocity;

    private GameController gc;

    void Start()
    {
//        Camera.main.orthographicSize = (float)Screen.height / Screen.width * (GameConfig.X_COUNT);gc
        gc = FindObjectOfType<GameController>();
    }
    
    void Update()
    {
        if (target == null || gc.paused)
        {
            return;
        }

        float x = (Vector3.Dot(target.position, new Vector3(1, 0, 1).normalized) - offset) * 1.414f / 2;
        Vector3 targePostion = new Vector3(x, transform.position.y, x);
        transform.position = Vector3.Lerp(transform.position, targePostion, Time.deltaTime * Speed);

//        transform.position = Vector3.SmoothDamp(transform.position, targePostion, ref currentVelocity, 0.1f);
    }

    public void OnGameStart()
    {
        offset = 7f;
    }
}
