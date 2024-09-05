public class Task : ITask
{    
    public Task()
    {
    }

    public string taskName;

    public string TaskName
    {
        get
        {
            return taskName;
        }
        set
        {
            taskName = value;
        }
    }

    public int target;

    public int Target
    {
        get
        {
            return target;
        }
        set
        {
            target = value;
        }
    }

    public int index;

    public int Index
    {
        get
        {
            return index;
        }
        set
        {
            index = value;
        }
    }

    public int reward;

    public int Reward
    {
        get
        {
            return reward;
        }
        set
        {
            reward = value;
        }
    }

    public string type;

    public string Type
    {
        get
        {
            return type;
        }
        set
        {
            type = value;
        }
    }

    public virtual bool IsTaskComplete(GameData gameData)
    {
        return true;
    }
    
    public virtual string Description(GameData gameData)
    {
        return "";
    }

    public virtual string Achievement
    {
        get
        {
            return "";
        }
    }
}
