using UnityEngine;

public abstract class Node : MonoBehaviour 
{
    public NodeType type;
    public NodeStatus status;
    public Vector3 position;

    public int score;

    public abstract void MeetSnake(Snake snake);
    public abstract void MoveBy(Vector3 step, Snake snake, GameData gameData);
    public abstract void Fllow(Vector3 lastPostion, Snake snake, GameData gameData);
    public abstract void BesselTo(int add);
    public abstract void OnUpdate();
    public abstract void ChangeToColor(Color color);
    public abstract void SetPosition(Vector3 position);
    public abstract void RemoveFromSnake(Snake snake, int addScore);

    public bool inSnake;
}
