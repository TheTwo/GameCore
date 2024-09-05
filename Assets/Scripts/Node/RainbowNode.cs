using UnityEngine;

public class RainbowNode : BasicNode
{
    public override void MeetSnake(Snake snake)
    {
        snake.MeetRainBowNode(this);
    }

    public override void SetPosition(Vector3 position)
    {
        this.position = position;
//        jellyMesh.SetPosition(position, true);
        transform.localRotation = Quaternion.identity;
        transform.position = position;
    }

    public override void OnUpdate()
    {
        if (gameController.startCheckingRestore && Camera.main.WorldToScreenPoint(position).y < -5)
        {
            GameObject.Destroy(gameObject);
        }
    }
}
