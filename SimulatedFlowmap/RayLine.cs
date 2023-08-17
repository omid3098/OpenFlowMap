
using System;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class RayLine
{
    public Vector3 Origin { get; }
    public float CalculationRadius { get; }
    public Vector3 StartPoint { get; }
    public Vector3 EndPoint { get; }
    public int Resolution { get; }
    Vector2 FlowDirection { get; }
    private List<Vector3> m_rayStartPoints = new List<Vector3>();
    public float chaosAngle = 15f; // In degrees

    public RayLine(Vector3 origin, Vector2 startPoint, Vector2 endPoint, int resolution, Vector2 flowDirection, float radius)
    {
        Origin = origin;
        CalculationRadius = radius * 1.5f;
        StartPoint = origin + new Vector3(startPoint.x, origin.y, startPoint.y);
        EndPoint = origin + new Vector3(endPoint.x, origin.y, endPoint.y);
        Resolution = resolution;
        FlowDirection = flowDirection;
        for (int i = 0; i < resolution; i++)
        {
            float x = StartPoint.x + (EndPoint.x - StartPoint.x) * i / resolution;
            float z = StartPoint.z + (EndPoint.z - StartPoint.z) * i / resolution;
            m_rayStartPoints.Add(new Vector3(x, StartPoint.y, z));
        }
        Draw();
        CastRays();
    }

    private void CastRays()
    {
        Vector3 direction = new Vector3(FlowDirection.x, 0, FlowDirection.y).normalized;
        foreach (var rayStartPoint in m_rayStartPoints)
        {
            CastRay(rayStartPoint, direction);
            CastRay(rayStartPoint, Quaternion.AngleAxis(chaosAngle, Vector3.up) * direction);
            CastRay(rayStartPoint, Quaternion.AngleAxis(-chaosAngle, Vector3.up) * direction);
        }
    }

    private void CastRay(Vector3 startPoint, Vector3 direction)
    {
        Ray ray = new Ray(startPoint, direction);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            // Visualize the hit point
            Debug.DrawLine(startPoint, hit.point, Color.yellow);
        }
        else // The ray didn't hit any collider
        {
            // Visualize the ray
            Debug.DrawRay(startPoint, direction, Color.green);
        }
    }

    public void Draw()
    {
        // Visualize the line
        Debug.DrawLine(StartPoint, EndPoint, Color.red);
    }

    public void Dispose()
    {
        m_rayStartPoints.Clear();
        m_rayStartPoints = null;
    }
}