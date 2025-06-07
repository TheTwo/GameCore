using UnityEngine;
using System.Collections.Generic;

public class TutorialController : MonoBehaviour
{   
    private List<ITip> tips;
    GameController gameController;
    ITip currentTip;

    private UIController uiController;
    private Animator animator;
    private bool finished = false;
    private TutorialData tutorialData;

    private int currentTipIndex;

    public TutorialData TutorialData
    {
        get
        {
            return tutorialData;
        }
    }

    void Awake()
    {
        gameController = FindObjectOfType<GameController>();

        // Always create the tutorialData object so it's never null
        tutorialData = new TutorialData();

        if (gameController.GameData.HighScore < GameConfig.TUTORIAL_END_SCORE)
        {
            tips = new List<ITip>();
            
            tips.Add(new WelcomeTip());
            tips.Add(new TreeTip());
            tips.Add(new EatCubeTip());
            tips.Add(new MatchTip());
            tips.Add(new RemoveTip());
            tips.Add(new LevelTip());
            
            tutorialData.OnTutorialDataChange += OnTutorialDataChange;
            
            currentTipIndex = 0;
            currentTip = tips [currentTipIndex];

            uiController = FindObjectOfType<UIController>();

            gameController.inTutorialMode = true;

            gameController.GameData.NodeSpeed = GameConfig.TUTORIAL_NODE_SPEED;
        }
    }

    void OnDestroy()
    {

    }     

    public void OnGameStart()
    {                
        gameController.OnTutorialFinish();
    }

    public void FinishTutorial()
    {
        if (!finished)
        {
            finished = true;
            gameController.inTutorial = false;
            gameController.OnTutorialFinish();
        }
    }

    private void OnTutorialDataChange(TutorialData tutorialData)
    {
        if (currentTip != null && currentTip.ShouldShowTip(tutorialData))
        {
            uiController.ShowTutorial(currentTip);
        }
    }

    public void OnTutorialOKBtnClick()
    {
        currentTip.OnTipHide();

        currentTipIndex++;

        if(currentTipIndex < tips.Count)
        {
            currentTip = tips[currentTipIndex];
        }
        else
        {
            currentTip = null;
        }

        uiController.HideTutorial();
    }
}
