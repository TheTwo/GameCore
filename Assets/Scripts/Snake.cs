using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class Snake : MonoBehaviour
{
    public List<Node> snakeNodes;
    public LevelGenerate level;
    public Node lastNode;
    public GameController gameController;

    private HeadNode head;
    private Vector3[] directions = {new Vector3(1, 0, 0),new Vector3(0, 0, 1)};
    private Vector3 headDirection;
    private bool gameOver = false;
    private bool gameStart;
    private GameData gameData;
    private Quaternion targetQuternion = Quaternion.identity;
    private int addScore = 1;
    private LevelGenerate levelGenerate;
    private Vector3 gameOverPlace;

    private Animator headAnimator;
    private int currentLevel = 0;
    private GameUIController gameUIController;

    private bool transforming = false;

//    private bool invinsibleSpeedUp;

    private TutorialData tutorialData;

    private float originalSpeed;
    private float speedBoostEndTime = 0f;
    private bool isSpeedBoosted = false;

    void Start()
    {
        headDirection = directions [1];

        levelGenerate = GameObject.Find("Level").GetComponent<LevelGenerate>();

        tutorialData = FindObjectOfType<TutorialController>().TutorialData;

        UpdateHead();
    }

    public void Revive()
    {
        float distance = Vector3.Dot(gameOverPlace.normalized, new Vector3(1, 0, 1).normalized) * gameOverPlace.magnitude;
        int revive = (int)(distance / 1.414f);
        Vector3 revivePosition = new Vector3(revive, 0, revive);

        InitHead(revivePosition);
        snakeNodes.Clear();

        snakeNodes.Add(head);
        lastNode = head;
        headDirection = directions [1];

        gameOver = false;

        if (headAnimator != null)
        {
            headAnimator.enabled = true;
        }

        Camera.main.GetComponent<CameralFollow>().enabled = true;

        StartInvincible(GameConfig.INVINSIBLE_TIME);
    }

    public void StartInvincible(float second)
    {
        if (!gameData.isSnakeInvinciable)
        {
            transforming = false;
            head.status = NodeStatus.TRANSFORMING;
        }
        
        head.StopMoveBy();
        CancelInvoke();
        gameData.isSnakeInvinciable = true;
        gameData.Energy = GameConfig.MAX_ENERGY;

		Debug.Log (gameData.Level % (GameConfig.LevelSpeed.Count));
		gameData.NodeSpeed = GameConfig.INVINCIBLE_SPEED;
        gameData.totalInvinciableTime = gameData.remainInvinciableTime = second;
//        FindObjectOfType<CameralFollow>().Speed = 3;
//        invinsibleSpeedUp = true;

//        EffectManager.Instance.ShowTapTip();

//        int targetRow = (int)(head.transform.position.z);
//        int targetCol = (int)(head.transform.position.x);
//        
//        int checkingLevel = (int)(Mathf.Max(targetCol, targetRow));
//
//        levelGenerate.AddInvinsibleLevel(checkingLevel);

//        head.transform.localScale = Vector3.one * 3;

        for (int i = 1; i < snakeNodes.Count; i++)
        {
            StartCoroutine(AddFlyText(i, snakeNodes [i].transform.position, i * 0.25f));
            snakeNodes [i].RemoveFromSnake(this, i);
        }

        InvokeRepeating("ShakeCamera", 0, GameConfig.INVINSIBLE_CAMERA_SHAKE_RATE);

        lastNode = headNode;

        headNode.ShowExplosionFX();
        
        TransformSnake();
    }

    private void ResetInvincible()  
    {
        head.status = NodeStatus.TRANSFORMING;
        head.StopMoveBy();
        gameData.isSnakeInvinciable = false;

        TransformSnake();

//        Debug.Log("ResetInvincible");

//        InvokeRepeating("ElapseEnergy", 1, 1);
    }

    private void ShakeCamera()
    {
        if(gameController.inTutorial || gameController.paused)
        {
            return;
        }

        if (gameData.remainInvinciableTime > 0)
        {
            // if(gameData.remainInvinciableTime > 2)
            {
                iTween.ShakePosition(Camera.main.gameObject, iTween.Hash("y", 0.2f, "x", 0.2f, "time", 0.2f));
            }

            level.Shake(head.transform.position);
            gameController.UpdateLevelSlider();
        }
        
        if (gameData.isSnakeInvinciable && head.status != NodeStatus.TRANSFORMING)
        {
            gameData.remainInvinciableTime -= GameConfig.INVINSIBLE_CAMERA_SHAKE_RATE;
        }

        if (gameData.remainInvinciableTime <= 0)
        {
            ResetInvincible();
        }

    }

    void Update()
    {
        if (!gameStart || gameOver || gameController.inTutorial || gameController.paused)
        {
            return;
        }

        // 检查加速效果是否结束
        if (isSpeedBoosted && Time.time >= speedBoostEndTime)
        {
            gameData.NodeSpeed = originalSpeed;
            isSpeedBoosted = false;
        }

        head.transform.localRotation = Quaternion.Lerp(head.transform.localRotation, targetQuternion, Time.deltaTime * 10);

        CheckInput();
        
        if(head.status == NodeStatus.TRANSFORMING)
        {
            TransformSnake();
        }
        else
        {
            if (head.status == NodeStatus.NONE)
            {
                MoveSnake();    
            }
        }

        CheckOutOfScreen();

        if (!gameData.isSnakeInvinciable && (head.transform.position.x > head.transform.position.z + GameConfig.X_COUNT || head.transform.position.x < head.transform.position.z - GameConfig.X_COUNT))
        {
            GameOver();
        }
    }

    public void InitHead(Vector3 position)
    {
        if (head != null && head.role != PlayerPrefs.GetInt("role"))
        {
            snakeNodes.Remove(head);
            Destroy(head.gameObject); 
            head = null;
        }

        if (head == null || head.role != PlayerPrefs.GetInt("role"))
        {
            string path = "Head/Head" + PlayerPrefs.GetInt("role");
            GameObject g = Instantiate(Resources.Load(path)) as GameObject;
            head = g.GetComponent<HeadNode>();

            g.transform.position = position;
            g.transform.localScale = Vector3.one;
            g.transform.localRotation = targetQuternion = Quaternion.identity;

            g.transform.parent = transform;

            headAnimator = g.GetComponent<Animator>();
        }

//        headAnimator.enabled = false;
    }

    public void UpdateHead()
    {
        InitHead(Vector3.zero);
        snakeNodes = new List<Node>();    
        snakeNodes.Add(head);
        lastNode = head;
    }

    private void CheckOutOfScreen()
    {
        if (gameData.isSnakeInvinciable)
        {
            return;
        }

        if (Camera.main.WorldToScreenPoint(head.transform.position).y > Screen.height)
        {
            Debug.Log("out of screen ======");
            GameOver();
        }
    }

    private void CheckInput()
    {
        if (Input.GetMouseButtonDown(0) && Input.mousePosition.y < Screen.height * 3 / 4)
        {
//            if (invinsibleSpeedUp)
//            {
//                gameData.NodeSpeed = Mathf.Min(gameData.NodeSpeed + 2, GameConfig.MAX_SPEED);
//            }
//            else
//            {
                ChangeDirection();
//            }

            SoundManager.instance.PlayingSound("Button", 0.4f, Camera.main.transform.position);

//            EffectManager.Instance.ShowTouch(Input.mousePosition);
        }      
    }

    public void ChangeDirection()
    {
        if (headDirection == directions [0])
        {
            headDirection = directions [1];
            targetQuternion = Quaternion.identity;
        }
        else
        {
            headDirection = directions [0];
            targetQuternion = Quaternion.Euler(new Vector3(0, 90, 0));
        }

        SoundManager.instance.PlayingSound("Button", 0.4f);

        if (tutorialData != null)
        {
            tutorialData.ChangeDirection();
        }
    }

    public void OnStartGame(GameData gameData)
    {
        this.gameData = gameData;
        Invoke("RealStart", 0.01f);

        gameData.OnLevelUp += HandleOnLevelUp;
        gameData.OnGameDataChange += GameData_OnGameDataChange;
    }

    void GameData_OnGameDataChange (GameData gamedata)
    {
        if (head.role != gamedata.Role)
        {
            Vector3 position = head.position;

            snakeNodes.Remove(head);
            Destroy(head);

            InitHead(position);
        }
    }

    void HandleOnLevelUp(int level)
    {
        StartInvincible(GameConfig.INVINSIBLE_TIME);
    }

    public HeadNode headNode
    {
        get
        {
            return head;
        }
    }

    public void RealStart()
    {
        gameStart = true;

        if (headAnimator != null)
        {
            headAnimator.enabled = true;
        }
//        InvokeRepeating("ElapseEnergy", 1, 1);
    }

    public Dictionary<Vector3, Node> LevelNodes
    {
        get
        {
            return level.Nodes;
        }
    }

    private void TransformSnake()
    {
        if (gameData.isSnakeInvinciable)
        {
            if (!transforming)
            {
                transforming = true;
                iTween.MoveTo(head.gameObject, iTween.Hash("y", 1, "time", 1f,"easetype", iTween.EaseType.linear));
                
                // 0.3s localScale 变为 1
                iTween.ScaleTo(head.gameObject,
                    iTween.Hash("scale", Vector3.one * 3, "time", 1f, "oncomplete", "AnimationInvincibleEnd",
                        "oncompletetarget", gameObject, "easetype", iTween.EaseType.linear));
            }
        }
        else
        {
            if (!transforming)
            {
                transforming = true;
                
                // position 1s 变为 0
                iTween.MoveTo(head.gameObject, iTween.Hash("y", 0, "time", 2f,"easetype", iTween.EaseType.linear));
                
                // 0.3s localScale 变为 1
                iTween.ScaleTo(head.gameObject,
                    iTween.Hash("scale", Vector3.one, "time", 2f, "oncomplete", "AnimationResetInvincibleEnd",
                        "oncompletetarget", gameObject,"easetype", iTween.EaseType.linear));
            }
        }
    }

    private void AnimationInvincibleEnd()
    {
        transforming = false;
        head.status = NodeStatus.NONE;
        head.gameObject.transform.position = new Vector3(head.transform.position.x, 1, head.transform.position.z);
    }
    
    private  void AnimationResetInvincibleEnd()
    {
        transforming = false;
        head.status = NodeStatus.NONE;
        head.gameObject.transform.position = new Vector3(head.transform.position.x, 0, head.transform.position.z);
        
        head.transform.position = StablePostion(head.transform.position);
        
        gameData.NodeSpeed = GameConfig.LevelSpeed [gameData.Level % (GameConfig.LevelSpeed.Count)];

//        FindObjectOfType<CameralFollow>().Speed = 1;         

        gameController.UpdateLevelSlider();
        CancelInvoke();

        if(gameUIController == null)
        {
            gameUIController = FindObjectOfType<GameUIController>();
        }

        gameUIController.SetLevelUpSliderColor(Color.white);

        headNode.HideExplosionFX();
    }
    
    
    private void MoveSnake()
    {
        if (tutorialData != null)
        {
            tutorialData.MoveCount++;
        }

        BangTail();

        if (lastNode != null)
        { 
            Camera.main.GetComponent<CameralFollow>().target = lastNode.transform;
        }
        else
        {
            Debug.Log("last node is null =========");
        }
        
        Vector3 targetPosition = StablePostion(head.transform.position + headDirection);

		if (gameData.isSnakeInvinciable)
        {
            if (head.transform.position.x > head.transform.position.z + GameConfig.X_COUNT)
            {
                headDirection = directions [1];
                targetQuternion = Quaternion.identity;
            }
            else if(head.transform.position.x < head.transform.position.z - GameConfig.X_COUNT)
            {
                headDirection = directions [0];
                targetQuternion = Quaternion.Euler(new Vector3(0, 90, 0));
            }
        }

        Node aheadNode;
        LevelNodes.TryGetValue(targetPosition, out aheadNode);

        if (aheadNode != null)
        {
            SoundManager.instance.PlayingSound("Ting");
            aheadNode.MeetSnake(this);
            gameData.Energy += 2;

            if (headAnimator != null)
            {
                headAnimator.SetTrigger("Eat");
            }
        }

        Vector3 lastPostion = head.transform.position;

        if (!transforming)
        {
            head.MoveBy(headDirection, this, gameData);    
        }
      
        for (int i = 1; i < snakeNodes.Count; i++)
        {
            Vector3 temp = snakeNodes [i].transform.position;
            snakeNodes [i].Fllow(lastPostion, this, gameData);
            lastPostion = temp;
        }

        addLevel();     
    }

    private Vector3 StablePostion(Vector3 position)
    {
        return new Vector3(Mathf.RoundToInt(position.x), 0, Mathf.RoundToInt(position.z));
    }

    private void addLevel()
    {
        int targetRow = (int)(head.transform.position.z);
        int targetCol = (int)(head.transform.position.x);

        int checkingLevel = (int)(Mathf.Max(targetCol, targetRow) * 1.414f) + 20;
        if (checkingLevel > currentLevel)
        {
            currentLevel = checkingLevel;
            level.AddLevel(currentLevel);
        }
    }

    private void BangTail()
    {       
        Node last = snakeNodes [0];

        for (int i = 1; i < snakeNodes.Count; i++)
        {
            if (snakeNodes [i].gameObject.activeSelf && snakeNodes [i].transform.position.x < last.transform.position.x || snakeNodes [i].transform.position.z < last.transform.position.z)
            {
                last = snakeNodes [i];
            }
        }

        lastNode = last;

        if (snakeNodes.Count < 4)
        {
            return;
        }

        Node checkingNode = snakeNodes [snakeNodes.IndexOf(last) - 1];
        NodeType checkingType = checkingNode.type;
        NodeType lastType = last.type;

        if (checkingType == lastType)
        {
            return;
        }

        List<Node> remove = new List<Node>();
        remove.Add(checkingNode);
        for (int i = snakeNodes.IndexOf(checkingNode) - 1; i >= 0; i--)
        {
            if (snakeNodes [i].type == checkingType)
            {
                remove.Add(snakeNodes [i]);
            }
            else
            {
                break;
            }
        }

        if (remove.Count >= 3)
        {
            int addScore = 0;
            foreach (Node node in remove)
            {
                if (node.inSnake)
                {
                    node.inSnake = false;
                    node.RemoveFromSnake(this, ++addScore);
                    StartCoroutine(AddFlyText(addScore, node.transform.position, addScore * 0.25f));
                    gameData.MatchCount++;
                }
            }

            if(tutorialData != null)
            {
                tutorialData.Bang = true;
            }
            SoundManager.instance.PlayingSound("AddScore");
        }
    }

    IEnumerator AddFlyText(int score, Vector3 position, float wait)
    {
        yield return new WaitForSeconds(wait);
        EffectManager.Instance.AddFlyText("+ " + score, position);
//        EffectManager.Instance.AddScoreEffect(position);
        EffectManager.Instance.ShowScoreFlare();
    }

    public void MeetBacisNode(Node basicNode)
    {
        if (basicNode == null)
        {
            return;
        }
		if (gameData.isSnakeInvinciable)
        {
            levelGenerate.AddAtom(basicNode.transform.position, GameConfig.NODE_COLOR_DIC[basicNode.type]);

            EffectManager.Instance.AddFlyText("+ " + addScore, basicNode.transform.position);
//            EffectManager.Instance.AddScoreEffect(basicNode.transform.position);
            EffectManager.Instance.ShowScoreFlare();
                        
            level.Restore(basicNode);
            gameController.AddScore(addScore);
        }
        else
        {
            headNode.SetEyeColor(basicNode.GetComponent<Renderer>().material.color);
            snakeNodes.Add(basicNode);
            basicNode.inSnake = true;
            basicNode.transform.parent = transform;
            LevelNodes.Remove(basicNode.transform.position);
            basicNode.gameObject.name = "snake_" + snakeNodes.Count;

            gameController.AddScore(basicNode.score);

            if(gameUIController == null)
            {
                gameUIController = FindObjectOfType<GameUIController>();
            }

            gameUIController.SetLevelUpSliderColor(GameConfig.NODE_COLOR_DIC[basicNode.type]);

            EffectManager.Instance.AddFlyText("+ " + addScore, basicNode.transform.position);
//            EffectManager.Instance.AddScoreEffect(basicNode.transform.position);
            EffectManager.Instance.ShowScoreFlare();
        }

        if (tutorialData != null)
        {
            tutorialData.SetNodes(snakeNodes);
        }
        gameData.EatCubeCount++;
    }

    public void MeetCoinNode(Node node)
    {
        gameController.AddStar(1);

        level.Restore(node);
    }

    public void MeetBadNode(Node badNode)
    {
		if (!gameData.isSnakeInvinciable)
        {
            levelGenerate.Restore(badNode);
            GameOver();
        }
    }

    public void MeetRainBowNode(Node rainbowNode)
    {
        levelGenerate.Restore(rainbowNode);

        StartInvincible(GameConfig.INVINSIBLE_TIME);
    }

    public void MeetLandMineBowNode()
    {
		if (!gameData.isSnakeInvinciable)
        {
            GameOver(); 
        }
    }

    public void GameOver(bool fromHead = true)
    {
        gameOver = true;

        gameOverPlace = head.transform.position;

        iTween.ShakePosition(Camera.main.gameObject, iTween.Hash("y", 0.3f, "time", 1.0f));
        
        Camera.main.GetComponent<CameralFollow>().enabled = false;
        
        foreach (Node node in snakeNodes)
        {
            node.StopAllCoroutines();
        }
        
        StartCoroutine(ChangeToBlack(fromHead));

        CancelInvoke();
    }

    public void ChangeColor()
    {
        
    }
    
    public void DestroyTail()
    {
        if (snakeNodes.Count > 1)
        {
            StartCoroutine(ChangeTailToBlack(true));
        }
    }
    
    IEnumerator ChangeTailToBlack(bool fromHead)
        {
            snakeNodes.Sort(delegate(Node x, Node y)
            {
                if(fromHead)
                {
                    return y.transform.position.sqrMagnitude.CompareTo(x.transform.position.sqrMagnitude);
                }
                else
                {
                    return x.transform.position.sqrMagnitude.CompareTo(y.transform.position.sqrMagnitude);
                }
            });
    
            int count = snakeNodes.Count;
            for (int i = 1; i < snakeNodes.Count; i++)
            {
                SoundManager.instance.PlayingSound("Tong", 0.5f, Camera.main.transform.position);
                snakeNodes [i].ChangeToColor(new Color(53f / 255, 49f / 255, 49f / 255));
                yield return new WaitForSeconds(0.3f / count);
            }
    
            while (snakeNodes.Count > 1)
            {
                SoundManager.instance.PlayingSound("Tong", 0.5f, Camera.main.transform.position);
    
    //            GameObject atom = GameObject.Instantiate(atomCube) as GameObject;
    //            atom.transform.position = snakeNodes [0].transform.position;
    ////            atom.transform.localScale = 0.5f * snakeNodes [0].transform.localScale;           
    //            atom.GetComponent<AtomCube>().Bomb();
    
                levelGenerate.AddAtom(snakeNodes [1].transform.position, new Color(53f / 255, 49f / 255, 49f / 255));
    
                GameObject.Destroy(snakeNodes [1].gameObject);
                snakeNodes.RemoveAt(1);
    
                yield return new WaitForSeconds(0.3f / count);
            }
    
            ScreenCapture.CaptureScreenshot("screen.png");
    
            yield return new WaitForSeconds(1f);
        }

    IEnumerator ChangeToBlack(bool fromHead)
    {
        snakeNodes.Sort(delegate(Node x, Node y)
        {
            if(fromHead)
            {
                return y.transform.position.sqrMagnitude.CompareTo(x.transform.position.sqrMagnitude);
            }
            else
            {
                return x.transform.position.sqrMagnitude.CompareTo(y.transform.position.sqrMagnitude);
            }
        });

        int count = snakeNodes.Count;
        for (int i = 0; i < snakeNodes.Count; i++)
        {
            SoundManager.instance.PlayingSound("Tong", 0.5f, Camera.main.transform.position);
            snakeNodes [i].ChangeToColor(new Color(53f / 255, 49f / 255, 49f / 255));
            yield return new WaitForSeconds(0.3f / count);
        }

        while (snakeNodes.Count > 0)
        {
            SoundManager.instance.PlayingSound("Tong", 0.5f, Camera.main.transform.position);

//            GameObject atom = GameObject.Instantiate(atomCube) as GameObject;
//            atom.transform.position = snakeNodes [0].transform.position;
////            atom.transform.localScale = 0.5f * snakeNodes [0].transform.localScale;           
//            atom.GetComponent<AtomCube>().Bomb();

            levelGenerate.AddAtom(snakeNodes [0].transform.position, new Color(53f / 255, 49f / 255, 49f / 255));

            GameObject.Destroy(snakeNodes [0].gameObject);
            snakeNodes.RemoveAt(0);

            yield return new WaitForSeconds(0.3f / count);
        }

        ScreenCapture.CaptureScreenshot("screen.png");

        yield return new WaitForSeconds(1f);

        gameController.GameEnd(gameData);
    }

    private void ElapseEnergy()
    {
		if (!gameData.isSnakeInvinciable)
        {
            gameData.Energy -= 1;
            
            if (gameData.Energy < 0)
            {
                GameOver(false);
            }
        }
    }

    public void ChangeCubeType(NodeType targetType)
    {
        StartCoroutine(ChangeToType(targetType));
    }

    IEnumerator ChangeToType(NodeType targetType)
    {
        // 逐个节点改变类型
        int count = snakeNodes.Count;
        
        // 移除所有节点
        for (int i = 1; i < count; i++)
        {
            var node = snakeNodes[i];
            node.inSnake = false;
            node.RemoveFromSnake(this, 0);
            yield return new WaitForSeconds(0.3f / count);
        }
        
        for (int i = 1; i < count; i++)
        {
            SoundManager.instance.PlayingSound("Tong", 0.5f, Camera.main.transform.position);
            
            var basicNode = levelGenerate.GenerateNode(targetType);
            snakeNodes.Add(basicNode);
            basicNode.inSnake = true;
            basicNode.transform.parent = transform;
            
            yield return new WaitForSeconds(0.3f / count);
        }
    }

    public void MeetSpeedNode(SpeedNode speedNode)
    {
        if (!isSpeedBoosted)
        {
            // 保存原始速度
            originalSpeed = gameData.NodeSpeed;
            // 应用加速效果
            gameData.NodeSpeed *= speedNode.GetSpeedBoostMultiplier();
            // 设置加速结束时间
            speedBoostEndTime = Time.time + speedNode.GetSpeedBoostDuration();
            // 设置加速状态
            isSpeedBoosted = true;
            // 显示加速特效
            EffectManager.Instance.ShowSpeedBoostEffect(transform.position);
        }

        // 销毁加速块
        speedNode.gameObject.SetActive(false);
        // 从LevelGenerate的nodes字典中移除
        LevelGenerate levelGenerate = FindObjectOfType<LevelGenerate>();
        if (levelGenerate != null)
        {
            levelGenerate.Restore(speedNode);
        }
    }
}
