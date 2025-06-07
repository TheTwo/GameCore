using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class Snake : MonoBehaviour
{
    public List<Node> snakeNodes;
    public Node lastNode;

    private HeadNode head;
    private Vector3[] directions = {new Vector3(1, 0, 0),new Vector3(0, 0, 1)};
    private Vector3 headDirection;
    private bool gameOver = false;
    private bool gameStart;
    private GameData gameData;
    private Quaternion targetQuternion = Quaternion.identity;
    private int addScore = 1;
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

    private LevelGenerate levelGenerate;
    private GameController gameController;

    public void PreInit(GameController gc, LevelGenerate lg)
    {
        this.gameController = gc;
        this.levelGenerate = lg;
        this.gameData = gc.GameData;

        headDirection = directions[1];

        Debug.Log("Attempting to find TutorialController...");
        TutorialController tutorialController = FindObjectOfType<TutorialController>();

        if (tutorialController == null)
        {
            Debug.Log("TutorialController is NULL. Skipping tutorial data setup.");
        }
        else
        {
            Debug.Log("TutorialController was FOUND. GameObject name: " + tutorialController.gameObject.name);
            tutorialData = tutorialController.TutorialData;
            if (tutorialData == null)
            {
                Debug.Log("tutorialController.TutorialData returned NULL.");
            }
        }
        
        gameData.OnLevelUp += HandleOnLevelUp;
        gameData.OnGameDataChange += GameData_OnGameDataChange;
    }

    public void Init()
    {
        Debug.Log("Snake.Init() called.");
        UpdateHead();
        Debug.Log("UpdateHead() finished in Snake.Init().");
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

            levelGenerate.Shake(head.transform.position);
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
    }

    public void InitHead(Vector3 position)
    {
        Debug.Log("InitHead called. Current head is " + (head == null ? "null" : "not null"));

        int role = PlayerPrefs.GetInt("role");
        Debug.Log("PlayerPrefs role is: " + role);

        if (head == null || head.role != role)
        {
            if (head != null)
            {
                Debug.Log("Existing head role " + head.role + " does not match new role " + role + ". Destroying old head.");
                snakeNodes.Remove(head);
                Destroy(head.gameObject);
                head = null;
            }

            string path = "Head/Head" + role;
            Debug.Log("Attempting to load prefab from path: " + path);

            Object prefab = Resources.Load(path);
            if (prefab == null)
            {
                Debug.LogError("FATAL: Failed to load head prefab from path: " + path + ". Make sure the prefab exists at this path in a Resources folder.");
                return; 
            }
            
            GameObject g = Instantiate(prefab) as GameObject;
            if (g == null)
            {
                Debug.LogError("FATAL: Failed to instantiate prefab from path: " + path);
                return;
            }
            
            Debug.Log("Prefab instantiated successfully.");
            
            head = g.GetComponent<HeadNode>();
            if (head == null) {
                Debug.LogError("FATAL: Instantiated prefab does not have a HeadNode component!");
                return;
            }
            Debug.Log("HeadNode component found successfully.");


            var basicNodeComponent = g.GetComponent<BasicNode>();
            if (basicNodeComponent != null)
            {
                Debug.Log("BasicNode component found, calling its Init.");
                basicNodeComponent.Init(levelGenerate, gameController);
            } else {
                Debug.LogWarning("Instantiated head prefab is missing a BasicNode component.");
            }

            g.transform.position = position;
            g.transform.localScale = Vector3.one;
            g.transform.localRotation = targetQuternion = Quaternion.identity;

            g.transform.parent = transform;

            headAnimator = g.GetComponent<Animator>();
            Debug.Log("InitHead finished successfully.");
        } else {
            Debug.Log("Skipping head creation because a valid head already exists.");
        }
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

        // if (Camera.main.WorldToScreenPoint(head.transform.position).y > Screen.height)
        // {
        //     Debug.Log("out of screen ======");
        //     GameOver();
        // }
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

    void HandleOnLevelUp(int level)
    {
        StartInvincible(GameConfig.INVINSIBLE_TIME);
    }

    void GameData_OnGameDataChange (GameData gamedata)
    {
        if (head.role != gamedata.Role)
        {
            Vector3 position = head.position;

            snakeNodes.Remove(head);
            Destroy(head.gameObject);

            InitHead(position);
        }
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
            return levelGenerate.Nodes;
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

        // --- Start of New Generation and Movement Logic ---

        // 1. Tell the level generator to check if it needs to generate based on our FUTURE position.
        levelGenerate.RequestGenerationCheck(targetPosition);

        // 2. Check for collisions at the future position.
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
        
        // 3. Move the snake bodies first.
        Vector3 lastPostion = head.transform.position;
        for (int i = 1; i < snakeNodes.Count; i++)
        {
            Vector3 temp = snakeNodes [i].transform.position;
            // Replace iTween with a direct, predictable movement
            snakeNodes[i].transform.position = Vector3.MoveTowards(snakeNodes[i].transform.position, lastPostion, gameData.NodeSpeed * Time.deltaTime);
            lastPostion = temp;
        }

        // 4. Finally, move the head.
        // Replace iTween with a direct, predictable movement
        head.transform.position = Vector3.MoveTowards(head.transform.position, targetPosition, gameData.NodeSpeed * Time.deltaTime);
        
        // --- End of New Generation and Movement Logic ---
    }

    private Vector3 StablePostion(Vector3 position)
    {
        return new Vector3(Mathf.RoundToInt(position.x), 0, Mathf.RoundToInt(position.z));
    }

    private void BangTail()
    {
        // --- FIX for incorrect tail logic (v4 - Final) ---

        // 1. Update the lastNode reference to be the actual tail.
        if (snakeNodes.Count > 0)
        {
            lastNode = snakeNodes[snakeNodes.Count - 1];
        }
        else
        {
            return; // No nodes to process
        }
        
        // 2. We need at least 3 body nodes (plus the head) to form a match of 3.
        if (snakeNodes.Count < 4)
        {
            return;
        }

        // 3. Check for a streak of 3 or more nodes of the same type at the tail end.
        NodeType tailType = lastNode.type;
        int streakCount = 0;
        
        // Iterate backwards from the tail to count the streak.
        for (int i = snakeNodes.Count - 1; i >= 1; i--) // Stop at index 1 (never check the head)
        {
            if(snakeNodes[i].type == tailType)
            {
                streakCount++;
            }
            else
            {
                break; // Streak broken
            }
        }

        // 4. If a streak of 3 or more is found, remove them.
        if (streakCount >= 3)
        {
            List<Node> nodesToRemove = new List<Node>();
            // Collect the nodes to be removed from the tail end.
            for(int i = 0; i < streakCount; i++)
            {
                nodesToRemove.Add(snakeNodes[snakeNodes.Count - 1 - i]);
            }

            int addScore = 0;
            foreach (Node node in nodesToRemove)
            {
                snakeNodes.Remove(node); // Remove from the snake's list
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
                        
            levelGenerate.Restore(basicNode);
            gameController.AddScore(addScore);
        }
        else
        {
            // --- FIX for incorrect body position (v2) ---
            
            // 1. Get the actual tail node, which is the last element in the list.
            Node currentTail = snakeNodes[snakeNodes.Count - 1];
            
            // 2. Store the original world position of the node being eaten.
            Vector3 originalPosition = basicNode.transform.position;

            // 3. Immediately move the new node to the current tail's position.
            //    The movement logic in Update() will then handle creating the space.
            basicNode.transform.position = currentTail.transform.position;
            
            // 4. Add the node to the snake's body list. It is now the new tail.
            headNode.SetEyeColor(basicNode.GetComponent<Renderer>().material.color);
            snakeNodes.Add(basicNode);
            lastNode = basicNode; // Explicitly update lastNode to be the new tail.

            basicNode.inSnake = true;
            basicNode.transform.parent = transform;

            // 5. Remove the node from the level dictionary using its ORIGINAL position.
            if (LevelNodes.ContainsKey(originalPosition))
            {
                LevelNodes.Remove(originalPosition); 
            }

            basicNode.gameObject.name = "snake_" + snakeNodes.Count;
            // --- END FIX ---

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

        levelGenerate.Restore(node);
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
