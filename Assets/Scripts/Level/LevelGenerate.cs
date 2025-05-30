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

            // 10%的概率生成加速方块
            if (ramdom < 10)
            {
                return elements.Find(e => e.cube.type == NodeType.SPEED)?.cube ?? elements[elements.Count - 1].cube;
            }

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


    private Dictionary<Vector3, Node> nodes;
    private GameObject level;
    private CubePool pool;
    private U3DAutoRestoreObjectPool StarPoll;

    private GameObject landscape;

    private bool invincible = false;

    private Snake snake;   

    private DynamicBorder leftBorder;
    private DynamicBorder rightBorder;
    private float currentPathWidth = 10f;  // 初始路径宽度

    public void Init()
    {
        level = GameObject.Find("Level");
        pool = FindObjectOfType<CubePool>();
        nodes = new Dictionary<Vector3, Node>(100);
        snake = FindObjectOfType<Snake>();
        
        StarPoll = GetComponent<U3DAutoRestoreObjectPool>();
        StarPoll.Init();
        
        // 初始化动态边界
        leftBorder = new DynamicBorder(5f, 10f, currentPathWidth);
        rightBorder = new DynamicBorder(5f, 10f, currentPathWidth);
        
        // 生成初始边界
        GenerateInitialBorders();
        
        for (int i = 10; i < 20; i++)
        {
            AddLevel(i);
        }
    }

    // 生成初始边界
    private void GenerateInitialBorders()
    {
        Vector3 startPos = new Vector3(-GameConfig.X_COUNT, 0, 0);
        Vector3 direction = Vector3.forward;
        
        // 生成左右边界
        for (int i = 0; i < 20; i++)  // 生成20个边界点
        {
            leftBorder.GenerateBorderPoint(startPos, direction);
            rightBorder.GenerateBorderPoint(startPos + Vector3.right * currentPathWidth, direction);
            
            // 随机调整方向
            direction = Quaternion.Euler(0, Random.Range(-15f, 15f), 0) * direction;
        }
    }

    // 动态扩展边界
    public void ExtendBorders()
    {
        // 获取最后一个边界点
        Vector3 lastLeftPoint = leftBorder.GetLastPoint();
        Vector3 lastRightPoint = rightBorder.GetLastPoint();
        
        // 计算新的方向
        Vector3 direction = (lastRightPoint - lastLeftPoint).normalized;
        
        // 生成新的边界点
        leftBorder.GenerateBorderPoint(lastLeftPoint, direction);
        rightBorder.GenerateBorderPoint(lastRightPoint, direction);
        
        // 更新路径宽度（可以随机变化）
        currentPathWidth = Mathf.Clamp(currentPathWidth + Random.Range(-1f, 1f), 8f, 12f);
    }

    public void HideLevel()
    {
        level.SetActive(false);
        snake.gameObject.SetActive(false);
    }

    public void ShowLevel()
    {
        level.SetActive(true);
        snake.gameObject.SetActive(true);
    }

    public void AddLevel(int addIndex)
    {      
        // 计算当前层级的中心点
        float levelRadius = 10f; // 每层的生成半径
        Vector3 centerPoint = new Vector3(addIndex, 0, addIndex);
        
        // 在圆形区域内生成方块
        float stepSize = 1.5f; // 增大步长，减少遍历点
        float angleStep = 20f; // 增大角度步长，减少遍历点
        float minDistance = 1.5f; // 增大元素之间的最小距离
        
        // 在圆形区域内生成方块
        for (float radius = 0; radius < levelRadius; radius += stepSize)
        {
            for (float angle = 0; angle < 360; angle += angleStep)
            {
                // 计算当前点的位置并四舍五入到整数
                float x = Mathf.Round(centerPoint.x + radius * Mathf.Cos(angle * Mathf.Deg2Rad));
                float z = Mathf.Round(centerPoint.z + radius * Mathf.Sin(angle * Mathf.Deg2Rad));
                Vector3 position = new Vector3(x, 0, z);
                
                // 检查是否与现有元素重叠
                bool canPlace = true;
                foreach (var node in nodes.Values)
                {
                    if (Vector3.Distance(position, node.transform.position) < minDistance)
                    {
                        canPlace = false;
                        break;
                    }
                }
                
                // 如果位置合适且满足生成概率，则生成新元素
                if (canPlace && Random.value < 0.1f) // 降低生成概率
                {
                    AddCubeAt(position, addIndex);
                }
            }
        }
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

                if(Nodes.ContainsKey(checkKey))
                {
                    if(snake != null)
                    {
                        snake.MeetBacisNode(Nodes[checkKey]);
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
        foreach (KeyValuePair<Vector3, Node> pair in Nodes)
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
            LevelRole currentRole = null;

            for(int i = 0; i < levelRoles.Count; i++)
            {
                if(addIndex > levelRoles[i].start)
                {
                    currentRole = levelRoles[i];
                }
            }

            Node generateNode = currentRole.Take();
            IAutoRestoreObject<GameObject> autoRestoreObjec = pool.Take(generateNode.type);
            GameObject cube = autoRestoreObjec.Get();
            cube.transform.parent = level.transform;
            Node node = cube.GetComponent<Node>();
            node.SetPosition(position);
            nodes.Add(position, node); 
            node.inSnake = false;
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
        pool.Restore(node);
        Nodes.Remove(node.transform.position);
        node.transform.parent = level.transform;
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

    // 获取指定层级的左边界点
    public Vector3 GetLeftBorderPoint(int level)
    {
        return leftBorder.GetPointAt(level);
    }

    // 获取指定层级的右边界点
    public Vector3 GetRightBorderPoint(int level)
    {
        return rightBorder.GetPointAt(level);
    }

    // 检查位置是否在边界内
    public bool IsPositionInBounds(Vector3 position)
    {
        int currentLevel = (int)(Mathf.Max(position.x, position.z) * 1.414f);
        Vector3 leftPoint = GetLeftBorderPoint(currentLevel);
        Vector3 rightPoint = GetRightBorderPoint(currentLevel);
        
        // 计算点到边界的距离
        float distanceToLeft = Vector3.Distance(position, leftPoint);
        float distanceToRight = Vector3.Distance(position, rightPoint);
        
        // 如果距离小于某个阈值，认为超出边界
        return distanceToLeft >= 0.5f && distanceToRight >= 0.5f;
    }

#if UNITY_EDITOR
    [MenuItem("Tools/AddBorder")]
    public static void AddBorder()
    {
        // 移除旧的边界生成方法
        // GenerateBorder();
    }

    [MenuItem("Tools/AddGrid")]
    public static void DrawGrid()
    {
        LineRenderer line = (Resources.Load("Line") as GameObject).GetComponent<LineRenderer>();

        for(int i = -10; i < 100; i++)
        {
            LineRenderer newline = Instantiate(line) as LineRenderer;
            newline.SetPosition(0, new Vector3(0.5f+ i, -0.5f, 100f));
            newline.SetPosition(1, new Vector3(0.5f+ i, -0.5f, -100f));
            
            newline.SetWidth(0.2f, 0.2f);
            
            LineRenderer newline2 = Instantiate(line) as LineRenderer;
            newline2.SetPosition(0, new Vector3(100f, -0.5f, 0.5f+ i));
            newline2.SetPosition(1, new Vector3(-100f, -0.5f, 0.5f+ i));
            
            newline2.SetWidth(0.2f, 0.2f);
        }
    }

#endif
}
