using System;
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
    private Collider[] m_hitColliders = new Collider[5];

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
            Vector3 closestPoint = Vector3.zero;
            Vector2 direction = Vector2.zero;
            if (hitColliders[i] is not TerrainCollider)
            {
                closestPoint = hitColliders[i].ClosestPoint(pointPosition);

                float distanceToCollider = Vector3.Distance(pointPosition, closestPoint);
                float strength = 1f - Mathf.Clamp01(distanceToCollider / radius);
                direction = new Vector2(pointPosition.x - closestPoint.x, pointPosition.z - closestPoint.z);
                direction.Normalize();
                direction *= strength;
                // Debug.Log("OtherColliders: " + Vector3.Distance(pointPosition, closestPoint));
            }
            else
            {
                // for this position, we need to find the terrain height at that point and create the terrain position
                // Debug.DrawLine(logStartPos, logEndPos, logColor);
                var terrain = hitColliders[i].GetComponent<Terrain>();
                var terrainHeightAtPoint = terrain.SampleHeight(pointPosition) + terrain.transform.position.y;

                Vector3 terrainPositionAtPoint = new Vector3(pointPosition.x, terrainHeightAtPoint, pointPosition.z);

                var flowStrenght = terrainPositionAtPoint - pointPosition;
                if (flowStrenght.y > 0) flowStrenght.y = 0;

                // calculate the direction of the flow based on the terrain normal
                var terrainNormal = terrain.terrainData.GetInterpolatedNormal((pointPosition.x - terrain.transform.position.x) / terrain.terrainData.size.x, (pointPosition.z - terrain.transform.position.z) / terrain.terrainData.size.z);
                // now we need to project the terrain normal on the xz plane
                terrainNormal.y = 0;
                terrainNormal.Normalize();
                // now we need to calculate the strength of the flow based on the terrain normal

                // Using the terrainNormal and flowStrenght (distance to seashore) to calculate direction and strength
                var directionFromNormal = new Vector2(terrainNormal.x, terrainNormal.z);
                float distanceFactor = 1f - Mathf.Clamp01(flowStrenght.magnitude / radius); // Normalize the distance to seashore within [0, 1]

                // Calculate the strength based on the distance to the seashore
                float strength = Mathf.Lerp(0f, 1f, distanceFactor);

                // Combine the direction and strength
                direction = directionFromNormal * strength;
            }
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

    public static Color ConvertDirectionToColor(Vector2 direction)
    {
        direction += Vector2.one / 2f;
        return new Color(direction.x, direction.y, 0, 1);
    }

    public static Vector2 ConvertColorToDirection(Color color)
    {
        return new Vector2(color.r - 0.5f, color.g - 0.5f);
    }

    // TODO: Move this calculations in compute shader
    /// <summary>
    /// Returns the position of a point in world space
    /// </summary>
    /// <param name="x">The x coordinate of the point in the flowmap</param>
    /// <param name="y">The y coordinate of the point in the flowmap</param>
    /// <returns> The position of the flowmap point in world space</returns>
    /// <remarks>
    /// The flowmap is a 2D texture that is mapped to the mesh. The flowmap's resolution is the same as the mesh's resolution.
    /// The flowmap's origin is at the bottom left corner of the mesh. The flowmap's x axis is mapped to the mesh's x axis and the flowmap's y axis is mapped to the mesh's z axis.
    /// </remarks>
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

    public Vector3 GetBounds()
    {
        return m_meshFilter.sharedMesh.bounds.size;
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
        // set texture type to normal map
        textureImporter.textureType = UnityEditor.TextureImporterType.NormalMap;

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