using UnityEngine;

public class BakeTexture : Effector
{
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution m_textureResolution = Resolution._128x128;
    [SerializeField] private Texture2D m_texture;
    internal override void Execute()
    {
        // Debug.Log("BakeTexture" + m_textureResolution);
        var rays = openFlowmap.RayProjector.GetRays();
        var textureSize = (int)m_textureResolution;
        var texture = new Texture2D(textureSize, textureSize, TextureFormat.RGBAFloat, false, false);
        var colors = new Color[textureSize * textureSize];
        var projectorResolution = openFlowmap.RayResolution;
        // remap projector resolution to texture resolution
        var remap = (float)projectorResolution / textureSize;
        for (int u = 0; u < textureSize; u++)
        {
            for (int v = 0; v < textureSize; v++)
            {
                var ray = rays[(int)(u * remap) * projectorResolution + (int)(v * remap)];
                var color = Utils.ConvertDirectionToColor(new Vector2(ray.direction.x, ray.direction.z));
                colors[u * textureSize + v] = color;
            }
        }
        texture.SetPixels(colors);
        texture.Apply();
        m_texture = texture;
    }
}
