using UnityEngine;
using System.Collections;

public class BasicNode : Node
{   
    protected  Vector3 targetPosition;
    private float scaleFactor = 0.01f;
    protected LevelGenerate level;
//    protected JellyMesh jellyMesh;
    protected GameController gameController;

    private Coroutine moveCoroutine;

    Color[] colors = new Color[]{Color.blue, Color.red, Color.black, Color.white, Color.green};

    void Start()
    {
        status = NodeStatus.NONE;
        level = GameObject.Find("Level").GetComponent<LevelGenerate>();
        scaleFactor += Random.value / 100;
//        jellyMesh = GetComponent<JellyMesh>();
        gameController = FindObjectOfType<GameController>();

    }

    void Update()
    {
        OnUpdate();
    }
    
    public override void OnUpdate()
    {
        if (gameController.startCheckingRestore && Camera.main.WorldToScreenPoint(transform.position).y < -5 && !inSnake)
        {
            level.Restore(this);
        }
    }

    public override void SetPosition(Vector3 position)
    {
        this.position = position;
        transform.position = position;
        transform.localScale = Vector3.one;
    }

    public override void MoveBy(Vector3 step, Snake snake, GameData gameData)
    {
        if (!gameObject.activeSelf)
        {
            Debug.Log(gameObject.name);
            Debug.Log("why!!!!!!");
            snake.snakeNodes.Remove(this);
            return;
        }   
        float scale = 0.9f + Random.value / 3;
        gameObject.transform.localScale = new Vector3(scale, scale, scale);
        targetPosition = transform.position + step;
        moveCoroutine = StartCoroutine(Move(snake, gameData));
    }
    
    public override void StopMoveBy()
    {
        if (moveCoroutine != null)
        {
            StopCoroutine(moveCoroutine);
        }
    }

    protected IEnumerator Move(Snake snake, GameData gameData)
    {
        status = NodeStatus.MOVING;
        float startTime = Time.time;
        Vector3 startPosition = transform.position;



        while (Vector3.Distance(transform.position,targetPosition) > 0.001f)
        {
            transform.position = Vector3.Lerp(startPosition, targetPosition, (Time.time - startTime) * gameData.NodeSpeed);
            yield return 1;
        }

        status = NodeStatus.NONE;
        yield return null;
    }

    public override void MeetSnake(Snake snake)
    {
        snake.MeetBacisNode(this);
    }

    public override void Fllow(Vector3 lastPostion, Snake snake, GameData gameData)
    {
        if (lastPostion.x > transform.position.x || lastPostion.z > transform.position.z)
        {
            transform.localScale = Vector3.one;
        }
        else
        {
            transform.localScale = new Vector3(GameConfig.Factor1 * (1 + scaleFactor), GameConfig.Factor1 * (1 + scaleFactor), GameConfig.Factor1 * (1 + scaleFactor));
        }

        MoveBy(lastPostion - transform.position, snake, gameData);
    }

    public override void BesselTo(int add)
    {
        Vector3 target = Camera.main.ScreenToWorldPoint(new Vector3(Screen.width / 2, Screen.height, Camera.main.nearClipPlane));
        Vector3[] paths = { transform.position, target};
        iTween.MoveTo(gameObject, iTween.Hash("path", paths, "time", 0.5f, "oncomplete", "oncomplete"));
    }

    public override void RemoveFromSnake(Snake snake, int addScore)
    {
        StartCoroutine(ChangeColorAndRemove(snake, addScore));
    }

    IEnumerator ChangeColorAndRemove(Snake snake, int addScore)
    {
        int count = 5;
        while (count-- > 0)
        {
            GetComponent<Renderer>().material.color = colors[count];
            yield return new WaitForSeconds(0.1f);
        }

        snake.snakeNodes.Remove(this);
        gameController.AddScore(addScore);

        GetComponent<Renderer>().material.color = Color.white;
        level.Restore(this);

        level.AddAtom(transform.position, GameConfig.NODE_COLOR_DIC[type]);
    }

    private void oncomplete()
    {
//        GameObject.Destroy(gameObject);
    }

    public override void ChangeToColor(Color color)
    {
//        if (jellyMesh != null)
//        {
//            jellyMesh.GetComponent<Renderer>().material.color = color;
//        }
//        else
//        {
////            renderer.material.color = color;
//        }

    }
}
