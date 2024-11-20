using System;
using UnityEngine;
using UnityEngine.SceneManagement;
using WeChatWASM;

// using WeChatWASM;
//using System.Collections;
//using cn.sharesdk.unity3d;

public class GameController : MonoBehaviour
{
	public UIController uiController;
	public Snake snake;
	public bool startCheckingRestore;
	public bool inTutorial = false;
	public bool paused = false;
	public TutorialController tutorialController;
	public Ranking ranking;

	public delegate void OnGameStarted (GameData gameData);

	public static event OnGameStarted OnGameStart;

	public bool inTutorialMode = false;

	private GameData gameData;
	private TutorialData tutorialData;

	private BackgroundController backgroundController;

	public CameralFollow cameralFollow;
	
	private WXRewardedVideoAd videoAd;
	private WXCustomAd customAdBottom;
	private WXCustomAd customAdTop;

//	public ShareSDK ssdk;

	void Awake ()
	{
		gameData = GameData.Instance;

		startCheckingRestore = false;
		backgroundController = FindObjectOfType<BackgroundController> ();
		backgroundController.Init();

		gameData.OnGameDataChange += HandleOnGameDataChange;
		Application.targetFrameRate = 60;

		FindObjectOfType<CubePool> ().Init ();
		FindObjectOfType<LevelGenerate> ().Init ();

		uiController.OnGameInit (gameData);

		HandleOnGameDataChange (gameData);

		Screen.sleepTimeout = SleepTimeout.NeverSleep; 
	}

	void OnDestroy ()
	{
		Debug.Log("-------------");
		gameData.OnGameDataChange -= HandleOnGameDataChange;
		GameData.Instance.Dispose();
	}

	void Start ()
	{
		WX.InitSDK(
			(code) =>
			{
				InitWX();
			}
		);

		SoundManager.instance.startBGM ();   

		if (PersistenceData.Instance.StartGameImmediatly) {
			StartGame ();
			PersistenceData.Instance.StartGameImmediatly = false;
		}

		tutorialData = FindObjectOfType<TutorialController> ().TutorialData;
	}

	private void InitWX()
	{
		WX.ReportGameStart();
		
		ranking.Init();
		
		// 创建激励视频广告实例，提前初始化
		var adParam = new WXCreateRewardedVideoAdParam();
		adParam.adUnitId = "adunit-ad4f10cca41ee2c7";
		videoAd = WX.CreateRewardedVideoAd(adParam);
		
		// 创建 原生模板 广告实例，提前初始化
		var styleBottom = new CustomStyle() { left = 0, top = Screen.height - 108, width = Screen.width };
		customAdBottom = new WXCustomAd("adunit-2a23b71cf12a6294", styleBottom);

		var styleTop = new CustomStyle() { left = 0, top = 0, width = Screen.width };
		customAdTop = new WXCustomAd("adunit-cd9a4114ac2b9bce", styleTop);
	}

	public void StartGame ()
	{
		cameralFollow.OnGameStart ();
        
		uiController.OnGameStart (gameData);
		snake.OnStartGame (gameData);
        
		startCheckingRestore = true;
        
		if (OnGameStart != null) {
			OnGameStart (gameData);
		}
	}

	public void OnTutorialFinish ()
	{
		cameralFollow.OnGameStart ();
        
		uiController.OnGameStart (gameData);
		snake.OnStartGame (gameData);
        
		startCheckingRestore = true;

		if (OnGameStart != null) {
			OnGameStart (gameData);
		}
	}

	public void GameEnd (GameData gameData)
	{
#if !UNITY_EDITOR 
        if (Social.Active.localUser.authenticated)
        {
        Social.ReportScore(gameData.HighScore, "com.ariequ.snake.hs", success => {
                Debug.Log(success ? "Reported score successfully" : "Failed to report score");
            });
        }
		
		
#endif
		ranking.ReportScore(gameData.HighScore);
		
		CancelInvoke ();

		uiController.OnGameEnd (gameData);
        
		// 每3次展现一次插屏广告
		if (gameData.countOfPlay % 3 == 0) {
			// APIForXcode.ShowInterstitial();
		}
		// 不显示插屏广告时才能显示Banner
		else {
			// 在屏幕底端显示Banner
			// APIForXcode.ShowBanner(false);
		}
//        Invoke("ShowAD", 2f);

		// 每局游戏结束后，显示原生模板广告
		customAdBottom.Show();
	}

	public void AddScore (int add)
	{
		gameData.Score += add;
		uiController.UpdateScore (add);

		if (tutorialData != null) {
			tutorialData.Score = gameData.Score;
		}
	}

	public void AddStar (int star)
	{
		gameData.Star += star;
		uiController.UpdateStar (gameData.Star);
	}

	public void UpdateLevelSlider ()
	{
		uiController.UpdateLevelSlider ();
	}

	public void Restart ()
	{
		gameData.countOfPlay++;
		// 点击重新开始按钮，可以复活了
		gameData.canRevive = true;
		gameData.reviceCount = 0;

		SoundManager.instance.PlayingSound ("Button", 1f, Camera.main.transform.position);
		PersistenceData.Instance.StartGameImmediatly = true;
		SceneManager.LoadScene("MainScene");
	}

	private void ThereIsNoAD()
	{
		Time.timeScale = 1;
	}
	private void Revive ()
	{
		Time.timeScale = 1;
		gameData.ReviveCount++;
		// 已经复活一次了，本局不能再次复活了
		if (gameData.ReviveCount >= GameData.MAX_REVIVE_COUNT) {
			gameData.canRevive = false;
		}
		
		gameData.Energy = GameConfig.MAX_ENERGY;
		uiController.OnGameStart (gameData);
		snake.Revive ();
	}
	public void ShowReviveAD ()
	{
		//Time.timeScale = 0;
		//	Advertisement.Initialize("1110066", false);
		//	if (Advertisement.IsReady ("rewardedVideo")) {
		//		// Show with default zone, pause engine and print result to debug log
		//		Advertisement.Show ("rewardedVideo", new ShowOptions {
		//			resultCallback = result => {
		//				Debug.Log (result.ToString ());
		//				if (result == ShowResult.Finished) {
		//					Revive ();
		//				}
		//			}
		//		});
		//	}
		
		videoAd.Show();
		
		videoAd.onCloseAction = (res) =>
		{
			if ((res != null && res.isEnded) || res == null)
			{
				Revive();
			}
			else
			{
				Debug.Log("广告未播放完毕");
			}
		};
		
		
		#if UNITY_EDITOR
			Revive();
		#endif
	}

	public void ShowLeaderboardUI ()
	{
		SoundManager.instance.PlayingSound ("Button", 1f, Camera.main.transform.position);

		//Social.localUser.Authenticate (success => {
		//	if (success) {
		//		Debug.Log ("Authentication successful");
		//		string userInfo = "Username: " + Social.localUser.userName +
		//		                              "\nUser ID: " + Social.localUser.id +
		//		                              "\nIsUnderage: " + Social.localUser.underage;
		//		Debug.Log (userInfo);

		//		GameCenterPlatform.ShowLeaderboardUI ("com.ariequ.snake.hs", UnityEngine.SocialPlatforms.TimeScope.AllTime);

		//	} else
		//		Debug.Log ("Authentication failed");
		//});
		
		ranking.ShowRanking();		
	}


	public void Pause ()
	{
		Debug.Log ("pause===========");

		SoundManager.instance.PlayingSound ("Button", 1f, Camera.main.transform.position);
//        Time.timeScale = 0;
		uiController.OnPause (gameData);
		paused = true;
		
		customAdTop.Show();
	}

	public void Resume ()
	{
		Debug.Log ("resume");
		// 移除Banner
		// APIForXcode.RemoveBanner();

		SoundManager.instance.PlayingSound ("Button", 1f, Camera.main.transform.position);
//        Time.timeScale = 1;
		uiController.OnResume ();
		paused = false;
		
		customAdTop.Hide();
	}

	public void HomePage ()
	{
		// 移除Banner
		// APIForXcode.RemoveBanner();
		
		// 每局游戏结束后，显示原生模板广告
		customAdBottom.Hide();

		SoundManager.instance.PlayingSound ("Button", 1f, Camera.main.transform.position);
		Time.timeScale = 1;
		SceneManager.LoadScene(0);
	}

	public void ShowExhibition ()
	{
		SceneManager.LoadScene("ShopScene");
	}

	//    public void Share()
	//    {
	//        Application.OpenURL("http://weibo.com/ariequ");
	//    }

	public void Reset ()
	{
		PlayerPrefs.DeleteAll ();
		HomePage ();
	}

	public void RemoveAd ()
	{
		// APIForXcode.RemoveAd();
	}

	public GameData GameData {
		get {
			return gameData;
		}
	}

	public void Share ()
	{   
//        ssdk.Authorize(0, PlatformType.WeChatTimeline);

//		Hashtable content = new Hashtable ();
//		content ["content"] = "《彩色尾巴》好玩到哭，我得到了***" + gameData.HighScore + "***分，快来一起HIGH吧！在安卓市场和AppStore搜索《彩色尾巴》就可以下载拉~";
//
//		content ["image"] = Application.persistentDataPath + "/screen.png";	
//
//		content ["title"] = "《彩色尾巴》好玩到哭，我得到了***" + gameData.HighScore + "***分，快来一起HIGH吧！在安卓市场和AppStore搜索《彩色尾巴》就可以下载拉~";
//		content ["description"] = "《彩色尾巴》好玩到哭，我得到了***" + gameData.HighScore + "***分，快来一起HIGH吧！在安卓市场和AppStore搜索《彩色尾巴》就可以下载拉~";
//
//		string url = "";
//
//		#if UNITY_IOS
//		url = "https://itunes.apple.com/app/cai-se-wei-ba/id955324802";
//		#else
//		url = "http://www.wandoujia.com/apps/com.ariequ.snake";
//		#endif
//
//		content ["url"] = url;
//		content ["type"] = ContentType.News;
//		content ["siteUrl"] = "http://weibo.com/ariequ";
//		content ["site"] = "作者微博";
////        content["musicUrl"] = "http://mp3.mwap8.com/destdir/Music/2009/20090601/ZuiXuanMinZuFeng20090601119.mp3";
//
////		ssdk.ShareContent (1, PlatformType.WeChatTimeline, content);

		ranking.Share(gameData.HighScore);
		
		Revive ();
		Pause();
	}

	void HandleOnGameDataChange (GameData gamedata)
	{
		backgroundController.ChangePlane (gameData.Level);
	}

	void OnApplicationPause (bool paused)
	{
		//程序进入后台时
		if (paused && uiController.GameUI.activeSelf && !inTutorial) {
			Pause ();
		}
	}
}
