public interface ITip
{
    string Content
    {
        get;
    }

    bool ShouldShowTip(TutorialData tutorialData);

    void OnTipHide();
}
