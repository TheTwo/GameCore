using UnityEngine;

public class PauseUIController : MonoBehaviour {

    public void UpdateUI(GameData gameData)
    {
        GetComponent<SoundController>().UpdateUI(gameData);
    }

    public void OnRestartClick()
	{
		// 移除Banner
		// APIForXcode.RemoveBanner();

        Time.timeScale = 1;
        GameObject.FindObjectOfType<GameController>().Restart();
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            OnRestartClick();
        }
    }
}
