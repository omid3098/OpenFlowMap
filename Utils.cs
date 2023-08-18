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

    public static Vector2 WorldPositionToUVCoodinate(Vector3 worldPosition, MeshRenderer meshRenderer)
    {
        var ray = new Ray(worldPosition + Vector3.up * 0.5f, Vector3.down);
        if (Physics.Raycast(ray, out RaycastHit hit, meshRenderer.gameObject.layer))
        {
            if (hit.collider.gameObject == meshRenderer.gameObject)
            {
                var uv = hit.textureCoord;
                return new Vector2(uv.x, uv.y);
            }
        }
        return -Vector2.one;
    }
}