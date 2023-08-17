using System;
using System.Collections.Generic;
using UnityEngine;

public class RayLine
{
    public Vector3 Origin { get; }
    public Vector3 StartPoint { get; }
    public Vector3 EndPoint { get; }
    public int Resolution { get; }
    public Vector2 FlowDirection { get; private set; }
    public float Radius { get; }
    public float ChaosAngle { get; private set; }
    public LayerMask LayerMask { get; }
    private List<Vector3> m_rayStartPoints = new List<Vector3>();
    private float m_stepLength;
    public List<(RaycastHit hit, Vector3 reflect)> HitDataList { get; }

    public RayLine(Vector3 origin,
                   Vector2 startPoint,
                   Vector2 endPoint,
                   int resolution,
                   Vector2 flowDirection,
                   float radius,
                   float chaosAngle,
                   LayerMask layerMask)
    {
        HitDataList = new List<(RaycastHit hit, Vector3 reflect)>();
        Origin = origin;
        LayerMask = layerMask;
        ChaosAngle = chaosAngle;
        StartPoint = origin + new Vector3(startPoint.x, origin.y, startPoint.y);
        EndPoint = origin + new Vector3(endPoint.x, origin.y, endPoint.y);
        var lineLength = Vector3.Distance(StartPoint, EndPoint);
        m_stepLength = lineLength / resolution;
        Resolution = resolution;
        FlowDirection = flowDirection;
        Radius = radius;
        for (int i = 0; i < resolution; i++)
        {
            float x = StartPoint.x + (EndPoint.x - StartPoint.x) * i / resolution;
            float z = StartPoint.z + (EndPoint.z - StartPoint.z) * i / resolution;
            m_rayStartPoints.Add(new Vector3(x, StartPoint.y, z));
        }
        Draw();
        CastRays();
    }

    public void CastRays()
    {
        Vector3 direction = new Vector3(FlowDirection.x, 0, FlowDirection.y).normalized;
        foreach (var rayStartPoint in m_rayStartPoints)
        {
            CastRay(rayStartPoint, direction);
            CastRay(rayStartPoint, Quaternion.AngleAxis(ChaosAngle, Vector3.up) * direction);
            CastRay(rayStartPoint, Quaternion.AngleAxis(-ChaosAngle, Vector3.up) * direction);
        }
    }

    private void CastRay(Vector3 startPoint, Vector3 direction)
    {
        Ray ray = new Ray(startPoint, direction);
        if (Physics.Raycast(ray, out RaycastHit hit, LayerMask))
        {
            // Visualize the hit point
            Logger.DrawLine(startPoint, hit.point, Color.yellow);
            Vector3 reflect = Vector3.Reflect(direction, hit.normal);
            HitDataList.Add((hit, reflect));
            // Debug.DrawRay(hit.point, reflect, Color.red);
        }
        else // The ray didn't hit any collider
        {
            // Visualize the ray to the end of the bounds
            Vector3 newStartPoint = startPoint + direction * m_stepLength;
            Logger.DrawRay(startPoint, direction, Color.green);
            if (Vector3.Distance(newStartPoint, Origin) < Radius)
            {
                CastRay(newStartPoint, direction);
            }
        }
    }

    public void Draw()
    {
        // Visualize the line
        Logger.DrawLine(StartPoint, EndPoint, Color.red);
    }

    public void Dispose()
    {
        m_rayStartPoints.Clear();
        m_rayStartPoints = null;
    }

    internal void SetFlowDirection(Vector2 normalizedFlowDirection)
    {
        FlowDirection = normalizedFlowDirection;
    }
}