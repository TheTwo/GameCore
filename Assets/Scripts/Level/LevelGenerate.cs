using UnityEngine;
using System.Collections.Generic;
using System;
using Com.Duoyu001.Pool.U3D;
using Com.Duoyu001.Pool;
using Random = UnityEngine.Random;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class LevelGenerate : MonoBehaviour
{
    public GameObject atomCube;
    public Snake snake; // Make public to be assigned in Inspector

    [Serializable]
    public class LevelRoleElement
    {
        public Node cube;
        public int probability;
    }

    [Serializable]
    public class LevelRole
    {
        public int start;
        
        public List<LevelRoleElement> elements;// = new List<LevelRoleElement>();
        
        public Node Take()
        {           
            int ramdom = UnityEngine.Random.Range(0, 100);

            Node ret = elements[elements.Count - 1].cube;
            int probabilitySum = 0;

            for (int i = 0; i < elements.Count; i++)
            {
                probabilitySum += elements[i].probability;

                if(ramdom < probabilitySum)
                {
                    ret = elements[i].cube;
                    break;
                }
            }
            return ret;
        }
    }

    public GameObject StarPrefab;
    public List<LevelRole> levelRoles;// = new List<LevelRole>();
    public GameController gameController; // Add a public reference to GameController


    private Dictionary<Vector3, Node> nodes;
    private GameObject level;
    private CubePool pool;
    private U3DAutoRestoreObjectPool StarPoll;

    private GameObject landscape;

    private bool invincible = false;

    private Transform snakeHead; // The actual moving part of the snake

    // --- Start of new fields for dynamic generation ---
    private readonly LinkedList<Vector3> activeChunkCenters = new LinkedList<Vector3>();
    private Vector3 lastGeneratedChunkCenter;
    private int chunksGenerated = 0;

    [Header("Dynamic Generation Settings")]
    public float generationDistance = 40f; // When to generate the next chunk, relative to the player.
    public float destructionDistance = 60f; // When to destroy old chunks, relative to the player.
    public float chunkSize = 20f; // The forward distance each new chunk represents.
    private Vector3 currentGenerationDirection = Vector3.forward;
    // --- End of new fields ---

    public void PreInit()
    {
        level = GameObject.Find("Level");
        pool = FindObjectOfType<CubePool>();
        
        // Initialize the StarPoll here to prevent NullReferenceException
        StarPoll = GetComponent<U3DAutoRestoreObjectPool>();
        if (StarPoll != null)
        {
            StarPoll.Init();
        }
        else
        {
            Debug.LogError("LevelGenerate is missing the U3DAutoRestoreObjectPool component for stars!");
        }
    }

    public void Init()
    {
        // level and pool are already initialized in PreInit
        nodes = new Dictionary<Vector3, Node>(2000); // Increased capacity for dynamic loading
        if (snake != null && snake.headNode != null)
        {
            snakeHead = snake.headNode.transform;
        }
        else
        {
            Debug.LogError("Could not find the snake's head node!");
        }
        
        // StarPoll = GetComponent<U3DAutoRestoreObjectPool>(); // This line is now in PreInit
        // StarPoll.Init(); // This line is now in PreInit
        
        // --- Start of new initialization logic ---
        // Clear previous state
        foreach (var node in nodes.Values)
        {
            pool.Restore(node);
        }
        nodes.Clear();
        activeChunkCenters.Clear();
        chunksGenerated = 0;

        // Set starting point for generation just behind the snake's initial position
        if (snakeHead != null)
        {
            lastGeneratedChunkCenter = snakeHead.position - Vector3.forward * 10f;
        }
        else
        {
            lastGeneratedChunkCenter = Vector3.zero - Vector3.forward * 10f;
            Debug.LogError("Snake object not found! Starting generation at world origin.");
        }
        currentGenerationDirection = Vector3.forward;

        // Generate the initial set of chunks so the player has a starting area
        for (int i = 0; i < 3; i++)
        {
            GenerateNextChunk();
        }
        // --- End of new initialization logic ---
    }

    // --- New Update method for dynamic management ---
    // Update is now only responsible for destruction. Generation is triggered by the snake.
    void Update()
    {
        if (snakeHead == null || !snake.gameObject.activeInHierarchy) return;

        // Dynamic Destruction
        if (activeChunkCenters.Count > 0)
        {
            Vector3 oldestChunkCenter = activeChunkCenters.First.Value;
            if (Vector3.Distance(snakeHead.position, oldestChunkCenter) > destructionDistance)
            {
                if (Vector3.Dot((snakeHead.position - oldestChunkCenter).normalized, Vector3.forward) > 0)
                {
                    DestroyChunk(oldestChunkCenter);
                }
            }
        }
    }

    // This public method is now the entry point for triggering generation.
    public void RequestGenerationCheck(Vector3 futurePosition)
    {
        if (Vector3.Distance(futurePosition, lastGeneratedChunkCenter) < generationDistance)
        {
            GenerateNextChunk();
        }
    }
    
    // --- New Chunk Management Methods ---
    private void GenerateNextChunk()
    {
        // Create a winding path by slightly altering the direction for each new chunk.
        currentGenerationDirection = Quaternion.Euler(0, Random.Range(-15f, 15f), 0) * currentGenerationDirection;
        Vector3 nextChunkCenter = lastGeneratedChunkCenter + currentGenerationDirection.normalized * chunkSize;

        // Use chunksGenerated for difficulty scaling, similar to the old 'addIndex'
        GenerateChunk(nextChunkCenter, chunksGenerated);

        lastGeneratedChunkCenter = nextChunkCenter;
        activeChunkCenters.AddLast(nextChunkCenter);
        chunksGenerated++;
    }

    private void DestroyChunk(Vector3 chunkCenter)
    {
        float chunkDestroyRadius = chunkSize; // Use a radius larger than generation radius to ensure cleanup.
        List<Vector3> nodesToRemove = new List<Vector3>();

        // Find all nodes within the chunk's area
        foreach (var pair in nodes)
        {
            if (Vector3.Distance(pair.Key, chunkCenter) < chunkDestroyRadius)
            {
                nodesToRemove.Add(pair.Key);
                pool.Restore(pair.Value); // Return the node to the object pool
            }
        }

        // Remove the nodes from the active dictionary
        foreach (var pos in nodesToRemove)
        {
            nodes.Remove(pos);
        }

        if (activeChunkCenters.Count > 0)
        {
            activeChunkCenters.RemoveFirst();
        }
        
        Debug.Log($"Destroyed chunk centered at {chunkCenter}. Active chunks: {activeChunkCenters.Count}");
    }

    public void HideLevel()
    {
        if(level != null) level.SetActive(false);
        if(snake != null && snake.gameObject != null) snake.gameObject.SetActive(false);
    }

    public void ShowLevel()
    {
        if(level != null) level.SetActive(true);
        if(snake != null && snake.gameObject != null) snake.gameObject.SetActive(true);
    }

    public void GenerateChunk(Vector3 centerPoint, int difficultyIndex)
    {      
        float levelRadius = chunkSize / 2f; // Generate in a radius related to chunk size
        float stepSize = 1.5f; // 增大步长，减少遍历点
        float angleStep = 20f; // 增大角度步长，减少遍历点
        float minDistance = 1.5f; // 增大元素之间的最小距离
        int generatedInChunk = 0;
        
        // 在圆形区域内生成方块
        for (float radius = 0; radius < levelRadius; radius += stepSize)
        {
            for (float angle = 0; angle < 360; angle += angleStep)
            {
                // 计算当前点的位置并四舍五入到整数
                float x = centerPoint.x + radius * Mathf.Cos(angle * Mathf.Deg2Rad);
                float z = centerPoint.z + radius * Mathf.Sin(angle * Mathf.Deg2Rad);
                Vector3 position = new Vector3(Mathf.Round(x), 0, Mathf.Round(z));
                
                // Check if a node already exists at this rounded position to prevent overlap.
                if (nodes.ContainsKey(position))
                {
                    continue;
                }
                
                // 如果位置合适且满足生成概率，则生成新元素
                if (Random.value < 0.25f) // 降低生成概率
                {
                    AddCubeAt(position, difficultyIndex);
                    generatedInChunk++;
                }
            }
        }
        Debug.Log($"Generated chunk at {centerPoint} with {generatedInChunk} elements. Total nodes: {nodes.Count}");
    }

    public void AddInvinsibleLevel(int startIndex)
    {
        int y = AddInvinsibleX(startIndex);

        int x = AddInvinsibleY(y);

        Debug.Log(x);

        AddInvinsibleX(x);
    }

    public int AddInvinsibleX(int x)
    {
        Line a = new Line(1, GameConfig.X_COUNT);
        Line b = new Line(1, -GameConfig.X_COUNT);
        
        int topY = Mathf.CeilToInt(a.Y(x));
        int bottomY = Mathf.FloorToInt(b.Y(x));
        
        for (int i = bottomY; i < topY; i++)
        {
            AddCubeAt(new Vector3(x + UnityEngine.Random.Range(-1,2), 0, i), x);
            AddCubeAt(new Vector3(x - 1 + UnityEngine.Random.Range(-1,2), 0, i), x);
        }

        return topY;
    }

    public int AddInvinsibleY(int y)
    {
        Line a = new Line(1, GameConfig.X_COUNT);
        Line b = new Line(1, -GameConfig.X_COUNT);
        
        int leftX = Mathf.CeilToInt(a.X(y));
        int rightX = Mathf.FloorToInt(b.X(y));
        
        for (int i = leftX; i < rightX; i++)
        {
            AddCubeAt(new Vector3(i, 0, y+ UnityEngine.Random.Range(-1,2)), y);
            AddCubeAt(new Vector3(i, 0, y - 1 + UnityEngine.Random.Range(-1,2)), y);
        }

        return rightX;
    }

    public void BeginInvincible()
    {
        invincible = true;
        ChangeCubeToCoin();
    }

    public void EndInvincible()
    {
        invincible = false;
    }

    private List<Node> remove = new List<Node>(10);

    public void Shake(Vector3 shakePosition)
    {
//        remove.Clear();
//
//        foreach (KeyValuePair<Vector3, Node> pair in Nodes)
//        {
//            if(Vector3.Distance(pair.Key, shakePosition) < GameConfig.INVINSIBLE_SHAKE_RANGE)
//            {
//                remove.Add(pair.Value);
//            }
//        }

        int centerX = (int)(shakePosition.x);
        int centerZ = (int)(shakePosition.z);
        Vector3 checkKey = Vector3.zero;

        for (int x = centerX - GameConfig.INVINSIBLE_SHAKE_RANGE; x <= centerX + GameConfig.INVINSIBLE_SHAKE_RANGE; x++)
        {
            for(int z = centerZ - GameConfig.INVINSIBLE_SHAKE_RANGE; z <= centerZ + GameConfig.INVINSIBLE_SHAKE_RANGE; z++)
            {
                checkKey.x = x;
                checkKey.z = z;

                if(nodes.ContainsKey(checkKey))
                {
                    if(snake != null)
                    {
                        snake.MeetBacisNode(nodes[checkKey]);
                    }
                }
            }
        }

//        for(int i = 0; i < remove.Count; i++)
//        {
//            if(snake != null)
//            {
//                snake.MeetBacisNode(remove[i]);
//            }
//            else
//            {
//                Debug.Log("snake is null");                 
//            }
//        }
    }

    private void ChangeCubeToCoin()
    {
        foreach (KeyValuePair<Vector3, Node> pair in nodes)
        {
            if(pair.Value != null)
            {
            Vector3 position = pair.Value.transform.position;

            IAutoRestoreObject<GameObject> autoRestoreObjec = pool.Take(NodeType.Coin);
            
            GameObject cube = autoRestoreObjec.Get();
            
            cube.transform.parent = level.transform;
            
            Node node = cube.GetComponent<Node>();
            node.SetPosition(position);

//            Restore(pair.Value);

            pair.Value.gameObject.SetActive(false);
            }
        }

        nodes.Clear();
    }

    public void AddCubeAt(Vector3 position, int addIndex)
    {
        if (invincible)
        {
            IAutoRestoreObject<GameObject> autoRestoreObjec = pool.Take(NodeType.Coin);
            
            GameObject cube = autoRestoreObjec.Get();
            
            cube.transform.parent = level.transform;
            
            Node node = cube.GetComponent<Node>();
            node.SetPosition(position);
        }
        else if (!nodes.ContainsKey(position))
        {
            LevelRole role = null;

            for (int i = 0; i < levelRoles.Count; i++)
            {
                if (addIndex >= levelRoles[i].start)
                {
                    role = levelRoles[i];
                }
            }

            // If no specific role was found (e.g., at the very beginning of the level),
            // default to the first role in the list as a fallback.
            if (role == null && levelRoles.Count > 0)
            {
                role = levelRoles[0];
            }

            // If levelRoles is empty or something went wrong, prevent crash.
            if (role == null)
            {
                Debug.LogError("Cannot generate cube: No suitable LevelRole found and levelRoles list is empty.");
                return;
            }
            
            // The 'Take()' method on the role returns a prefab/template for the node.
            Node nodePrefab = role.Take();
            
            // Use the NodeType from the prefab to get an actual GameObject from the pool.
            IAutoRestoreObject<GameObject> pooledObjectContainer = pool.Take(nodePrefab.type);
            GameObject cubeGO = pooledObjectContainer.Get();

            // Initialize the node immediately after getting it from the pool, BEFORE setting its position or parent.
            var basicNode = cubeGO.GetComponent<BasicNode>();
            if (basicNode != null)
            {
                basicNode.Init(this, gameController);
            }

            cubeGO.transform.parent = level.transform; // Set parent first

            // Get the Node component from the pooled GameObject and configure it.
            Node cube = cubeGO.GetComponent<Node>();
            cube.transform.position = position;
            cube.transform.rotation = Quaternion.identity;
            
            nodes.Add(position, cube); 
            cube.inSnake = false;
        }
    }
    
    public Node GenerateNode(NodeType type)
    {
        IAutoRestoreObject<GameObject> autoRestoreObjec = pool.Take(type);
        GameObject cube = autoRestoreObjec.Get();
        Node node = cube.GetComponent<Node>();
        return node;
    }

    private void AddStar(Vector3 position)
    {
        IAutoRestoreObject<GameObject> autoRestoreObjec = StarPoll.Take();
        GameObject star = autoRestoreObjec.Get();
        TimeBaseChecker checker = star.GetComponent<TimeBaseChecker>();
        checker.Init(30f);
        autoRestoreObjec.Restore = checker;
        
        Vector3 targetPostion = position + new Vector3(UnityEngine.Random.value * 5, 0, UnityEngine.Random.value * 5);
        targetPostion.y = -0.49f;
        star.transform.position = targetPostion;
        star.transform.localRotation = Quaternion.Euler(new Vector3(90, 0, 0));
    }

    public void AddAtom(Vector3 position, Color color)
    {
        IAutoRestoreObject<GameObject> autoRestoreObjec = pool.Take(NodeType.Atom);        
        GameObject atom = autoRestoreObjec.Get();

        atom.transform.position = position;
        atom.transform.localScale = Vector3.one * 0.5f;
        atom.GetComponent<AtomCube>().Bomb();

        foreach(Renderer render in atom.GetComponentsInChildren<Renderer>())
        {
            render.material.color = color;
        }

    }

    public Dictionary<Vector3, Node>  Nodes
    {
        get
        {
            return nodes;
        }
    }

    public void Restore(Node node)
    {
        if(nodes.ContainsKey(node.transform.position))
        {
            nodes.Remove(node.transform.position);
            pool.Restore(node);
        }
    }

    private void Remove(int removeIndex)
    {
        for (int x=0; x< removeIndex; x++)
        {
            for (int y = 0; y< removeIndex; y++)
            {
                Vector3 removeKey = new Vector3(x, 0, y);
                if (nodes.ContainsKey(removeKey))
                {
                    Node node = nodes [removeKey];
                    pool.Restore(node.gameObject, node.type);
                    nodes.Remove(removeKey);
                }
            }
        }
    }

    // This method is obsolete as we are not using the old border system.
    // However, it's called by Snake.cs. We'll temporarily return a wide bound.
    // TODO: Refactor Snake.cs to not depend on this, or implement new bounds logic.
    public bool IsPositionInBounds(Vector3 position)
    {
        // For now, let's assume a generous width around the center-line (x=0)
        // This is a temporary measure to allow compilation.
        return true; // Mathf.Abs(position.x) < 20f; 
    }

#if UNITY_EDITOR
    [MenuItem("Tools/AddBorder")]
    public static void AddBorder()
    {
        // This is an editor tool for the old system and is no longer needed for dynamic generation.
        Debug.LogWarning("'AddBorder' is an obsolete tool from the old level generation system.");
    }

    [MenuItem("Tools/AddGrid")]
    public static void DrawGrid()
    {
        // This is an editor tool for the old system and is no longer needed for dynamic generation.
        Debug.LogWarning("'DrawGrid' is an obsolete tool from the old level generation system.");
    }

#endif
}

