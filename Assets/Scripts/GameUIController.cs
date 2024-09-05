using UnityEngine;
using UnityEngine.UI;

public class GameUIController : MonoBehaviour
{
    public Text Score;
    public Slider slider;
    public TaskUIController task;
    public GameObject levelUp;   

    public Text Star;

    public Slider levelUpSlider;

    public Text levelUpLabel;
    public Text levelLabel;
    public Image sliderFill;
   
    private GameData gameData;

    private Animator animator;

    void OnEnable()
    {
		gameData = GameData.Instance;
        slider.value = slider.maxValue = GameConfig.MAX_ENERGY;
        animator = GetComponent<Animator>();
        levelLabel.text = "1";
    }

    void OnDisable()
    {
        gameData.OnLevelUp -= HandleOnLevelUp;
        gameData.OnGameDataChange -= HandleOnGameDataChange;
    }

    public void UpdateScore(int addScore)
    {
//        Score.text = gameData.Score.ToString();

        EffectManager.Instance.CumulativeEffect(Score, gameData.Score);

        animator.SetTrigger("AddScore");

        UpdateLevelUpSlider();
    }

    public void UpdateStar(int star)
    {
        Star.text = star.ToString();
        animator.SetTrigger("StarChange");
    }

    void Update()
    {
        if(gameData.isSnakeInvinciable)
        {
            levelLabel.text = gameData.remainInvinciableTime.ToString("f0");
        }

        if (Input.GetKeyDown(KeyCode.Escape))
        {
            FindObjectOfType<GameController>().HomePage();
        }
    }

    public void UpdateLevelUpSlider()
    {
        if(gameData.isSnakeInvinciable)
        {
            levelUpSlider.maxValue = gameData.totalInvinciableTime;
            levelUpSlider.value = gameData.remainInvinciableTime;
            sliderFill.color = Color.green;
        }
        else
        {
            levelUpSlider.maxValue = GameConfig.LevelScore[gameData.Level] - GameConfig.LevelScore[gameData.Level - 1];
            levelUpSlider.value = gameData.Score - GameConfig.LevelScore[gameData.Level - 1];
            levelLabel.text = gameData.Level.ToString();
        }
    }

    public void OnGameStart(GameData gameData)
    {
        this.gameData = gameData;

        if(TaskSystem.Instance.ProcessingTasks.Count > 0)
        {
            task.Init(TaskSystem.Instance.ProcessingTasks[0], gameData);
        }

        slider.maxValue = gameData.MaxEnergy;
        gameData.OnLevelUp += HandleOnLevelUp;
        gameData.OnGameDataChange += HandleOnGameDataChange;

        animator.SetFloat("Energy", gameData.Energy);
        
        animator.SetBool("Invinsiable", gameData.isSnakeInvinciable);
        
        animator.SetFloat("InvinsiableTime", gameData.remainInvinciableTime);
    }

    public void SetLevelUpSliderColor(Color color)
    {
        sliderFill.color = color;
    }

    void HandleOnGameDataChange (GameData gamedata)
    {
        slider.value = gameData.Energy;

        animator.SetFloat("Energy", gamedata.Energy);

        animator.SetBool("Invinsiable", gamedata.isSnakeInvinciable);

        animator.SetFloat("InvinsiableTime", gamedata.remainInvinciableTime);
    }

    void HandleOnLevelUp (int level)
    {
        animator.SetTrigger("LevelUp");
//        levelUpAnimator.SetTrigger("LevelUp");
        levelUpLabel.text = "STAGE " + level;

        levelLabel.text = level.ToString();

//        Time.timeScale = 0.5f;
//
//        Invoke("ResetTimeScale", 1);
    }

    private void ResetTimeScale()
    {
        Time.timeScale = 1f;
    }
}
