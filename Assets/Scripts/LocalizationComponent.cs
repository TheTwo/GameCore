using UnityEngine;
using UnityEngine.UI;

public class LocalizationComponent : MonoBehaviour
{
    void Start()
    {
        Text text = GetComponent<Text>();
        text.text = Localization.GetLanguage(text.text);
    }
}
