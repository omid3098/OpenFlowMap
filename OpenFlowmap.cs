using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class OpenFlowmap : MonoBehaviour
{
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution resolutionEnum = Resolution._128x128;
    public float radius = 0.2f;
    public LayerMask layerMask;

    public List<Vector2> FlowmapPoints { get; private set; }
    public List<Color> FlowmapColors { get; private set; }

    [SerializeField] bool m_showTexture = false;

    private MeshRenderer m_meshRenderer;
    private MeshFilter m_meshFilter;
    private Material m_unlitFlowMaterial;
    private Collider[] m_hitColliders = new Collider[3];
    private Vector2Int m_resolution;

    private void Awake() => InitializeFlowmapPoints();
    private void OnValidate() => InitializeFlowmapPoints();

    public void InitializeFlowmapPoints()
    {
        // Debug.Log("Initializing flowmap points");
        m_resolution = new Vector2Int((int)resolutionEnum, (int)resolutionEnum);
        FlowmapPoints = new List<Vector2>();
        FlowmapColors = new List<Color>(new Color[m_resolution.x * m_resolution.y]);

        // find Shader: OpenFlowmap/UnlitFlowmap and create a new material
        m_unlitFlowMaterial = new Material(Shader.Find("OpenFlowmap/UnlitFlowmap"));

        // Get the MeshRenderer component
        m_meshRenderer = GetComponent<MeshRenderer>();
        m_meshRenderer.sharedMaterial = m_unlitFlowMaterial;

        m_meshFilter = GetComponent<MeshFilter>();


        for (int x = 0; x < m_resolution.x; x++)
        {
            for (int y = 0; y < m_resolution.y; y++)
            {
                FlowmapPoints.Add(new Vector2(x, y));
            }
        }
    }

    private void Update()
    {
        GetFlowPoints();
        if (m_showTexture) VisualizeFlowmap();
    }

    public void GetFlowPoints()
    {
        int index = 0;
        foreach (var point in FlowmapPoints)
        {
            var pointPosition = GetPointPosition(point.x, point.y);
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
            FlowmapColors[index++] = color;
        }
    }

    private void VisualizeFlowmap()
    {
        UpdateMaterialTexture();
    }


    // Update the plane's material texture with the flowmap texture
    private void UpdateMaterialTexture()
    {
        // Check if the MeshRenderer and material exist
        if (m_meshRenderer != null && m_meshRenderer.sharedMaterial != null)
        {
            // Get the flowmap texture
            Texture flowmapTexture = GetFlowmapTexture();

            // Assign the flowmap texture to the material's main texture
            m_meshRenderer.sharedMaterial.SetTexture("_MainTex", flowmapTexture);
        }
        else
        {
            Debug.LogError("MeshRenderer or material not found!");
        }
    }

    public Texture GetFlowmapTexture()
    {
        Texture2D texture = new Texture2D(m_resolution.x, m_resolution.y);
        // Iterate over the flowmap colors and set the pixels, flipping the Y-axis
        for (int x = 0; x < m_resolution.x; x++)
        {
            for (int y = 0; y < m_resolution.y; y++)
            {
                int index = x * m_resolution.y + y;
                int flippedY = m_resolution.y - y - 1; // Flip the Y-axis
                int flippedX = m_resolution.x - x - 1; // Flip the X-axis
                texture.SetPixel(flippedX, flippedY, FlowmapColors[index]);
            }
        }
        texture.Apply();
        return texture;
    }

    public Color GetFlowDirectionColor(Collider[] hitColliders, Vector3 pointPosition)
    {
        for (int i = 0; i < hitColliders.Length; i++)
        {
            Vector3 closestPoint = hitColliders[i].ClosestPoint(pointPosition);
            float distanceToCollider = Vector3.Distance(pointPosition, closestPoint);
            float strength = 1f - Mathf.Clamp01(distanceToCollider / radius);

            Vector2 direction = new Vector2(pointPosition.x - closestPoint.x, pointPosition.z - closestPoint.z);
            direction.Normalize();
            direction *= strength;
            direction += Vector2.one / 2f;
            return new Color(direction.x, direction.y, 0, 1);
        }
        return Color.black;
    }

    public Vector3 GetPointPosition(float x, float y)
    {
        // calculate the point's position and rotation to keep it aligned with the plane
        var bounds = m_meshFilter.sharedMesh.bounds.size;
        float pointX = x * bounds.x / m_resolution.x - bounds.x / 2f;
        float pointY = 0;
        float pointZ = y * bounds.z / m_resolution.y - bounds.z / 2f;
        Vector3 point = transform.TransformPoint(pointX, pointY, pointZ);
        return point;
    }


#if UNITY_EDITOR
    public void BakeFlowmapTexture()
    {
        Texture2D texture = (Texture2D)GetFlowmapTexture();
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

    private void OnDisable()
    {
        FlowmapColors = new List<Color>(new Color[m_resolution.x * m_resolution.y]);
        FlowmapPoints = new List<Vector2>();
    }
}