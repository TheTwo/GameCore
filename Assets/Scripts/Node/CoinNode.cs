using UnityEngine;

public class CoinNode : BasicNode
{
    private Snake snake;
    private bool following = false;

    void OnTriggerEnter(Collider collider)
    {
        if(collider.GetComponent<HeadNode>() != null)
        {
            FindObjectOfType<Snake>().MeetCoinNode(this);
        }
    }

    void Start()
    {
        snake = FindObjectOfType<Snake>();
    }

    void Update()
    {
        if(!following && snake != null && snake.headNode != null && Vector3.Distance(transform.position, snake.headNode.transform.position) < 10)
        {
            following = true;
        }
        else
        {
            following = false;
        }

        if(following)
        {
            transform.position = Vector3.Slerp(transform.position, snake.headNode.transform.position, Time.deltaTime * GameConfig.CoinSpeed);
        }

    }
}
