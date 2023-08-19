using UnityEngine;

public class GlobalFlowDirection : Effector
{
    [SerializeField] Vector2 m_flowDirection = new Vector2(1, 0);
    [SerializeField, Range(0f, 1f)] float m_flowStrenght = 0.5f;

    internal override void Execute()
    {
        m_flowDirection = new Vector2(Mathf.Clamp(m_flowDirection.x, -1, 1), Mathf.Clamp(m_flowDirection.y, -1, 1));
        Ray[] rays = openFlowmap.RayProjector.GetRays();
        for (int i = 0; i < rays.Length; i++)
        {
            Ray ray = rays[i];
            // push the ray in the direction of the flow
            ray.direction = Vector3.Lerp(ray.direction, m_flowDirection, m_flowStrenght);
            ray.direction.Normalize();
            rays[i] = ray;
        }
    }
}
