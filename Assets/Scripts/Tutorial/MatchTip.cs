public class MatchTip : ITip
{
    public string Content
    {
        get
        {
            return Localization.GetLanguage("MatchTip");
        }
    }
    
    public bool ShouldShowTip(TutorialData tutorialData)
    {
        int length = tutorialData.SnakeNodes.Count;
        if (length > 3)
        {
            if(tutorialData.SnakeNodes[length -1].type == tutorialData.SnakeNodes[length -2].type && tutorialData.SnakeNodes[length -2].type == tutorialData.SnakeNodes[length - 3].type)
            {
                return true;
            }
        }

        return false;
    }

    public void OnTipHide()
    {
    }
}
