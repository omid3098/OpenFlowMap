using UnityEngine;
public class Logger
{
    public static bool Active { get; set; } = true;
    public static void DrawLine(Vector3 start, Vector3 end, Color color)
    {
        if (Active)
            Debug.DrawLine(start, end, color);
    }

    public static void DrawRay(Vector3 start, Vector3 direction, Color color)
    {
        if (Active)
            Debug.DrawRay(start, direction, color);
    }

    public static void Log(string message)
    {
        if (Active)
            Debug.Log(message);
    }
}