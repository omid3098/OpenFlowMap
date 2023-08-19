using UnityEngine;
public static class Utils
{
    public static Color ConvertDirectionToColor(Vector2 direction)
    {
        direction += Vector2.one / 2f;
        return new Color(direction.x, direction.y, 0, 1);
    }

    public static Vector2 ConvertColorToDirection(Color color)
    {
        return new Vector2(color.r - 0.5f, color.g - 0.5f);
    }
}