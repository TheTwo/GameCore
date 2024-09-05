public class BadNode : BasicNode
{   
    public override void MeetSnake(Snake snake)
    {
        snake.MeetBadNode(this);
    }

}
