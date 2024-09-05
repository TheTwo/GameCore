using UnityEngine;
using UnityEngine.UI;

public class TaskRender : MonoBehaviour
{
    public Text description;
    public Text reward;
    public Toggle mark;


    public void Init(ITask task, GameData gameData)
    {       
        description.text = task.Achievement;
        
        if (TaskSystem.Instance.IsTaskDone(task))
        {
            mark.isOn = true;
        }
        else
        {
            mark.isOn = false;
        }
        
        reward.text = task.Reward.ToString();
    }
}
