using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class OpenFlowmap : MonoBehaviour
{
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution resolutionEnum = Resolution._128x128;
    [Range(0.1f, 1)] public float radius = 0.2f;
    public LayerMask layerMask;

    [SerializeField] bool m_showFlowMaterial = true;

    private MeshRenderer m_meshRenderer;
    private MeshFilter m_meshFilter;
    private Material m_unlitFlowMaterial;
    private Material m_previusMaterial;
    private Collider[] m_hitColliders = new Collider[3];

    public Flowmap Flowmap;

    private void Awake() => InitializeFlowmapPoints();
    private void OnValidate() => InitializeFlowmapPoints();

    public void InitializeFlowmapPoints()
    {
        Flowmap = new Flowmap((int)resolutionEnum);

        m_meshRenderer = GetComponent<MeshRenderer>();

        if (m_showFlowMaterial)
        {
            // store the previous material to restore it later if it already exists
            if (m_previusMaterial != null) m_previusMaterial = m_meshRenderer.sharedMaterial;
            else if (m_meshRenderer.sharedMaterial != null) m_previusMaterial = m_meshRenderer.sharedMaterial;

            // find Shader: OpenFlowmap/UnlitFlowmap and create a new material
            m_unlitFlowMaterial = new Material(Shader.Find("OpenFlowmap/UnlitFlowmap"));
            m_meshRenderer.sharedMaterial = m_unlitFlowMaterial;
        }

        m_meshFilter = GetComponent<MeshFilter>();
    }

    private void Update()
    {
        GetFlowPoints();
        if (m_showFlowMaterial) VisualizeFlowmap();
    }

    public void GetFlowPoints()
    {
        for (int y = 0; y < Flowmap.Resolution; y++)
        {
            for (int x = 0; x < Flowmap.Resolution; x++)
            {
                var pointPosition = GetPointPosition(x, y);
                int hitCount = Physics.OverlapSphereNonAlloc(pointPosition, radius, m_hitColliders, layerMask);
                Color color;
                if (hitCount > 0)
                {
                    Collider[] hits = new Collider[hitCount];
                    System.Array.Copy(m_hitColliders, hits, hitCount);
                    color = GetFlowDirectionColor(hits, pointPosition);
                }
                else
                {
                    color = new Color(0.5f, 0.5f, 0, 1);
                }
                Flowmap.SetColor(x, y, color);

            }
        }
    }

    private void VisualizeFlowmap()
    {
        // Check if the MeshRenderer and material exist
        if (m_meshRenderer != null && m_meshRenderer.sharedMaterial != null)
        {
            // Assign the flowmap texture to the material's main texture
            m_meshRenderer.sharedMaterial.SetTexture("_FlowMap", Flowmap.GetTexture());
        }
        else
        {
            Debug.LogError("MeshRenderer or material not found!");
        }
    }

    public Color GetFlowDirectionColor(Collider[] hitColliders, Vector3 pointPosition)
    {
        Vector2 sumDirection = Vector2.zero;
        for (int i = 0; i < hitColliders.Length; i++)
        {
            Vector3 closestPoint = hitColliders[i].ClosestPoint(pointPosition);
            float distanceToCollider = Vector3.Distance(pointPosition, closestPoint);
            float strength = 1f - Mathf.Clamp01(distanceToCollider / radius);

            Vector2 direction = new Vector2(pointPosition.x - closestPoint.x, pointPosition.z - closestPoint.z);
            direction.Normalize();
            direction *= strength;
            sumDirection += direction;
        }
        if (hitColliders.Length > 0)
        {
            Vector2 averageDirection = sumDirection / hitColliders.Length;
            averageDirection += Vector2.one / 2f;
            return new Color(averageDirection.x, averageDirection.y, 0, 1);
        }
        return new Color(0.5f, 0.5f, 0, 1); // Default color if no colliders are hit
    }

    // TODO: Move this calculations in compute shader
    public Vector3 GetPointPosition(float x, float y)
    {
        // calculate the point's position and rotation to keep it aligned with the plane
        var bounds = m_meshFilter.sharedMesh.bounds.size;
        float pointX = x * bounds.x / Flowmap.Resolution - bounds.x / 2f;
        float pointY = 0;
        float pointZ = y * bounds.z / Flowmap.Resolution - bounds.z / 2f;
        Vector3 point = transform.TransformPoint(pointX, pointY, pointZ);
        return point;
    }


#if UNITY_EDITOR
    public void BakeFlowmapTexture()
    {
        Texture2D texture = (Texture2D)Flowmap.GetTexture();
        byte[] bytes = texture.EncodeToPNG();
        string fileName = gameObject.name + "_Flowmap.png";
        // get the path to the current scene
        string filePath = System.IO.Path.GetDirectoryName(UnityEngine.SceneManagement.SceneManager.GetActiveScene().path) + "/" + fileName;
        System.IO.File.WriteAllBytes(filePath, bytes);

        UnityEditor.AssetDatabase.Refresh();
        UnityEditor.TextureImporter textureImporter = UnityEditor.AssetImporter.GetAtPath(filePath) as UnityEditor.TextureImporter;
        textureImporter.sRGBTexture = false;
        textureImporter.alphaSource = UnityEditor.TextureImporterAlphaSource.None;
        textureImporter.wrapMode = TextureWrapMode.Clamp;
        textureImporter.filterMode = FilterMode.Bilinear;
        // disable compression
        textureImporter.textureCompression = UnityEditor.TextureImporterCompression.Uncompressed;
        textureImporter.SaveAndReimport();

        Debug.Log("Flowmap texture baked and saved at " + filePath);
        // Select the texture asset
        UnityEditor.Selection.activeObject = UnityEditor.AssetDatabase.LoadAssetAtPath(filePath, typeof(Texture2D));
    }
#endif
    private void Dispose()
    {
        // dispose the flowmap
        if (Flowmap != null)
        {
            Flowmap.Dispose();
            Flowmap = null;
        }
        // destroy the material
        if (m_unlitFlowMaterial != null)
        {
            DestroyImmediate(m_unlitFlowMaterial);
            m_unlitFlowMaterial = null;
        }
    }

    private void OnDestroy()
    {
        Dispose();
    }
}