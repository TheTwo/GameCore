using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.Advertisements;

public class EndUIController : MonoBehaviour
{
    public Text Score;
    public Text BestScore;
    public Text CubeCount;
    public GameObject flarePrefab;
    public Transform flareParent;
    public GameObject NewHighScoreText;

    public GameObject HomeNew;

    public List<TaskUIController> taskUIs;

    public GameObject reviveGameobject;
    public Button reviveBtn;
    public Button sharBtn;

    private List<ITask> processing;
    private GameData gameData;

    private bool captured;
    private Animator animator;

    void Awake()
    {
        animator = GetComponent<Animator>();
    }

    public void UpdateUI(GameData data)
    {
        this.gameData = data;

        captured = false;

//        Score.text = data.Score.ToString();

        EffectManager.Instance.CumulativeEffect(Score, data.Score);

        BestScore.text = data.HighScore.ToString();
        CubeCount.text = data.Star.ToString();

        if (data.isHighScore)
        {
            SoundManager.instance.PlayingSound("NewHighScore");
            NewHighScoreText.SetActive(true);                                      
            AddFlare();
            animator.enabled = true;
        }
        else
        {
            NewHighScoreText.SetActive(false);                                     
            animator.enabled = false;
        }

		if (gameData.canRevive) {
			reviveGameobject.SetActive(true);
			reviveBtn.interactable = true;
			reviveBtn.GetComponent<Animator>().enabled = reviveBtn.interactable;
		}
		else {
			reviveGameobject.SetActive(false);
		}
                
//        gameData.Energy = 0; 

//        UpdateProcessing();

//        Invoke("StopBadFollow", 1f);

        GetComponent<NewIconController>().Init(data);
    }

    private void StopBadFollow()
    {
        FindObjectOfType<BadFollowingController>().Stop();
    }

    public void AddFlare()
    {
        StartCoroutine(Fire());
    }

    IEnumerator Fire()
    {
        while (true)
        {
            int count = Random.Range(5, 20);
            for (int i = 0; i < count; i++)
            {
                GameObject flare = Instantiate(flarePrefab) as GameObject;
                flare.transform.SetParent(flareParent);
                flare.transform.localScale = Vector3.one * Random.value / 2;
                flare.transform.localPosition = new Vector3((Random.value - 0.5f) * 640, (Random.value - 0.5f) * 1136, 0);
                yield return new WaitForSeconds(Random.value / 10);
            }

            if (!captured)
            {
                captured = true;
                ScreenCapture.CaptureScreenshot("screen.png");
            }
        }
    }

    public void OnRestartClick()
	{
		// // 移除Banner
		// APIForXcode.RemoveBanner();

       GameObject.FindObjectOfType<GameController>().Restart();
    }

    public void OnCubeCountChange()
    {
        CubeCount.text = gameData.Star.ToString();
    }
}
