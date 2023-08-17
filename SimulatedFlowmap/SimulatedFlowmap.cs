using UnityEngine;
[ExecuteInEditMode]
public class SimulatedFlowmap : MonoBehaviour
{
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution resolutionEnum = Resolution._128x128;
    public LayerMask layerMask;
    [SerializeField] Transform m_flowDirectionTransform;
    private Bounds m_bounds;
    private RayLine m_rayLine;
    private void Awake() => InitializeFlowmapPoints();
    private void OnValidate() => InitializeFlowmapPoints();

    public void InitializeFlowmapPoints()
    {
        m_bounds = GetComponent<MeshFilter>().sharedMesh.bounds;
    }

    private void Update()
    {
        CreateFlowLine();
        m_rayLine.Dispose();
        m_rayLine = null;
    }

    private void CreateFlowLine()
    {
        // define an imaginary finite line from border of a sphere around the the bounds of the mesh in the direction of the flow
        Vector3 sphereCenter = transform.position;
        float sphereRadius = m_bounds.extents.magnitude;
        Vector2 normalizedFlowDirection = new Vector2(m_flowDirectionTransform.forward.x, m_flowDirectionTransform.forward.z).normalized;
        Vector2 oppositeDirection = -normalizedFlowDirection;
        Vector2 offset = oppositeDirection * sphereRadius;
        Vector2 pointOnSphere = new Vector2(sphereCenter.x, sphereCenter.z) + offset;
        Vector2 toPointDirection = (pointOnSphere - new Vector2(sphereCenter.x, sphereCenter.z)).normalized;
        Vector2 tangentDirection = new Vector2(-toPointDirection.y, toPointDirection.x);
        Vector2 startPoint = pointOnSphere + tangentDirection * sphereRadius;
        Vector2 endPoint = pointOnSphere - tangentDirection * sphereRadius;
        m_rayLine = new RayLine(sphereCenter, startPoint, endPoint, (int)resolutionEnum, normalizedFlowDirection, sphereRadius);
        // we will cast rays from the start point to the end point and check if they hit any collider
    }

    private void Dispose()
    {
        if (m_rayLine != null)
        {
            m_rayLine.Dispose();
            m_rayLine = null;
        }
    }

    private void OnDestroy()
    {
        Dispose();
    }
}
