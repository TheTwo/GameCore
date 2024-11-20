using UnityEngine;
using UnityEngine.UI;

public class StartUIController : MonoBehaviour
{
    public Text BestScore;
    public Text CubeCount;
    public GameObject Title;
    public SoundController soundController;
    public TaskPanelController taskPanelController;
    public GameObject bottomBtns;

	public GameObject removeAdBtn;

    public GameObject gamecenterBtn;

    public GameObject shopBtn;

    private GiftUIController giftUIController;

//    private bool showGift = false;
    private GameData gameData;

    private Animator animator;

    private LevelGenerate levelGenerate;
    void Start()
    {
        animator = GetComponent<Animator>();
        giftUIController = FindObjectOfType<GiftUIController>();
        levelGenerate = FindObjectOfType<LevelGenerate>();

#if UNITY_IOS
		// removeAdBtn.SetActive(!APIForXcode.IsPurchasedForRemoveAd());
        gamecenterBtn.SetActive(true);
#else
		// removeAdBtn.SetActive(false);
        gamecenterBtn.SetActive(false);
#endif

        gamecenterBtn.SetActive(true);

        //shopBtn.SetActive(false);
    }

	void confirmRemoveAd()
	{
		// removeAdBtn.SetActive(!APIForXcode.IsPurchasedForRemoveAd());
	}

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape) && !giftUIController.isShowing && !taskPanelController.gameObject.activeSelf)
        {
            Application.Quit();
        }
    }

    public void UpdateUI(GameData gameData)
    {
        this.gameData = gameData;
        BestScore.text = gameData.HighScore.ToString();
        CubeCount.text = gameData.Star.ToString();
        iTween.MoveBy(Title, iTween.Hash("y", - Screen.height * 0.4f, "easetype", "easeOutElastic", "time", 1.3f));
        soundController.UpdateUI(gameData);
//        taskPanelController.InitUI(gameData);

        GetComponent<NewIconController>().InitRole(gameData);
    }

    public void OnStartClick()
    {
        animator.SetTrigger("GameStart");
        SoundManager.instance.PlayingSound("Button", 1f, Camera.main.transform.position);
        Invoke("StartGame", 0.3f);

		gameData.countOfPlay++;
		// 点击开始按钮，可以复活了
		gameData.canRevive = true;
        gameData.reviceCount = 0;   
    }

    private void StartGame()
    {
        FindObjectOfType<GameController>().StartGame();
    }

    public void OnGiftClick()
    {
        animator.SetTrigger("ShowGift");
        giftUIController.UpdateUI(gameData);

        bottomBtns.SetActive(false);
        levelGenerate.HideLevel();
        giftUIController.isShowing = true;
    }

    public void HideGift()
    {
        animator.SetTrigger("HideGift");
        UpdateUI(gameData);
        bottomBtns.SetActive(true);

        levelGenerate.ShowLevel();

        giftUIController.isShowing = false;
    }

    public void OnTaskBtnClicked()
    {
        if (taskPanelController.gameObject.activeSelf)
        {
            HideTask();
        }
        else
        {
            ShowTask();
        }
    }

    private void ShowTask()
    {
        taskPanelController.gameObject.SetActive(true);
        taskPanelController.InitUI(gameData);
    }

    public void HideTask()
    {
        taskPanelController.gameObject.SetActive(false);        
    }  
    
    public void ShowLeaderboard()
    {
        SoundManager.instance.PlayingSound("Button", 1f, Camera.main.transform.position);
        // APIForXcode.ShowLeaderboard();
    }
    
    public void HideLeaderboard()
    {
        // APIForXcode.HideLeaderboard();
    }
}
