using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class ShopUIController : MonoBehaviour
{
	public GridLayoutGroup grid;
	public ScrollRect scrollRect;
	public Text moneyText;
	public Button nextBtn;
	public Button preBtn;

	public GameObject shopRender;

	private const int ROLES_COUNT = 22;
	private const string ROLE_PATH_PRE = "Roles/Role";
	private int currentIndex;
	private float targetHorizontalNormalizedPosition;
	private ShopRenderController[] renders;
	private bool initialized;
	private GameController gameController;

	public Transform renderParent;

	void Start ()
	{
		if (!initialized) {
			grid.GetComponent<RectTransform> ().sizeDelta = new Vector2 (grid.cellSize.x * ROLES_COUNT, 750);

			currentIndex = 0;
			ShowCurrent ();
			targetHorizontalNormalizedPosition = scrollRect.horizontalNormalizedPosition = 0;

			for (int i = 0; i < ROLES_COUNT; i++) {
				GameObject newRender = Instantiate (shopRender);
				newRender.transform.SetParent (grid.transform);
				newRender.SetActive (true);
				newRender.transform.localScale = Vector3.one;
				newRender.GetComponent<ShopRenderController> ().currentIndex = i;
			}

			renders = FindObjectsOfType<ShopRenderController> ();

			foreach (ShopRenderController render in renders) {
				render.OnRenderUpdate += OnRenderUpdate;
			}

			initialized = true;
		}

		Refresh ();
	}

	void Update ()
	{
		scrollRect.horizontalNormalizedPosition = Mathf.Lerp (scrollRect.horizontalNormalizedPosition, targetHorizontalNormalizedPosition, Time.deltaTime * 5);

		if (Input.GetKeyDown (KeyCode.Escape)) {
			OnCloseBtnClick ();
		}
	}

	void OnDestory ()
	{
		foreach (ShopRenderController render in renders) {
			render.OnRenderUpdate -= OnRenderUpdate;
		}
	}

	public void Refresh ()
	{
		foreach (ShopRenderController render in renders) {
			render.UpdateUI ();
		}

		moneyText.text = PlayerPrefs.GetInt (GameData.CUBE_COUNT).ToString ();
	}

	public void OnCloseBtnClick ()
	{
		SceneManager.LoadScene ("MainScene");
	}

	public void OnRenderUpdate ()
	{
		foreach (ShopRenderController render in renders) {
			render.UpdateUI ();
		}
	}

	public void ShowNext ()
	{
		currentIndex++;

		ShowCurrent ();
	}

	public void ShoePre ()
	{
		currentIndex--;


		ShowCurrent ();
	}

	private void ShowCurrent ()
	{
		targetHorizontalNormalizedPosition = currentIndex / (ROLES_COUNT - 1f);

		if (currentIndex == ROLES_COUNT - 1) {
			nextBtn.interactable = false;
		} else if (currentIndex == 0) {
			preBtn.interactable = false;
		} else {
			preBtn.interactable = true;
			nextBtn.interactable = true;
		}

		if (renderParent.childCount > 0) {
			DestroyObject (renderParent.GetChild (0).gameObject);
		}


		GameObject currentRole = Instantiate (Resources.Load ("Head/Head" + currentIndex)) as GameObject;
		currentRole.GetComponent<BasicNode> ().enabled = false;
		currentRole.transform.SetParent (renderParent);
		currentRole.transform.localPosition = Vector3.zero;
		currentRole.transform.localScale = Vector3.one;	
		currentRole.transform.localRotation = Quaternion.AngleAxis (0, Vector3.zero);
	}
}
