using System;
using UnityEngine;
using UnityEngine.UI;
using WeChatWASM;

public class UIController : MonoBehaviour
{
    public GameObject StartUI;
    public GameObject EndUI;
    public GameObject GameUI;
    public GameObject PauseUI;
    public GameObject TutorialUI;
    public GameObject ShopUI;
    public RectTransform Rootrect;
    public CanvasScaler cs;

    private GameUIController gameUIController;
    private LevelGenerate levelGenerate;

    private GameData gameData;

    private GameController gameController;

    private void Awake()
    {
        var info = WX.GetWindowInfo();
        if (info == null)
        {
            return;
        }
        
        float py = (float)info.safeArea.top / (float)info.windowHeight;
// Rootrect初始时设置其Anchor，使其与父节点一样大，也就是屏幕的大小
// 调整屏幕移到刘海屏下面,
        Rootrect.anchorMin = new Vector2((float)info.safeArea.left / (float)info.windowWidth, -(float)info.safeArea.top / (float)info.windowHeight);
// 重新计算缩放，让高度占满刘海屏以下的区域
        cs.referenceResolution = new Vector2(cs.referenceResolution.x, cs.referenceResolution.y * (1.0f+py));
    }

    public void OnGameInit(GameData gameData)
    {
        levelGenerate = FindObjectOfType<LevelGenerate>();
        this.gameData = gameData;

        UnActiveAll();
        StartUI.SetActive(true);
        Reposition(StartUI);

        StartUI.GetComponent<StartUIController>().UpdateUI(gameData);
        levelGenerate.HideLevel();

        gameController = FindObjectOfType<GameController>();
    }

    public void ShowStartUI()
    {
        UnActiveAll();
        StartUI.SetActive(true);
        Reposition(StartUI);

        StartUI.GetComponent<StartUIController>().UpdateUI(gameData);

        levelGenerate.HideLevel();

        gameController.snake.UpdateHead();
    }

    public void UpdateScore(int addScore)
    {
        if (gameUIController == null)
        {
            gameUIController = GameUI.GetComponent<GameUIController>();
        }

        gameUIController.UpdateScore(addScore);
    }

    public void UpdateStar(int star)
    {
        if (gameUIController == null)
        {
            gameUIController = GameUI.GetComponent<GameUIController>();
        }
        
        gameUIController.UpdateStar(star);
    }

    public void UpdateLevelSlider()
    {
        if (gameUIController == null)
        {
            gameUIController = GameUI.GetComponent<GameUIController>();
        }
        
        gameUIController.UpdateLevelUpSlider();
    }

    public void OnGameStart(GameData gameData)
    {
        UnActiveAll();
        GameUI.SetActive(true);    
        Reposition(GameUI);
        GameUI.GetComponent<GameUIController>().OnGameStart(gameData);

        levelGenerate.ShowLevel();
    }

    public void OnGameEnd(GameData data)
    {
        UnActiveAll();
        EndUI.SetActive(true);
        Reposition(EndUI);

        EndUI.GetComponent<EndUIController>().UpdateUI(data);

        levelGenerate.HideLevel();
    }

    public void OnPause(GameData data)
    {
        UnActiveAll();
        PauseUI.SetActive(true);
		Reposition(PauseUI);

		// 在屏幕顶端显示Banner
		// APIForXcode.ShowBanner(true);

        PauseUI.GetComponent<PauseUIController>().UpdateUI(data);
    }

    public void OnResume()
	{
		// 移除Banner
		// APIForXcode.RemoveBanner();

        UnActiveAll();
        GameUI.SetActive(true);
        Reposition(GameUI);
    }

    public void ShowTutorial(ITip tip)
    {
//        UnActiveAll();
        TutorialUI.SetActive(true);
        TutorialUI.GetComponent<TutorialUIController>().UpdateUI(tip);
        Reposition(TutorialUI);

        gameController.inTutorial = true;
    }

    public void HideTutorial()
    {
        TutorialUI.SetActive(false);

        Invoke("ResettutorialState", 0.25f);
    }

    private void ResettutorialState()
    {
        gameController.inTutorial = false;
    }

    //public void ShowShop()
    //{
    //    UnActiveAll();
    //    ShopUI.SetActive(true);
    //    Reposition(ShopUI);

    //    levelGenerate.HideLevel();        
    //}

    public void HideShop()
    {
        ShopUI.SetActive(false);
        ShowStartUI();
    }

    private void UnActiveAll()
    {
        StartUI.SetActive(false);
        EndUI.SetActive(false);
        GameUI.SetActive(false); 
        PauseUI.SetActive(false);
        TutorialUI.SetActive(false);
        ShopUI.SetActive(false);
    }

    private void Reposition(GameObject ui)
    {
        RectTransform rectTransform = ui.GetComponent<RectTransform>();
        rectTransform.anchoredPosition = Vector2.zero;  
//        Transparent(ui);
    }

    private void Transparent(GameObject ui)
    {
        ui.GetComponent<Image>().color = new Color(1, 1, 1, 0);
    }

    public void Hide()
    {
        gameObject.SetActive(false);
    }

    public void Show()
    {
        gameObject.SetActive(true);
    }
}
