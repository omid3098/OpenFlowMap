using System;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "TestRealisticFlow", menuName = "OpenFlowmap/Processor/TestRealisticFlow")]
public class TestRealisticFlow : RayProcessor
{
    [SerializeField] Vector2 m_directions = new Vector2(1, 0);
    [SerializeField, Range(0.1f, 1f)] float m_rayDistance = 0.2f;
    [SerializeField, Range(0.001f, 1f)] float m_strenght = 1;
    [SerializeField] int m_rayCount = 1;
    private Vector3 target;
    private Vector3 flowDirection;
    private Vector3 lineDirection;
    private float radius;
    private Vector3 center;
    private Color color;
    // private Ray[] rays;
    List<(Vector3 start, Vector3 end)> m_rayLines = new List<(Vector3 start, Vector3 end)>();
    private Vector3 lineStart;
    private Vector3 lineEnd;
    private Vector3 NormalizedDirection => new Vector3(m_directions.x, 0, m_directions.y).normalized;
    internal override void Execute()
    {
        m_rayLines.Clear();
        // rays = openFlowmapConfig.RayProjector.GetRays();
        // first draw a sphere over the flowmap region.
        var size = openFlowmapConfig.Size;
        radius = Mathf.Sqrt(size.x * size.x + size.z * size.z) / 2;
        center = openFlowmapConfig.PlaneOrigin;
        color = Color.red;
        target = center + NormalizedDirection * radius;
        flowDirection = -NormalizedDirection * m_strenght;

        // define a line. the center of the line is target and the direction is perpendicular to the flow direction
        // we will use this line to cast rays from the target toward the flow direction
        // plane      \
        // ------     \
        //      \     \
        // ----------- target
        //      \     \
        // ------     \
        //            \


        lineDirection = Vector3.Cross(NormalizedDirection, openFlowmapConfig.Plane.normal);
        lineStart = target + lineDirection * radius;
        lineEnd = target - lineDirection * radius;

        // cast m_rayCount rays from the rayLine toward the flow direction
        var lineLength = Vector3.Distance(lineStart, lineEnd);
        var lineSpacing = lineLength / m_rayCount;
        for (int i = 0; i < m_rayCount; i++)
        {
            var origin = lineStart - lineDirection * (lineSpacing * i);
            CastRecursiveRay(origin, flowDirection);
        }

        // CastRecursiveRay(target, flowDirection);
    }

    private void CastRecursiveRay(Vector3 origin, Vector3 direction)
    {
        // cast a ray to a short distance (0.1f) if we hit something, we cast again toward reflected vector of the ray along the hit surface
        if (Physics.SphereCast(origin, 0.1f, direction, out var hit, m_rayDistance, openFlowmapConfig.LayerMask))
        {
            var reflected = Vector3.Reflect(direction, hit.normal);
            // keep reflected vector on the plane
            reflected.y = 0;
            // make the lenght of the reflected vector the same as the original vector
            reflected = reflected.normalized * direction.magnitude;

            // add flow direction to the reflected direction
            reflected += flowDirection;
            CastRecursiveRay(hit.point, reflected);
            m_rayLines.Add((origin, hit.point));
        }
        else
        {
            // if we don't hit anything, we continue to cast the ray until we hit something or the ray is out of a sphere centered at the flowmap center with radius of the Mathf.Sqrt(size.x * size.x + size.z * size.z) / 2;
            if (Vector3.Distance(origin, center) <= radius * 2)
            {
                // Create a new ray from the target (origin + direction) affected towards the flow direction
                Vector3 newDirection = (direction + flowDirection).normalized;
                Vector3 newOrigin = origin + (direction * m_rayDistance);
                CastRecursiveRay(newOrigin, newDirection);
                m_rayLines.Add((origin, newOrigin));
            }
        }
    }

    internal override void Draw()
    {
        Debug.DrawLine(lineStart, lineEnd, Color.green);


        // Draw all rays
        foreach (var ray in m_rayLines)
        {
            var direction = ray.end - ray.start;
            var _color = Utils.ConvertDirectionToColor(direction);
            Debug.DrawLine(ray.start, ray.end, _color);
        }
    }
}