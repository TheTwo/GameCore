using System.Collections.Generic;
using UnityEngine;
using Pathfinding.Serialization.JsonFx;

public class TaskSystem
{
    private List<ITask> tasks = new List<ITask>(20);
    private List<ITask> leftTasks = new List<ITask>(3);
    private List<ITask> processingTasks;
    private static TaskSystem instance;

    private static System.ComponentModel.Int32Converter _unused = new System.ComponentModel.Int32Converter();
    private static System.ComponentModel.DecimalConverter _unused1 = new System.ComponentModel.DecimalConverter();

    public TaskSystem()
    {
        Init();
    }

    public static TaskSystem Instance
    {
        get
        {
            if (instance == null)
            {
                instance = new TaskSystem();
            }

            return instance;
        }
    }

    public void AddTask(ITask task)
    {
        tasks.Add(task);
    }

    public void Init()
    {
        tasks = new List<ITask>();

        string taskJson = Resources.Load<TextAsset>("task").ToString();

        Task[] taskArray = JsonReader.Deserialize<Task[]>(taskJson);

        for (int i = 0; i < taskArray.Length; i++)
        {
            switch (taskArray [i].type)
            {
                case "EatCubeTask":
                    tasks.Add(JsonReader.Deserialize<EatCubeTask>(JsonWriter.Serialize(taskArray[i])));
                    break;
                case "ScoreTask":
                    tasks.Add(JsonReader.Deserialize<ScoreTask>(JsonWriter.Serialize(taskArray[i])));
                    break;
                case "MatchTask":
                    tasks.Add(JsonReader.Deserialize<MatchTask>(JsonWriter.Serialize(taskArray[i])));
                    break;
            }
        }

        leftTasks = new List<ITask>();
         
        for (int i = 0; i < tasks.Count; i ++)
        {
            ITask task = tasks [i];
            if (!IsTaskDone(task))
            {
                leftTasks.Add(task);
            }
        }       

        processingTasks = new List<ITask>();
        for (int i = 0; i < 1; i++)
        {
            ITask task = PopTask();
            if (task != null)
            {
                processingTasks.Add(task);
            }
        }
    }

    private ITask PopTask()
    {
        if (leftTasks.Count == 0)
        {
            Debug.Log("No left Task");
            return null;
        }
        else
        {
            ITask task = leftTasks [0];
            leftTasks.RemoveAt(0);
            return task;
        }
    }

    public void FinishTask(ITask task)
    {
        processingTasks.Remove(task);

        ITask newTask = PopTask();
        if (newTask != null)
        {
            processingTasks.Add(newTask);
        }

        PlayerPrefs.SetString(task.TaskName, "Done");
    }

    public bool IsTaskDone(ITask task)
    {
        if (PlayerPrefs.GetString(task.TaskName).Equals("Done"))
        {
            return true;
        }

        return false;
    }

    public List<ITask> ProcessingTasks
    {
        get
        {
            return processingTasks;
        }
    }

    public List<ITask> Tasks
    {
        get
        {
            return tasks;
        }
    }
}

