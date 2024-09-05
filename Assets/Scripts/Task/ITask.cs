public interface ITask
{
    bool IsTaskComplete(GameData gameData);
    string Description(GameData gameData);
    string Achievement
    {
        get;
    }
    int Target
    {
        get;
        set;
    }
    int Index 
    { 
        get; 
        set; 
    }
    int Reward
    {
        get;
        set;
    }
    string Type
    {
        get;
        set;
    }
    string TaskName
    {
        get;
        set;
    }
}


