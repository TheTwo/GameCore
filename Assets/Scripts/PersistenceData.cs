using UnityEngine;
// using WeChatWASM;

public class PersistenceData : MonoBehaviour
{
    private static PersistenceData _instance;
    private bool _startGameImmediatly;

    public static PersistenceData Instance
    {
        get
        {
            if (_instance == null)
            {
                GameObject newg = new GameObject();
                newg.name = "PersistenceData";
                _instance = newg.AddComponent<PersistenceData>();
                DontDestroyOnLoad(_instance);
                // WX.GetSystemInfo(new GetSystemInfoOption());  // 读取SystemInfo
            }

            return _instance;
        }
    }

    public bool StartGameImmediatly
    {
        set
        {
            _startGameImmediatly = value;
        }
        get
        {
            return _startGameImmediatly;
        }
    }
}
