using UnityEngine;

public class OpenFlowmapBehaviour : MonoBehaviour
{
    [SerializeField] LayerMask m_LayerMask;
    [SerializeField] int m_rayCount = 100;
    [SerializeField, Range(0f, 1f)] float m_rayLength = 0.5f;
    [SerializeField] RayProcessor[] m_processors;
    [SerializeField] bool m_processEveryFrame = false;
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    [SerializeField] Resolution m_textureResolution = Resolution._128x128;
    [SerializeField] public Texture2D m_texture;

    [Header("Debug")]
    [SerializeField] bool m_drawGizmos = true;
    [SerializeField] bool m_drawGizmosOnSelected = true;

    public LayerMask LayerMask => m_LayerMask;

    private RayProjector m_rayProjector;

    private void OnValidate()
    {
        ApplyTexture();
        Process();
#if UNITY_EDITOR
        if (m_updateCoroutine != null)
        {
            Unity.EditorCoroutines.Editor.EditorCoroutineUtility.StopCoroutine(m_updateCoroutine);
            m_updateCoroutine = null;
        }
        if (m_processEveryFrame && !UnityEditor.EditorApplication.isPlaying)
        {
            m_updateCoroutine = Unity.EditorCoroutines.Editor.EditorCoroutineUtility.StartCoroutineOwnerless(UpdateCoroutine());
        }
#endif
    }

#if UNITY_EDITOR
    private Unity.EditorCoroutines.Editor.EditorCoroutine m_updateCoroutine;

    private System.Collections.IEnumerator UpdateCoroutine()
    {
        while (true && !UnityEditor.EditorApplication.isPlaying)
        {
            Update();
            UnityEditor.SceneView.RepaintAll();
            yield return null;
        }
    }
#endif

    private void Update()
    {
        if (m_processEveryFrame || transform.hasChanged)
        {
            transform.hasChanged = false;
            Process();
        }
    }

    internal void RayProcessorOnValidate(RayProcessor processor)
    {
        if (System.Array.IndexOf(m_processors, processor) != -1)
        {
            Process();
        }
    }

    public void Process()
    {
        m_rayProjector = null;
        var m_meshFilter = GetComponent<MeshFilter>();
        Process(m_meshFilter.sharedMesh.bounds.size, new Plane(transform.up, transform.position), transform.position);
    }

    private void Process(Vector3 size, Plane plane, Vector3 planeOrigin)
    {
        if (m_texture == null)
        {
            return;
        }
        m_rayProjector = new RayProjector(
            size,
            plane,
            planeOrigin,
            m_rayCount,
            m_rayLength);
        for (int i = 0; i < m_processors.Length; i++)
        {
            RayProcessor effector = m_processors[i];
            if (effector != null)
            {
                effector.Register(this);
                effector.Initialize();
                effector.Execute(m_rayProjector);
            }
        }
    }

    [ContextMenu("Bake Texture")]
    public void BakeTexture()
    {
        if (m_rayProjector == null)
        {
            return;
        }
        var textureSize = (int)m_textureResolution;
        Texture2D texture = new Texture2D(textureSize, textureSize, TextureFormat.RGBAFloat, false, false);
        var colors = new Color[textureSize * textureSize];
        var projectorResolution = m_rayProjector.RayCount;
        // remap projector resolution to texture resolution
        var remap = (float)projectorResolution / textureSize;
        for (int u = 0; u < textureSize; u++)
        {
            for (int v = 0; v < textureSize; v++)
            {
                int indexX = (int)(u * remap);
                int indexY = (int)(v * remap);
                var ray = m_rayProjector.GetRay(indexX, indexY);
                var color = Utils.ConvertDirectionToColor(new Vector2(ray.direction.x, ray.direction.z));
                // texture pixels are mirrored diagonally along y = -x line
                var correctX = textureSize - 1 - u;
                var correctY = textureSize - 1 - v;
                colors[correctX * textureSize + correctY] = color;
            }
        }
        texture.SetPixels(colors);
        texture.Apply();
        byte[] bytes = texture.EncodeToPNG();
        DestroyImmediate(texture);
        SaveTexture(bytes);
        Debug.Log("BakeTexture" + m_textureResolution);
    }

    private void SaveTexture(byte[] bytes)
    {
        // save the texture as a png file at the same location of the current scene
        var path = UnityEditor.AssetDatabase.GetAssetPath(m_texture);
        System.IO.File.WriteAllBytes(path, bytes);
        // Refresh the AssetDatabase after saving the file
        UnityEditor.AssetDatabase.Refresh();

        var textureImporter = UnityEditor.AssetImporter.GetAtPath(path) as UnityEditor.TextureImporter;
        textureImporter.textureType = UnityEditor.TextureImporterType.NormalMap;
        textureImporter.textureCompression = UnityEditor.TextureImporterCompression.Uncompressed;
        textureImporter.crunchedCompression = false;
        textureImporter.SaveAndReimport();
    }

    private void ApplyTexture()
    {
        var meshRenderer = GetComponent<MeshRenderer>();
        if (meshRenderer != null && meshRenderer.sharedMaterial.GetTexture("_FlowMap") != m_texture)
        {
            meshRenderer.sharedMaterial.SetTexture("_FlowMap", m_texture);
        }
    }

    private void OnDrawGizmos()
    {
        if (m_drawGizmos && !m_drawGizmosOnSelected)
        {
            Draw();
        }
    }

    private void OnDrawGizmosSelected()
    {
        if (m_drawGizmos && m_drawGizmosOnSelected)
        {
            Draw();
        }
    }

    private void Draw()
    {
        if (m_rayProjector == null)
        {
            return;
        }
        m_rayProjector.Draw();
        foreach (var processor in m_processors)
        {
            processor.Draw();
        }
    }
}
