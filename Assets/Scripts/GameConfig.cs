using UnityEngine;
using System.Collections.Generic;

public class GameConfig
{
    public const float Factor1 = 1.6f;
    public const int X_COUNT = 7;
    public const float CUBE_REMOVE_GAP = 0.5f;
    public const float SCORE_EFFECT_GAP = 0.3f;
    public const int MAX_ENERGY = 10;
    public const float MAX_SPEED = 20;
    public const float MIN_SPEED = 5;
    public const int GIFT_GAP = 360;
    public const float CoinSpeed = 5f;

    public const int INVINSIBLE_SHAKE_RANGE = 5;
    public const float INVINSIBLE_CAMERA_SHAKE_RATE = 0.2f;

    public const float INVINSIBLE_TIME = 5;

    public const int MAX_REVIVE_COUNT = 1000;

    public const int TUTORIAL_NODE_SPEED = 3;

    public static int TUTORIAL_END_SCORE = 50;

    public const int AD_REWARD = 5;

    public const int MAX_TIME_GIFT_REWARD = 20;

	public const int INVINCIBLE_SPEED = 10;

    public static Dictionary<string, int> ROLE_PRICE_Dic = new Dictionary<string, int>()
    {
        {"Role0", 20},
        {"Role1", 40},
        {"Role2", 60},
        {"Role3", 80},
        {"Role4", 100},
        {"Role5", 120}
    };

    public static Dictionary<NodeType, Color> NODE_COLOR_DIC = new Dictionary<NodeType, Color>()
    {
        {NodeType.A, new Color(34f/255, 154f/255, 187f/255)},
        {NodeType.B, new Color(153f/255,19f/255,187f/255)},
        {NodeType.C, new Color(173f/255, 50f/255, 22f/255)},
        {NodeType.D, new Color(187f/255,161f/255, 8f/255)},
        {NodeType.BAD, new Color(53f / 255, 49f / 255, 49f / 255)},
        {NodeType.RAINBOW, Color.white}
    };

    public static List<int> LevelScore = new List<int>{0,50,100,200,300,400,500,600,700,800,900,1000,1100,1200,1300,1400,1500,1600,1700,1800,1900,2000,2100,2200,2300,2400,2500,int.MaxValue};

    public static List<int> LevelSpeed = new List<int>{4,7,11,15,18};
}
