using UnityEngine;

public class CameralFollow : MonoBehaviour
{
    public Transform target; // The snake's head
    public float followSpeed = 10f; // Increased speed for more responsive follow

    // The desired screen position for the target (X: 0.5 = center, Y: 0.33 = 1/3 from bottom)
    private readonly Vector3 targetScreenPos = new Vector3(0.5f, 0.333f, 0);
    private float initialHeight;
    private Vector3 viewRayDirection; // The fixed direction of the view ray
    private GameController gc;

    void Start()
    {
        gc = FindObjectOfType<GameController>();
        if (target == null)
        {
            Snake snake = FindObjectOfType<Snake>();
            if (snake != null && snake.headNode != null)
            {
                target = snake.headNode.transform;
            }
        }
        
        // Store the camera's initial height and calculate the fixed view ray direction once.
        initialHeight = transform.position.y;
        viewRayDirection = Camera.main.ViewportPointToRay(targetScreenPos).direction;
    }
    
    void LateUpdate()
    {
        if (target == null || (gc != null && gc.paused))
        {
            return;
        }

        // --- Geometric Calculation (Corrected) ---

        // 1. Calculate the distance 's' from the camera to the target's horizontal plane along the view ray.
        // Formula: s = (target.y - camera.y) / ray.direction.y
        float s = (target.position.y - initialHeight) / viewRayDirection.y;

        // 2. The desired camera position is found by moving *from* the target *backwards* along the view ray.
        // This is the corrected formula with the minus sign.
        Vector3 desiredPosition = target.position - viewRayDirection * s;
        
        // --- Movement ---
        // Smoothly move the camera towards the calculated perfect position.
        // Its rotation is never changed.
        transform.position = Vector3.Lerp(transform.position, desiredPosition, Time.deltaTime * followSpeed);
    }

    public void OnGameStart()
    {
        // This function can be used to reset the camera if needed.
    }
}
