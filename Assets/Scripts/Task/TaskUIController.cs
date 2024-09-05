using UnityEngine;
using UnityEngine.UI;

public class TaskUIController : MonoBehaviour
{
    //    public Toggle toggle;
    public Text description;
    public Text reward;
    public GameObject finish;


    private bool isCompleted;
    private GameData gameData;
    private ITask task;
    private Animator animator;
    private bool inited = false;

    private GameController gameController;

    void Awake()
    {
        animator = GetComponent<Animator>();
        gameController = FindObjectOfType<GameController>();
    }

    void OnDestroty()
    {
        gameData.OnGameDataChange -= HandleOnGameDataChange;
    }

    public void Init(ITask task, GameData gameData)
    {
        if (gameController.inTutorialMode || inited)
        {
            return;
        }

        this.inited = true;
        this.task = task;
        this.gameData = gameData;

        description.text = task.Description(gameData);
        reward.text = task.Reward.ToString();

        if (task.IsTaskComplete(gameData))
        {
            isCompleted = true;
        }

        gameData.OnGameDataChange += HandleOnGameDataChange;

        animator.SetTrigger("TaskShow");
    }

    void HandleOnGameDataChange(GameData gamedata)
    {
        if (task.IsTaskComplete(gamedata) && !TaskSystem.Instance.IsTaskDone(task))
        {
            gameData.OnGameDataChange -= HandleOnGameDataChange;
            description.text = task.Description(gameData);

            Invoke("ShowStartAdd", 0.5f);

            reward.text = task.Reward.ToString();
            animator.SetTrigger("TaskFinish");
            TaskSystem.Instance.FinishTask(task);
            gameData.OnGameDataChange -= HandleOnGameDataChange;
        }
    }

    private void ShowStartAdd()
    {
        EffectManager.Instance.ShowStarAdd(task.Reward);                
    }

    public void OnFinishTaskAnimationFinish()
    {
        gameController.AddStar(task.Reward);
    }

    public ITask Task
    {
        get
        {
            return task;
        }
    }
}
