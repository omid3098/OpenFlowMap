using System;
using UnityEngine;

[CreateAssetMenu(fileName = "FlowmapRenderer", menuName = "OpenFlowmap/Processor/FlowmapRenderer")]
public class FlowmapRenderer : RayProcessor
{
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution m_textureResolution = Resolution._128x128;
    [SerializeField] public Texture2D m_texture;
    internal override void Execute()
    {
        // Debug.Log("BakeTexture" + m_textureResolution);
        var rays = openFlowmapConfig.RayProjector.GetRays();
        var textureSize = (int)m_textureResolution;
        Texture2D texture = new Texture2D(textureSize, textureSize, TextureFormat.RGBAFloat, false, false);
        var colors = new Color[textureSize * textureSize];
        var projectorResolution = openFlowmapConfig.RayResolution;
        // remap projector resolution to texture resolution
        var remap = (float)projectorResolution / textureSize;
        for (int u = 0; u < textureSize; u++)
        {
            for (int v = 0; v < textureSize; v++)
            {
                var ray = rays[(int)(u * remap) * projectorResolution + (int)(v * remap)];
                var color = Utils.ConvertDirectionToColor(new Vector2(ray.direction.x, ray.direction.z));
                // texture pixels are mirrored diagonally along y = -x line
                var correctX = textureSize - 1 - v;
                var correctY = textureSize - 1 - u;
                colors[correctX * textureSize + correctY] = color;
            }
        }

        texture.SetPixels(colors);
        texture.Apply();
        SaveTexture(texture);
        ApplyTexture();
    }

    private void SaveTexture(Texture2D texture)
    {
        // save the texture as a png file at the same location of the current scene
        var scenePath = UnityEngine.SceneManagement.SceneManager.GetActiveScene().path;
        var fileName = System.IO.Path.GetFileNameWithoutExtension(scenePath);
        var path = System.IO.Path.GetDirectoryName(scenePath) + "/" + fileName + "_" + m_textureResolution + ".png";
        var bytes = texture.EncodeToPNG();
        System.IO.File.WriteAllBytes(path, bytes);
        // Refresh the AssetDatabase after saving the file
        UnityEditor.AssetDatabase.Refresh();

        var textureImporter = UnityEditor.AssetImporter.GetAtPath(path) as UnityEditor.TextureImporter;
        textureImporter.textureType = UnityEditor.TextureImporterType.NormalMap;
        textureImporter.textureCompression = UnityEditor.TextureImporterCompression.Uncompressed;
        textureImporter.crunchedCompression = false;
        textureImporter.SaveAndReimport();

        m_texture = UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>(path);
    }

    private void ApplyTexture()
    {
        var openFlowmapBehaviour = FindObjectOfType<OpenFlowmapBehaviour>();
        if (openFlowmapBehaviour != null)
        {
            var meshRenderer = openFlowmapBehaviour.GetComponent<MeshRenderer>();
            if (meshRenderer != null)
            {
                meshRenderer.sharedMaterial.SetTexture("_FlowMap", m_texture);
            }
        }
    }
}
