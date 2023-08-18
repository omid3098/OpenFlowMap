using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SimulatedFlowmap : MonoBehaviour
{
    public class Flowmap
    {
        private MeshRenderer m_meshRenderer;
        private MeshFilter m_meshFilter;
        private Bounds m_bounds;
        private Vector2 m_normalizedFlowDirection;
        private int m_resolution;
        private float m_radius;

        public Texture2D Texture { get; private set; }

        public Flowmap(int resolution, GameObject gameObject, Vector2 normalizedFlowDirection, float radius)
        {
            m_meshRenderer = gameObject.GetComponent<MeshRenderer>();
            m_meshFilter = gameObject.GetComponent<MeshFilter>();
            m_bounds = m_meshFilter.sharedMesh.bounds;
            m_normalizedFlowDirection = normalizedFlowDirection;
            m_resolution = resolution;
            m_radius = radius;

            Texture = new Texture2D(m_resolution, m_resolution, TextureFormat.RGBAFloat, false, false);
            for (int x = 0; x < Texture.width; x++)
            {
                for (int y = 0; y < Texture.height; y++)
                {
                    Texture.SetPixel(x, y, new Color(0.5f, 0.5f, 0, 1f));
                }
            }
            Texture.Apply();
        }

        public void WriteHits(List<(RaycastHit hit, Vector3 reflect, Ray ray)> hitFlowList)
        {
            foreach (var hitData in hitFlowList)
            {
                // Draw line on texture from ray start point to hit point with color based on distance from the current pixel in world space to the hit point
                var startPoint = new Vector2(hitData.ray.origin.x, hitData.ray.origin.z);
                var endPoint = new Vector2(hitData.hit.point.x, hitData.hit.point.z);
                // Convert world coordinates to texture coordinates
                Vector2 texP1 = WorldToTexture(startPoint);
                Vector2 texP2 = WorldToTexture(endPoint);
                DrawFlowLineOnTexture(texP1, texP2, m_radius);

            }
            Texture.Apply();
            ApplyToMesh(m_meshRenderer, "_FlowMap");
        }

        /// <summary>
        /// Draws a flow line on the texture between two points using Bresenham's line algorithm.
        /// </summary>
        /// <param name="p1">The starting point of the line. start point of the ray</param>
        /// <param name="p2">The ending point of the line. hit point</param>
        /// <param name="radius">The radius of the effect</param>
        public void DrawFlowLineOnTexture(Vector2 p1, Vector2 p2, float radius)
        {
            // Bresenham's line algorithm
            int x0 = Mathf.FloorToInt(p1.x);
            int y0 = Mathf.FloorToInt(p1.y);
            int x1 = Mathf.FloorToInt(p2.x);
            int y1 = Mathf.FloorToInt(p2.y);

            int dx = Mathf.Abs(x1 - x0);
            int dy = Mathf.Abs(y1 - y0);
            int sx = (x0 < x1) ? 1 : -1;
            int sy = (y0 < y1) ? 1 : -1;
            int err = dx - dy;

            while (true)
            {
                // Check if the pixel is inside the UV coordinate
                if (x0 >= 0 && x0 < Texture.width && y0 >= 0 && y0 < Texture.height)
                {
                    float distanceToP2 = Vector2.Distance(new Vector2(x0, y0), p2);
                    if (distanceToP2 <= radius)
                    {
                        // Calculate the effect strength based on distance to p2
                        float effectStrength = 1f - (distanceToP2 / radius);

                        // Calculate the opposite direction
                        Vector2 oppositeDirection = -m_normalizedFlowDirection * effectStrength;

                        // Get the current color
                        var currentColor = Texture.GetPixel(x0, y0);

                        // Convert the new flow direction to color
                        var newColor = Utils.ConvertDirectionToColor(oppositeDirection);
                        var flowDirectionColor = Utils.ConvertDirectionToColor(m_normalizedFlowDirection);

                        // Lerp between all colors 
                        var color = Color.Lerp(newColor, currentColor, 0.5f);
                        // color = Color.Lerp(currentColor, color, effectStrength);

                        Texture.SetPixel(x0, y0, color);
                    }
                    else
                    {
                        // Get the current color
                        var currentColor = Texture.GetPixel(x0, y0);

                        // Convert the new flow direction to color
                        var newColor = Utils.ConvertDirectionToColor(m_normalizedFlowDirection);
                        // Lerp between current and new color based on effect strength
                        var color = Color.Lerp(currentColor, newColor, 0.5f);

                        Texture.SetPixel(x0, y0, color);
                    }
                }

                if (x0 == x1 && y0 == y1) break;

                int e2 = 2 * err;
                if (e2 > -dy)
                {
                    err -= dy;
                    x0 += sx;
                }
                if (e2 < dx)
                {
                    err += dx;
                    y0 += sy;
                }
            }
        }


        private Vector2 WorldToTexture(Vector2 worldPos)
        {
            Transform transform = m_meshRenderer.transform;
            Vector3 localPos = transform.InverseTransformPoint(new Vector3(worldPos.x, transform.position.y, worldPos.y));
            float u = 1 - (localPos.x - m_bounds.min.x) / m_bounds.size.x;
            float v = 1 - (localPos.z - m_bounds.min.z) / m_bounds.size.z;
            return new Vector2(u * Texture.width, v * Texture.height);
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
    public Resolution textureResolution = Resolution._128x128;
    public LayerMask m_layerMask;
    [SerializeField] Transform m_flowDirectionTransform;
    [SerializeField, Range(0f, 45f)] float m_chaosAngle = 15f;
    [SerializeField] bool m_drawGizmos = true;
    [SerializeField, Range(1, 500)] int m_numberOfRays = 1;
    [SerializeField, Range(1f, 5)] float m_radius = 4f;

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
        Logger.Active = m_drawGizmos;
        m_meshRenderer = GetComponent<MeshRenderer>();
        m_meshFilter = GetComponent<MeshFilter>();

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
        m_rayLine = new RayLine(
            sphereCenter,
            startPoint,
            endPoint,
            (int)textureResolution,
            normalizedFlowDirection,
            sphereRadius,
            m_chaosAngle,
            m_layerMask,
            m_numberOfRays);
        // we will cast rays from the start point to the end point and check if they hit any collider
        m_flowmap = new Flowmap((int)textureResolution, gameObject, normalizedFlowDirection, m_radius);
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
