using UnityEngine;

[CreateAssetMenu(fileName = "GlobalFlowDirection", menuName = "OpenFlowmap/Processor/GlobalFlowDirection")]
public class GlobalFlowDirection : RayProcessor
{
    [SerializeField, Range(0, 360)] float m_angle = 0;
    [SerializeField, Range(0.001f, 2f)] float m_strength = 1;
    [SerializeField, Range(0f, 1f)] float m_blend = 0.5f;

    internal override void Execute(RayProjector rayProjector)
    {
        if (m_blend == 0f)
        {
            return;
        }
        float radians = m_angle * Mathf.Deg2Rad;
        Vector3 flowDirection = new Vector3(Mathf.Cos(radians) * m_strength, 0, Mathf.Sin(radians) * m_strength);
        Ray[] rays = rayProjector.GetRays();
        for (int i = 0; i < rays.Length; i++)
        {
            Ray ray = rays[i];
            // push the ray in the direction of the flow
            ray.direction = Vector3.Lerp(ray.direction, flowDirection, m_blend);
            rays[i] = ray;
        }
    }
}
