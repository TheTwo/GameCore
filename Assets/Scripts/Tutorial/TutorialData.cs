using System.Collections.Generic;

public class TutorialData
{
    public delegate void TutorialDataChange(TutorialData tutorialData);
    public event TutorialDataChange OnTutorialDataChange;

    private List<Node> snakeNodes = new List<Node>();

    private int moveCount;

    private bool bang;

    private float levelProgress;

    public float LevelProgress
    {
        get
        {
            return levelProgress;
        }
        set
        {
            levelProgress = value;
        }
    }

    private int score;

    public int Score
    {
        get
        {
            return score;
        }
        set
        {
            score = value;
        }
    }

    public bool Bang
    {
        get
        {
            return bang;
        }
        set
        {
            bang = value;
        }
    }

    public int MoveCount
    {
        get
        {
            return moveCount;
        }
        set
        {
            moveCount = value;

            if (OnTutorialDataChange != null)
            {
                OnTutorialDataChange(this);
            }
        }
    }

    public List<Node> SnakeNodes
    {
        get
        {
            return snakeNodes;
        }
    }

    public void SetNodes(List<Node> snakeNodes)
    {
        this.snakeNodes = snakeNodes;

        if (OnTutorialDataChange != null)
        {
            OnTutorialDataChange(this);
        }
    }

    public void ChangeDirection()
    {
        if (OnTutorialDataChange != null)
        {
            OnTutorialDataChange(this);
        }
    }
}
