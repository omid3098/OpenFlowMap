using UnityEngine;

[CreateAssetMenu(fileName = "GlobalFlowDirection", menuName = "OpenFlowmap/Processor/GlobalFlowDirection")]
public class GlobalFlowDirection : RayProcessor
{
    [SerializeField] Vector2 m_flowDirection = new Vector2(1, 0);
    [SerializeField, Range(0f, 1f)] float m_flowStrength = 0.5f;

    internal override void Execute(RayProjector rayProjector)
    {
        m_flowDirection = new Vector2(Mathf.Clamp(m_flowDirection.x, -1, 1), Mathf.Clamp(m_flowDirection.y, -1, 1));
        Ray[] rays = rayProjector.GetRays();
        for (int i = 0; i < rays.Length; i++)
        {
            Ray ray = rays[i];
            // push the ray in the direction of the flow
            ray.direction = Vector3.Lerp(ray.direction, new Vector3(m_flowDirection.x, 0, m_flowDirection.y), m_flowStrength);
            ray.direction.Normalize();
            rays[i] = ray;
        }
    }
}
