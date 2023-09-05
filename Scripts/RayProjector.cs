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
    private float m_rayLength = 0.5f;

    public RayProjector(
        Vector3 size,
        Plane plane,
        Vector3 planeOrigin,
        int rayCount,
        float rayLength = 0.5f)
    {
        m_rayLength = rayLength;
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
            Debug.DrawRay(ray.origin, new Vector3(ray.direction.x, ray.direction.y * 0.2f, ray.direction.z) * m_rayLength, color);
        }
    }

    internal Ray[] GetRays() => m_rays;

    internal Ray GetRay(int index) => m_rays[index];
    internal Ray GetRay(int x, int y) => m_rays[GetIndex(x, y)];


    internal int GetNeighborIndex(int x, int y, int neighborIndex)
    {
        // 0 1 2
        // 3 x 4
        // 5 6 7
        // if x , y are out of bounds, return -1
        if (x < 0 || x >= m_rayCount || y < 0 || y >= m_rayCount)
            return -1;

        switch (neighborIndex)
        {
            case 0:
                return GetIndex(x - 1, y - 1);
            case 1:
                return GetIndex(x, y - 1);
            case 2:
                return GetIndex(x + 1, y - 1);
            case 3:
                return GetIndex(x - 1, y);
            case 4:
                return GetIndex(x + 1, y);
            case 5:
                return GetIndex(x - 1, y + 1);
            case 6:
                return GetIndex(x, y + 1);
            case 7:
                return GetIndex(x + 1, y + 1);
            default:
                return -1;
        }
    }

    internal int GetIndex(int x, int y)
    {
        if (x < 0 || x >= m_rayCount || y < 0 || y >= m_rayCount)
            return -1;
        return x + y * m_rayCount;
    }
}