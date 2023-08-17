using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SimulatedFlowmap : MonoBehaviour
{
    public class Flowmap
    {
        private MeshRenderer m_meshRenderer;
        private MeshFilter m_meshFilter;

        public Texture2D Texture { get; private set; }

        public Flowmap(int resolution, MeshRenderer m_meshRenderer, MeshFilter m_meshFilter)
        {
            this.m_meshRenderer = m_meshRenderer;
            this.m_meshFilter = m_meshFilter;
            Texture = new Texture2D(resolution, resolution, TextureFormat.RGBAFloat, false, false);
            for (int x = 0; x < Texture.width; x++)
            {
                for (int y = 0; y < Texture.height; y++)
                {
                    Texture.SetPixel(x, y, new Color(0.5f, 0.5f, 0.5f, 1f));
                }
            }
        }

        public void WriteHits(List<(RaycastHit hit, Vector3 reflect)> hitFlowList)
        {
            foreach (var hitData in hitFlowList)
            {
                // Debug.DrawRay(hitData.hit.point, hitData.reflect, Color.red);
                // raycast from hit point + up toward down to get the the UV coordinate of the hit point
                var ray = new Ray(hitData.hit.point + Vector3.up, Vector3.down);
                // cast the ray
                if (Physics.Raycast(ray, out RaycastHit hit, 2f, m_meshRenderer.gameObject.layer))
                {
                    // get the UV coordinate of the hit point
                    var uv = hit.textureCoord;
                    var x = (int)(uv.x * Texture.width);
                    var y = (int)(uv.y * Texture.height);
                    // calculate the color of the pixel based on the reflect vector in range of 0-1
                    var pixelColor = new Color(hitData.reflect.x / 2f + 0.5f, hitData.reflect.y / 2f + 0.5f, hitData.reflect.z / 2f + 0.5f, 1f);
                    // set the pixel color
                    Texture.SetPixel(x, y, pixelColor);
                }
            }
            Texture.Apply();
            ApplyToMesh(m_meshRenderer, "_FlowMap");
        }

        public void ApplyToMesh(Renderer renderer, string textureName)
        {
            renderer.sharedMaterial.SetTexture(textureName, Texture);
        }

        public void Dispose()
        {
            Object.DestroyImmediate(Texture);
        }
    }

    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution resolutionEnum = Resolution._128x128;
    public LayerMask layerMask;
    [SerializeField] Transform m_flowDirectionTransform;
    [SerializeField, Range(0f, 45f)] float m_chaosAngle = 15f;
    [SerializeField] bool m_drawGizmos = true;
    private Bounds m_bounds;
    private RayLine m_rayLine;
    private Flowmap m_flowmap;
    private MeshRenderer m_meshRenderer;
    private MeshFilter m_meshFilter;

    private void Awake()
    {
        m_bounds = GetComponent<MeshFilter>().sharedMesh.bounds;
        Initialize();
    }

    private void OnValidate() => Initialize();

    public void Initialize()
    {
        Logger.DrawGizmos = m_drawGizmos;
        m_meshRenderer = GetComponent<MeshRenderer>();
        m_meshFilter = GetComponent<MeshFilter>();
        m_flowmap = new Flowmap((int)resolutionEnum, m_meshRenderer, m_meshFilter);

        // define an imaginary finite line from border of a sphere around the the bounds of the mesh in the direction of the flow
        Vector3 sphereCenter = transform.position;
        float sphereRadius = m_bounds.extents.magnitude;
        var normalizedFlowDirection = new Vector2(m_flowDirectionTransform.forward.x, m_flowDirectionTransform.forward.z).normalized;
        Vector2 oppositeDirection = -normalizedFlowDirection;
        Vector2 offset = oppositeDirection * sphereRadius;
        Vector2 pointOnSphere = new Vector2(sphereCenter.x, sphereCenter.z) + offset;
        Vector2 toPointDirection = (pointOnSphere - new Vector2(sphereCenter.x, sphereCenter.z)).normalized;
        Vector2 tangentDirection = new Vector2(-toPointDirection.y, toPointDirection.x);
        Vector2 startPoint = pointOnSphere + tangentDirection * sphereRadius;
        Vector2 endPoint = pointOnSphere - tangentDirection * sphereRadius;
        m_rayLine = new RayLine(sphereCenter, startPoint, endPoint, (int)resolutionEnum, normalizedFlowDirection, sphereRadius, m_chaosAngle, layerMask);
        // we will cast rays from the start point to the end point and check if they hit any collider
    }

    private void Update()
    {
        Initialize();
        m_rayLine.CastRays();
        m_flowmap.WriteHits(m_rayLine.HitDataList);
    }

    private void OnDestroy()
    {
        m_flowmap.Dispose();
        m_rayLine.Dispose();
    }
}
