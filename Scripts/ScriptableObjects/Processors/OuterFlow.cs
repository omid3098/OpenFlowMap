using UnityEngine;

[CreateAssetMenu(fileName = "OuterFlow", menuName = "OpenFlowmap/Processor/OuterFlow")]
public class OuterFlow : RayProcessor
{
    [Range(0.1f, 2)] public float m_radius = 0.5f;
    [Range(4, 30)] public int outerFlowRayCount = 12;

    private Collider[] m_colliders;

    public override void Initialize()
    {
        if (m_colliders == null)
        {
            m_colliders = new Collider[1];
        }
    }

    internal override void Execute(RayProjector rayProjector)
    {
        Ray[] mainRaysArray = rayProjector.GetRays();
        LayerMask layerMask = openFlowmapBehaviour.LayerMask;
        for (int i = 0; i < mainRaysArray.Length; i++)
        {
            Ray projectorRay = mainRaysArray[i];
            var position = projectorRay.origin;
            // use SphereOverlap to get all colliders in a radius
            int nearbyColliders = Physics.OverlapSphereNonAlloc(position, m_radius, m_colliders, openFlowmapBehaviour.LayerMask);

            if (nearbyColliders > 0)
            {
                var sum = Vector3.zero;
                // Cast ray in outerFlowRayCount directions from the ray origin aligned with the mesh surface
                for (int j = 0; j < outerFlowRayCount; j++)
                {
                    float angle = j * Mathf.PI * 2 / outerFlowRayCount;
                    Vector3 direction = new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle));

                    // Cast ray in direction
                    if (Physics.Raycast(position, direction, out var hit, m_radius, layerMask))
                    {
                        var distance = Vector3.Distance(position, hit.point);
                        // if the distance is too short, this point should effect more than the others
                        // var weight = 1 - distance / m_radius;
                        sum += hit.normal * distance;
                    }
                }
                // Debug.DrawRay(position, sum, Color.red);

                // normalize the sum of all normals
                // sum = sum / 8;
                // add the sum of all normals to the original ray direction
                projectorRay.direction += sum;

                mainRaysArray[i] = projectorRay;
            }
        }
    }
}
