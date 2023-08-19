using System;
using System.Collections.Generic;
using UnityEngine;
public class RayProjector
{
    private Ray[] m_rays;
    private int m_rayCount;
    private Vector2 m_size;
    private Plane m_plane;
    private Vector3 m_planeOrigin;
    private float m_rayLenght = 0.5f;

    public RayProjector(
        Vector3 size,
        Plane plane,
        Vector3 planeOrigin,
        int rayCount,
        float rayLenght = 0.5f)
    {
        m_rayLenght = rayLenght;
        m_rayCount = rayCount;
        m_plane = plane;
        m_planeOrigin = planeOrigin;
        m_rays = new Ray[rayCount * rayCount];
        m_size = new Vector2(size.x, size.z);
        InitializeRaysAlongPlane();
    }

    private void InitializeRaysAlongPlane()
    {
        var rayIndex = 0;
        var raySpacing = m_size / m_rayCount;
        var rayOrigin = m_planeOrigin - new Vector3(m_size.x / 2, 0, m_size.y / 2) + new Vector3(raySpacing.x / 2, 0, raySpacing.y / 2);
        for (int i = 0; i < m_rayCount; i++)
        {
            for (int j = 0; j < m_rayCount; j++)
            {
                var ray = new Ray(rayOrigin + new Vector3(raySpacing.x * i, 0, raySpacing.y * j), m_plane.normal);
                m_rays[rayIndex++] = ray;
            }
        }
    }


    public void Draw()
    {
        for (int i = 0; i < m_rays.Length; i++)
        {
            var ray = m_rays[i];
            var color = Utils.ConvertDirectionToColor(new Vector2(ray.direction.x, ray.direction.z));
            Debug.DrawRay(ray.origin, new Vector3(ray.direction.x, 0, ray.direction.z) * m_rayLenght, color);
        }
    }

    internal Ray[] GetRays() => m_rays;
}