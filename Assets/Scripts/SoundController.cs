using UnityEngine;

public class SoundController : MonoBehaviour
{
    public GameObject EnableSprite;
    public GameObject DisalbeSprite;
    private GameData gameData;

    public void UpdateUI(GameData gameData)
    {
        this.gameData = gameData;

        if (gameData.SoundEnable)
        {
            EnableSprite.SetActive(true);
            DisalbeSprite.SetActive(false);
            SoundManager.instance.Mute(false);
        }
        else
        {
            EnableSprite.SetActive(false);
            DisalbeSprite.SetActive(true);
            SoundManager.instance.Mute(true);
        }
    }

    public void DisableSound()
    {
        gameData.SoundEnable = false;

        UpdateUI(gameData);
    }

    public void EnableSound()
    {
        gameData.SoundEnable = true;

        UpdateUI(gameData);
    }

}
