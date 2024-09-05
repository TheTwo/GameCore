using UnityEngine;
using UnityEngine.Advertisements;
using UnityEngine.UI;
using Com.Duoyu001.Pool.U3D;

public class GiftUIController : MonoBehaviour
{
    public Transform flareParent;
    public Button giftButton;
    public Button adButton;
    public Text countDown;
    public GameObject notificationIcon;
    public U3DAutoRestoreObjectPool pool;

    public Text giftReward;
    public Text adReward;

    public bool isShowing;

    private GameData gameData;

    void Awake()
    {
        pool.Init();
    }

    void Start()
    {
        if (gameData == null)
        {
            gameData = FindObjectOfType<GameController>().GameData;
        }

        UpdataNotifictionIcon();

        giftReward.text = "0 - " + GameConfig.MAX_TIME_GIFT_REWARD;
        adReward.text = GameConfig.AD_REWARD.ToString();
    }

    void Update()
    {
        if (isShowing && Input.GetKeyDown(KeyCode.Escape))
        {
            FindObjectOfType<StartUIController>().HideGift();
        }
    }

    public void UpdateUI(GameData data)
    {
        gameData = data;

        if (TimeSince2001() - gameData.GiftReceiveTime > GameConfig.GIFT_GAP)
        {
            giftButton.interactable = true;
        }
        else
        {
            giftButton.interactable = false;
        }

        UpdataNotifictionIcon();

        InvokeRepeating("UpdateTimeLabel", 0, 1);

		adButton.interactable = true;
    }

    private void UpdataNotifictionIcon()
    {
        if (TimeSince2001() - gameData.GiftReceiveTime > GameConfig.GIFT_GAP)
        {
            notificationIcon.SetActive(true);
        }
        else
        {
            notificationIcon.SetActive(false);
        }
    }

    void UpdateTimeLabel()
    {
        if (GameConfig.GIFT_GAP + gameData.GiftReceiveTime - TimeSince2001() <= 0)
        {
            CancelInvoke();
            countDown.text = Localization.GetLanguage("Tap To Gain");
            giftButton.interactable = true;
        }
        else
        {
            countDown.text = FormatSecond((int)(GameConfig.GIFT_GAP + gameData.GiftReceiveTime - TimeSince2001()));
        }
    }

	private void ThereIsNoAD()
	{
		Time.timeScale = 1;
	}
	private void FinishVideo()
	{
		Time.timeScale = 1;
		
		AddFlare();
		gameData.Star += GameConfig.AD_REWARD;
		FindObjectOfType<StartUIController>().UpdateUI(gameData);
		IOSNotification.NotificationMessage("一大堆免费金币已经刷新，快来领取吧，有了金币就可以解锁更多角色了！",System.DateTime.Now.AddSeconds(GameConfig.GIFT_GAP),false);
	}
    public void OnADClick()
	{
		//Time.timeScale = 0;

		//	Advertisement.Initialize("1110066", false);
		//	if (Advertisement.IsReady("rewardedVideo"))
		//	{
		//		// Show with default zone, pause engine and print result to debug log
		//		Advertisement.Show("rewardedVideo", new ShowOptions {               
		//			resultCallback = result => {
		//				Debug.Log(result.ToString());
		//				if(result == ShowResult.Finished)
		//				{
		//					FinishVideo();
		//				}
		//			}
		//		});
		//	}
    }

    private string FormatSecond(int second)
    {
        return new System.DateTime(2001, 1, 1).AddSeconds(second).ToLongTimeString();
    }

    private double TimeSince2001()
    {
        System.DateTime centuryBegin = new System.DateTime(2001, 1, 1);
        System.DateTime currentDate = System.DateTime.Now;
        
        long elapsedTicks = currentDate.Ticks - centuryBegin.Ticks;
        System.TimeSpan elapsedSpan = new System.TimeSpan(elapsedTicks);

        return elapsedSpan.TotalSeconds;
    }

    public void OnGiftClick()
    {
        AddFlare();

        int count = Random.Range(0,GameConfig.MAX_TIME_GIFT_REWARD);
        EffectManager.Instance.ShowStarAdd(count);

        gameData.Star += count;
        gameData.GiftReceiveTime = (float)(TimeSince2001());
        UpdateUI(gameData);
        FindObjectOfType<StartUIController>().UpdateUI(gameData);
        #if UNITY_IPHONE
        UnityEngine.iOS.NotificationServices.RegisterForNotifications(UnityEngine.iOS.NotificationType.Alert | UnityEngine.iOS.NotificationType.Badge | UnityEngine.iOS.NotificationType.Sound);
        #endif
    }

    public void AddFlare()
    {
        int count = 100;//Random.Range(5, 20);
        for (int i = 0; i < count; i++)
        {
            GameObject flare = pool.Take().Get();
            flare.transform.localScale = Vector3.one * Random.value;
            flare.transform.localPosition = Vector3.up * 10; //new Vector3((Random.value - 0.5f) * 640, (Random.value - 0.5f) * 1136, 0);
            flare.GetComponent<Rigidbody2D>().AddForce(new Vector2((Random.value - 0.5f) * 22400, Random.value * 31360));
            flare.GetComponent<Rigidbody2D>().AddTorque(100);
        }       
    }
}
