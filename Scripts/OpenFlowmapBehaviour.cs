using UnityEngine;

public class OpenFlowmapBehaviour : MonoBehaviour
{
    [SerializeField] LayerMask m_LayerMask;
    [SerializeField] int m_rayCount = 100;
    [SerializeField, Range(0f, 1f)] float m_rayLength = 0.5f;
    [SerializeField] RayProcessor[] m_processors;
    [SerializeField] bool m_processEveryFrame = false;
    [SerializeField] public RenderTexture m_renderTexture;

    [Header("Debug")]
    [SerializeField] bool m_drawGizmos = true;
    [SerializeField] bool m_drawGizmosOnSelected = true;

    public LayerMask LayerMask => m_LayerMask;

    private RayProjector m_rayProjector;
    private Color[] m_colors;
    private Texture2D m_tempTexture;

    private void OnValidate()
    {
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
        var m_meshFilter = GetComponent<MeshFilter>();
        Process(m_meshFilter.sharedMesh.bounds.size, new Plane(transform.up, transform.position), transform.position);
    }

    private void Process(Vector3 size, Plane plane, Vector3 planeOrigin)
    {
        if (m_renderTexture == null)
        {
            return;
        }
        if (m_rayProjector == null)
        {
            m_rayProjector = new RayProjector(
                size,
                plane,
                planeOrigin,
                m_rayCount,
                m_rayLength);
        }
        else
        {
            if (m_rayProjector.RayCount != m_rayCount)
            {
                m_rayProjector.ResizeRays(m_rayCount);
            }
            m_rayProjector.InitializeRaysAlongPlane(size, plane, planeOrigin, m_rayLength);
        }
        for (int i = 0; i < m_processors.Length; i++)
        {
            RayProcessor processor = m_processors[i];
            if (processor != null)
            {
                processor.Register(this);
                processor.Initialize();
                processor.Execute(m_rayProjector);
            }
        }
        BakeTexture();
    }

    private void BakeTexture()
    {
        if (m_rayProjector == null)
        {
            return;
        }
        var textureSize = m_renderTexture.width;
        if (m_tempTexture == null)
        {
            m_tempTexture = new Texture2D(textureSize, textureSize, TextureFormat.RGBAFloat, false, false);
        }
        else if (m_tempTexture.width != textureSize || m_tempTexture.height != textureSize)
        {
            m_tempTexture.Reinitialize(textureSize, textureSize);
        }
        if (m_colors == null || m_colors.Length != textureSize * textureSize)
        {
            m_colors = new Color[textureSize * textureSize];
        }
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
                var color = Utils.ConvertDirectionToColor(ray.direction);
                // texture pixels are mirrored diagonally along y = -x line
                var correctX = textureSize - 1 - u;
                var correctY = textureSize - 1 - v;
                m_colors[correctX * textureSize + correctY] = color;
            }
        }
        m_tempTexture.SetPixels(m_colors);
        m_tempTexture.Apply();

        if (m_renderTexture == null)
        {
            m_renderTexture = new RenderTexture(textureSize, textureSize, 24);
        }
        var oldActive = RenderTexture.active;
        Graphics.Blit(m_tempTexture, m_renderTexture);
        RenderTexture.active = oldActive;

        ApplyTexture();
    }

    private void ApplyTexture()
    {
        var meshRenderer = GetComponent<MeshRenderer>();
        if (meshRenderer != null && meshRenderer.sharedMaterial.GetTexture("_FlowMap") != m_renderTexture)
        {
            meshRenderer.sharedMaterial.SetTexture("_FlowMap", m_renderTexture);
        }
    }

    public void SaveTexture(string path)
    {
        if (m_tempTexture == null)
        {
            Debug.LogError("Flowmap is not available.");
            return;
        }
        byte[] bytes = m_tempTexture.EncodeToPNG();
        System.IO.File.WriteAllBytes(path, bytes);
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

    private void OnDestroy()
    {
        m_processEveryFrame = false;
        m_rayProjector = null;
        m_colors = null;
        if (m_tempTexture != null)
        {
            DestroyImmediate(m_tempTexture);
            m_tempTexture = null;
        }
    }
}
