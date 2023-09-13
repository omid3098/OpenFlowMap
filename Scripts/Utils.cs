using UnityEngine;
public static class Utils
{
    public static Color ConvertDirectionToColor(Vector2 direction)
    {
        return new Color(direction.x + 0.5f, direction.y + 0.5f, 0, 1);
    }

    public static Color ConvertDirectionToColor(Vector3 direction)
    {
        return new Color(direction.x + 0.5f, direction.z + 0.5f, 0, 1);
    }

    public static Vector2 ConvertColorToDirection(Color color)
    {
        return new Vector2(color.r - 0.5f, color.g - 0.5f);
    }
}