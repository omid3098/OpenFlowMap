using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "OuterFlow", menuName = "OpenFlowmap/OuterFlow")]
public class OuterFlow : Effector
{
    [Range(0.1f, 2)] public float m_radius = 0.5f;
    [Range(4, 30)] public int ourerFlowRayCount = 12;

    private Collider[] m_colliders;
    public override void Initialize()
    {
        m_colliders = new Collider[1];
    }

    internal override void Execute()
    {
        Ray[] mainRaysArray = openFlowmap.RayProjector.GetRays();
        for (int i = 0; i < mainRaysArray.Length; i++)
        {
            Ray projectorRay = mainRaysArray[i];
            var position = projectorRay.origin;
            // use SphereOverlap to get all colliders in a radius
            int nearbyColliders = Physics.OverlapSphereNonAlloc(position, m_radius, m_colliders, openFlowmap.LayerMask);

            if (nearbyColliders > 0)
            {
                // Cast ray in ourerFlowRayCount directions from the ray origin aligned with the mesh surface
                var directions = new List<Vector3>();
                for (int j = 0; j < ourerFlowRayCount; j++)
                {
                    float angle = j * Mathf.PI * 2 / ourerFlowRayCount;
                    Vector3 direction = new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle));
                    directions.Add(direction);
                }

                var sum = Vector3.zero;
                foreach (var direction in directions)
                {
                    // Cast ray in direction
                    var ray = new Ray(position, direction);
                    if (Physics.Raycast(ray, out var hit, m_radius, openFlowmap.LayerMask))
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

                var newRay = new Ray(position, projectorRay.direction);
                mainRaysArray[i] = newRay;
            }
        }
    }
}