using UnityEngine;

public class NewIconController : MonoBehaviour
{
    public GameObject newIcon;

    public void Init(GameData data)
    {
        newIcon.SetActive(data.HasNew() || data.HasGift());
    }

    public void InitRole(GameData data)
    {
        newIcon.SetActive(data.HasNew());
    }
}
