using UnityEngine;
using UnityEngine.UI;

public class ShopRenderController : MonoBehaviour
{
    public Text priceText;
    public int currentIndex;
    public Text title;
    public Button btn;
    public GameObject priceGameobject;

    public delegate void RenderUpdate();
    
    // Declare the event. 
    public event RenderUpdate OnRenderUpdate;
        
    private int price;

    public void UpdateUI()
    {        
        btn.onClick.RemoveAllListeners();

		price = 100;// GameConfig.ROLE_PRICE_Dic ["Role" + currentIndex];
        
        priceText.text = price.ToString();
        
		if (GameData.IsRoleUnlocked(currentIndex))
        {            
			if (GameData.Instance.Role == currentIndex)
            {
                title.text = Localization.GetLanguage("Using"); 
                btn.interactable = false;
            }
            else
            {
                title.text = Localization.GetLanguage("Select"); 
                btn.interactable = true;
            }

            btn.interactable = true;
            priceGameobject.SetActive(false);
            btn.onClick.AddListener(OnSelectClick);
        }
        else
        {
            title.text = Localization.GetLanguage("Buy");

			if (GameData.Instance.Star < price)
            {
                priceText.color = Color.red;
                btn.interactable = false;
            }
            else
            {
                priceText.color = Color.white;
                btn.interactable = true;
            }



            priceGameobject.SetActive(true);
            btn.onClick.AddListener(OnBuyClick);
        }
    }

    private void OnBuyClick()
    {
		GameData.Instance.Star -= price;
        
		GameData.Instance.Role = currentIndex;
        
		GameData.Instance.UnlockRole(currentIndex);

        if(OnRenderUpdate != null)
        {
            OnRenderUpdate();
        }
    }

    private void OnSelectClick()
    {
		GameData.Instance.Role = currentIndex;
        FindObjectOfType<ShopUIController>().OnCloseBtnClick();
    }
}
