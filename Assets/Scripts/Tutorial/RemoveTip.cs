public class RemoveTip : ITip
{
    public string Content
    {
        get
        {
            return Localization.GetLanguage("RemoveTip");
        }
    }
    
    public bool ShouldShowTip(TutorialData tutorialData)
    {
        return tutorialData.Bang;
    }

    public void OnTipHide()
    {
    }
}
