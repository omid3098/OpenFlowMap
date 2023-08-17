using UnityEngine;
public class Logger
{
    public static bool DrawGizmos { get; set; } = true;
    public static void DrawLine(Vector3 start, Vector3 end, Color color)
    {
        if (DrawGizmos)
            Debug.DrawLine(start, end, color);
    }

    public static void DrawRay(Vector3 start, Vector3 direction, Color color)
    {
        if (DrawGizmos)
            Debug.DrawRay(start, direction, color);
    }
}