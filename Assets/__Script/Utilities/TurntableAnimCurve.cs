using DG.Tweening;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TurntableAnimCurve : MonoBehaviour
{
	[Header("动画曲线，纵坐标为动画进度，取值0-1")]
    public AnimationCurve animationCurve;
	[Header("动画时长")]
    public float duration;

    [Header("最小圈数")]
    public int minTurns;

    [Header("最大圈数")]
    public int maxTurns;
}
