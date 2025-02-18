using UnityEngine;
using System.Collections.Generic;
using System;
using Com.Duoyu001.Pool.U3D;
using Com.Duoyu001.Pool;

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

            Node ret = elements [elements.Count - 1].cube;
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

    public void Init()
    {
        level = GameObject.Find("Level");
        pool = FindObjectOfType<CubePool>();
        nodes = new Dictionary<Vector3, Node>(100);
        snake = FindObjectOfType<Snake>();
        
        StarPoll = GetComponent<U3DAutoRestoreObjectPool>();
        StarPoll.Init();
        
        for (int i = 10; i < 20; i++)
        {
            AddLevel(i);
        }
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
        Line a = new Line(1, GameConfig.X_COUNT - 1);
        Line b = new Line(1, -GameConfig.X_COUNT -1);
        Line c = new Line(-1, 1.414f * addIndex);

        Vector2 pointTop = Line.Cross(a, c);
        Vector2 pointBottom = Line.Cross(b, c);

        int min = Mathf.FloorToInt(pointTop.x);
        int max = Mathf.CeilToInt(pointBottom.x);

        for(int i = min; i < max; i++)
        {
            int y = (int)c.Y(i);

            if (UnityEngine.Random.value < 0.2f)
            {
                AddCubeAt(new Vector3(i, 0, y), addIndex);
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
//            int index = UnityEngine.Random.Range(0, GameConfig.Instance.Nodes.Length);
//            NodeType type = GameConfig.Instance.Nodes [index].type;

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

//            AddStar(position);
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

    private static void GenerateBorder()
    {
        Line left = new Line(1, GameConfig.X_COUNT * 2);
        Line right = new Line(1, - GameConfig.X_COUNT * 2);
        GameObject landscape = GameObject.Find("Landscape");

        GameObject prefab = Resources.Load("Landmine") as GameObject;

        for (float x = -25; x < 55f; x++)
        {
            GameObject landmine = Instantiate(prefab) as GameObject;
            landmine.transform.position = new Vector3(x, 0, left.Y(x));
            landmine.transform.localScale = Vector3.one;
            landmine.transform.parent = landscape.transform;
        }

        for (float x = -20; x < 65f; x++)
        {
            GameObject landmine = Instantiate(prefab) as GameObject;
            landmine.transform.position = new Vector3(x, 0, right.Y(x));
            landmine.transform.localScale = Vector3.one;
            landmine.transform.parent = landscape.transform;
        }
    }
#if UNITY_EDITOR
    [MenuItem("Tools/AddBorder")]
    public static void AddBorder()
    {
        GenerateBorder();
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
