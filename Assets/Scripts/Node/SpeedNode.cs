using UnityEngine;
using System.Collections;

public class SpeedNode : BasicNode
{
    private float speedBoostDuration = 5f; // 加速持续时间
    private float speedBoostMultiplier = 1.5f; // 加速倍率

    public override void MeetSnake(Snake snake)
    {
        // 调用Snake类中的新方法处理加速效果
        snake.MeetSpeedNode(this);
    }

    public float GetSpeedBoostDuration()
    {
        return speedBoostDuration;
    }

    public float GetSpeedBoostMultiplier()
    {
        return speedBoostMultiplier;
    }
} 