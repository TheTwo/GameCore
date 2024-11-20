using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class GameData
{
    private const string HIGHT_SCORE = "high_score";
	public const string CUBE_COUNT = "cube_count";
    public const string SOUND_ENABLE = "SoundEnable";
    private const string GIFT_RECEIVE_TIME = "giftReceiveTime";
    private const string ROLE = "role";
    private const string UNLOCKED_ROLE_PRE = "unlocked_role";
    private int score;
    private int level = 1;
    private int energy = GameConfig.MAX_ENERGY;
    private bool isHight = false;
    private float speed = GameConfig.LevelSpeed[0];

	public int countOfPlay = 0;
	public bool canRevive = true;
    public int reviceCount = 0;

    public const int MAX_REVIVE_COUNT = 2;
    
    public delegate void GameDataChange(GameData gamedata);
    public event GameDataChange OnGameDataChange;

    public delegate void LevelUp(int level);
    public event LevelUp OnLevelUp;

    private bool _isSnakeInvinciable;

	private static GameData instance;

	public static GameData Instance
	{
		get
		{
			if (instance == null)
			{
				instance = new GameData();
			}

			return instance;
		}
	}

	public void Dispose()
	{
		instance = null;
	}

    public bool isSnakeInvinciable
    {
        get
        {
            return _isSnakeInvinciable;
        }
        set
        {
            _isSnakeInvinciable = value;
            OnGameDataChange(this);
        }
    }

    private float _totalInvinciableTime;

    public float totalInvinciableTime
    {
        get
        {
            return _totalInvinciableTime;
        }
        set
        {
            _totalInvinciableTime = value;
            OnGameDataChange(this);
        }
    }

    private float _remainInvinciableTime;

    public float remainInvinciableTime
    {
        get
        {
            return _remainInvinciableTime;
        }
        set
        {
            _remainInvinciableTime = value;
            OnGameDataChange(this);
        }
    }

    public GameData()
    {
        UnlockRole(0);
    }

    public float GiftReceiveTime
    {
        set
        {
            PlayerPrefs.SetFloat(GIFT_RECEIVE_TIME, value);

            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
        get
        {
            return PlayerPrefs.GetFloat(GIFT_RECEIVE_TIME, 0);
        }
    }

    public int Star
    {
        set
        {
            PlayerPrefs.SetInt(CUBE_COUNT, value);
            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
        get
        {
            return PlayerPrefs.GetInt(CUBE_COUNT);
        }
    }

    public int HighScore
    {
        set
        {
            PlayerPrefs.SetInt(HIGHT_SCORE, value);
            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
        get
        {
            return PlayerPrefs.GetInt(HIGHT_SCORE);
        }
    }

    public int Level
    {
        get
        {
            return level;
        }
    }

    public int Score
    {
        set
        {
            score = value;
            if (score > HighScore)
            {
                HighScore = score;
                isHight = true;
            }

            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }

            if(score >= GameConfig.LevelScore[level])
            {
                level++;
                OnLevelUp(level);
            }
        }
        get
        {
            return score;
        }
    }

    public int MaxEnergy
    {
        get
        {
            return GameConfig.MAX_ENERGY;
        }
    }

    public int Energy
    {
        set
        {
            if (value < GameConfig.MAX_ENERGY)
            {
                energy = value;
            }
            else
            {
                energy = GameConfig.MAX_ENERGY;
            }
            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
        get
        {
            return energy;
        }
    }

    public bool isHighScore
    {
        get
        {
            return isHight;
        }
    }

    public bool SoundEnable
    {
        set
        {
            PlayerPrefs.SetInt(SOUND_ENABLE, value ? 0 : -1);
            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
        get
        {
            return PlayerPrefs.GetInt(SOUND_ENABLE) == 0;
        }
    }

    public float NodeSpeed
    {
        set
        {
            speed = Mathf.Min(value, GameConfig.MAX_SPEED);
            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
        get
        {
            return speed;
        }
    }

    public int Role
    {
        set
        {
            PlayerPrefs.SetInt(ROLE, value);
            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
        get
        {
            return PlayerPrefs.GetInt(ROLE, 0);
        }
    }

    private int reviveCount;

    public int ReviveCount
    {
        get
        {
            return reviveCount;
        }
        set
        {
            reviveCount = value;
        }
    }

	public static bool IsRoleUnlocked(int roleIndex)
    {
        return PlayerPrefs.GetInt(UNLOCKED_ROLE_PRE + roleIndex, 0) > 0;
    }

    public void UnlockRole(int roleIndex)
    {
        PlayerPrefs.SetInt(UNLOCKED_ROLE_PRE + roleIndex, 1);
    }

    public void SelectRole(int roleIndex)
    {
        Role = roleIndex;
    }

    private int eatCubeCount;

    public int EatCubeCount
    {
        get
        {
            return eatCubeCount;
        }
        set
        {
            eatCubeCount = value;

            if (OnGameDataChange != null)
            {
                OnGameDataChange(this);
            }
        }
    }

    private int matchCount;

    public int MatchCount
    {
        get
        {
            return matchCount;
        }
        set
        {
            matchCount = value;
        }
    }

    public bool HasGift()
    {
        return TimeSince2001() - GiftReceiveTime > GameConfig.GIFT_GAP;
    }

    private double TimeSince2001()
    {
        System.DateTime centuryBegin = new System.DateTime(2001, 1, 1);
        System.DateTime currentDate = System.DateTime.Now;
        
        long elapsedTicks = currentDate.Ticks - centuryBegin.Ticks;
        System.TimeSpan elapsedSpan = new System.TimeSpan(elapsedTicks);
        
        return elapsedSpan.TotalSeconds;
    }

    public bool HasNew()
    {
        for(int i = 0; i < GameConfig.ROLE_PRICE_Dic.Count; i++)
        {
            int price = GameConfig.ROLE_PRICE_Dic ["Role" + i];

            if(!IsRoleUnlocked(i) && Star >= price)
            {
                return true;
            }
        }

        return false;
    }

#if UNITY_EDITOR
    [MenuItem("Tools/DeleteAllPlayerPrefs")]
    public static void DeleteAllPlayerPrefs()
    {
        PlayerPrefs.DeleteAll();
    }
#endif
}
