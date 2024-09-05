using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;

public class TaskPanelController : MonoBehaviour 
{
    public GameObject render;
    public Transform grid;
    public Button closeBtn;

//    private Animator animator;

    void Start()
    {
//        animator = GetComponent<Animator>();
        closeBtn.onClick.AddListener(OnBtnClick);
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            FindObjectOfType<StartUIController>().HideTask();
        }
    }

    public void OnBtnClick()
    {
        gameObject.SetActive(false);
//        animator.SetTrigger("Close");
    }

    public void InitUI(GameData gameData)
    {
        List<ITask> tasks = TaskSystem.Instance.Tasks;

        while(grid.childCount > 0)
        {
            DestroyImmediate(grid.GetChild(0).gameObject);
        }

        for(int i= 0; i<tasks.Count; i++)
        {
            GameObject mRender = Instantiate(render) as GameObject;
            mRender.transform.SetParent(grid);
            mRender.transform.localScale = Vector3.one;

            TaskRender task = mRender.GetComponent<TaskRender>();
            task.Init(tasks[i], gameData);
        }


        grid.GetComponent<RectTransform>().sizeDelta = new Vector2(grid.GetComponent<GridLayoutGroup>().cellSize.x,tasks.Count * grid.GetComponent<GridLayoutGroup>().cellSize.y);
    }
}
