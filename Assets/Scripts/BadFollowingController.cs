using UnityEngine;
using System.Collections;

public class BadFollowingController : MonoBehaviour
{
    private Vector3 startPosition;
    private Vector3 endPosition;
    private Vector3 targetPositon;
    private GameData gameData;

    void Start()
    {
        GameController.OnGameStart += HandleOnGameStart;
        startPosition = transform.localPosition;
        endPosition = Vector3.down * (Screen.height);
        transform.localPosition = targetPositon = endPosition;
    }

    void Update()
    {
        transform.localPosition = Vector3.Lerp(transform.localPosition, targetPositon, Time.deltaTime * 0.5f);
    }

    void OnDestroy()
    {
        if (gameData != null)
        {
            gameData.OnGameDataChange -= HandleOnGameDataChange;
        }
        GameController.OnGameStart -= HandleOnGameStart;
    }

    void HandleOnGameStart (GameData gameData)
    {
        this.gameData = gameData;
        GetComponent<ParticleSystem>().Play();
        this.gameData.OnGameDataChange += HandleOnGameDataChange;
    }

    void HandleOnGameDataChange (GameData gamedata)
    {
        targetPositon = endPosition + (startPosition - endPosition) / GameConfig.MAX_ENERGY * (10 - gamedata.Energy);

        if (gamedata.Energy == 0)
        {
//            particleSystem.Stop();
        }
        else if (gamedata.Energy > 0 && GetComponent<ParticleSystem>().isStopped)
        {
            GetComponent<ParticleSystem>().Play();
        }
    }

    public void Stop()
    {
        GetComponent<ParticleSystem>().Stop();
    }
}
