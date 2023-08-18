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

    private int m_numberOfRays;

    public float ChaosAngle { get; private set; }
    public LayerMask LayerMask { get; }
    private List<Vector3> m_rayStartPoints = new List<Vector3>();
    private float m_stepLength;
    public List<(RaycastHit hit, Vector3 reflect, Ray ray)> HitDataList { get; }

    public RayLine(Vector3 origin,
                   Vector2 startPoint,
                   Vector2 endPoint,
                   int resolution,
                   Vector2 flowDirection,
                   float radius,
                   float chaosAngle,
                   LayerMask layerMask,
                   int numberOfRays)
    {
        HitDataList = new List<(RaycastHit hit, Vector3 reflect, Ray ray)>();
        Origin = origin;
        LayerMask = layerMask;
        ChaosAngle = chaosAngle;
        StartPoint = new Vector3(startPoint.x, origin.y, startPoint.y);
        EndPoint = new Vector3(endPoint.x, origin.y, endPoint.y);
        var lineLength = Vector3.Distance(StartPoint, EndPoint);
        m_stepLength = lineLength / resolution;
        Resolution = resolution;
        FlowDirection = flowDirection;
        Radius = radius;
        m_numberOfRays = numberOfRays;

        var lineMidPoint = (StartPoint + EndPoint) / 2f;
        var lineDirection = (EndPoint - StartPoint).normalized;
        var pointDistance = lineLength / Mathf.Max(m_numberOfRays - 1, 1); // Ensure at least one ray is created
        for (int i = 0; i < m_numberOfRays; i++)
        {
            var point = StartPoint + lineDirection * (i * pointDistance);
            var direction = (point - lineMidPoint).normalized;
            var rayStartPoint = point + direction * pointDistance / 2f;
            m_rayStartPoints.Add(rayStartPoint);
        }
        // for (int i = 0; i < resolution; i++)
        // {
        //     float x = StartPoint.x + (EndPoint.x - StartPoint.x) * i / resolution;
        //     float z = StartPoint.z + (EndPoint.z - StartPoint.z) * i / resolution;
        //     m_rayStartPoints.Add(new Vector3(x, StartPoint.y, z));
        // }
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
        if (Physics.SphereCast(ray, 0.1f, out RaycastHit hit, LayerMask)) // The ray hit something
        {
            // Visualize the hit point
            Logger.DrawLine(startPoint, hit.point, Color.yellow);
            Vector3 reflect = Vector3.Reflect(direction, hit.normal);
            HitDataList.Add((hit, reflect, ray));
            // Debug.DrawRay(hit.point, reflect, Color.red);
        }
        else // The ray didn't hit any collider
        {
            // Visualize the ray to the end of the bounds
            Vector3 newStartPoint = startPoint + direction * m_stepLength;
            Logger.DrawRay(startPoint, direction, Color.blue);
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