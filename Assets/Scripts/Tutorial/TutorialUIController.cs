using UnityEngine;
using UnityEngine.UI;

public class TutorialUIController : MonoBehaviour
{
    public Text guideLabel;
    public Button OKBtn;
    public TypewriterEffect effect;

    private TutorialController tutorialController;

    void Start()
    {
        tutorialController = FindObjectOfType<TutorialController>();
    }

    public void UpdateUI(ITip tip)
    {
        guideLabel.text = tip.Content;
        effect.Run(TypewritterFinishCallback);
        OKBtn.gameObject.SetActive(false);
    }

    public void OnOKBtnClick()
    {
        SoundManager.instance.PlayingSound("Button");
        tutorialController.OnTutorialOKBtnClick();
    }

    private void TypewritterFinishCallback()
    {
        OKBtn.gameObject.SetActive(true);
    }
} 