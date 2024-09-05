using UnityEngine;

public class Line
{
    private float a;
    private float b;

    public Line(float a, float b)
    {
        this.a = a;
        this.b = b;
    }

    public float Y(float x)
    {
        return a * x + b;
    }

    public float X(float y)
    {
        return (y - b) / a;
    }

    public static Vector2 Cross(Line a, Line b)
    {
        float x = (b.b - a.b)/(a.a - b.a);
        return new Vector2(x, a.Y(x));
    }
}
