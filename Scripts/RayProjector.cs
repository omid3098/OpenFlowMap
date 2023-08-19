using System;
using System.Collections.Generic;
using UnityEngine;
public class RayProjector
{
    private Ray[] m_rays;
    private int m_rayCount;
    private Transform m_transform;
    private Vector2 m_size;

    public RayProjector(Transform transform, Vector3 size, int rayCount)
    {
        m_rayCount = rayCount;
        m_rays = new Ray[rayCount * rayCount];
        m_transform = transform;
        m_size = new Vector2(size.x, size.z);
        InitializeRays();
    }

    private void InitializeRays()
    {
        for (int x = 0; x < m_rayCount; x++)
        {
            for (int y = 0; y < m_rayCount; y++)
            {
                var pixelPosition = new Vector2(
                    (x + 0.5f) / m_rayCount * m_size.x,
                    (y + 0.5f) / m_rayCount * m_size.y
                );
                var worldPosition = m_transform.TransformPoint(new Vector3(
                    pixelPosition.x - m_size.x / 2f,
                    0,
                    pixelPosition.y - m_size.y / 2f
                ));
                var direction = m_transform.up;
                m_rays[x * m_rayCount + y] = new Ray(worldPosition, direction);
            }
        }
    }

    public void Draw()
    {
        for (int i = 0; i < m_rays.Length; i++)
        {
            var ray = m_rays[i];
            var color = Utils.ConvertDirectionToColor(new Vector2(ray.direction.x, ray.direction.z));
            Debug.DrawRay(ray.origin, ray.direction * 0.5f, color);
        }
    }

    internal Ray[] GetRays() => m_rays;
}