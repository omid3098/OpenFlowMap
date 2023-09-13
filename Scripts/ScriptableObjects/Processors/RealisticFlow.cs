using UnityEngine;

[CreateAssetMenu(fileName = "RealisticFlow", menuName = "OpenFlowmap/Processor/RealisticFlow")]
public class RealisticFlow : RayProcessor
{
    [SerializeField, Range(0, 360)] float m_angle = 0;
    [SerializeField, Range(0.001f, 2f)] float m_strength = 1;
    [SerializeField, Range(0.1f, 1f)] float m_radius = 1;
    [SerializeField, Range(1, 128)] int m_iterationCount = 10;
    [SerializeField, Range(0f, 1f)] float m_deltaT = 0.5f;
    [SerializeField, Range(0f, 0.0005f)] float m_viscosity = 0.0001f;

    private MSAFluidSolver2D fluidSolver;
    private int resolution;

    internal override void Execute(RayProjector rayProjector)
    {
        resolution = rayProjector.RayCount;
        if (fluidSolver == null || fluidSolver.getWidth() - 2 != resolution)
        {
            fluidSolver = new MSAFluidSolver2D(resolution, resolution);
        }
        fluidSolver.setDeltaT(m_deltaT).setVisc(m_viscosity).setSolverIterations(m_iterationCount);

        Solve(rayProjector);
    }

    private void Solve(RayProjector rayProjector)
    {
        // SetCurrentDirections(rayProjector);
        AddForceBasedOnAngle();
        Collide(rayProjector);
        fluidSolver.update();
        UpdateRayDirections(rayProjector);
    }

    private void AddForceBasedOnAngle()
    {
        float radians = m_angle * Mathf.Deg2Rad;
        Vector3 direction = new Vector3(Mathf.Cos(radians) * m_strength, 0, Mathf.Sin(radians) * m_strength);

        if (m_angle == 0 || m_angle == 360)
        {
            int y = 0;
            for (int x = 0; x < resolution; x++)
            {
                AddForce(x, y, direction);
            }
        }
        else if (m_angle > 0 && m_angle < 90)
        {
            //(y == 0 || x == 0)
            for (int x = 0; x < resolution; x++)
            {
                AddForce(x, 0, direction);
            }
            for (int y = 1; y < resolution; y++) // don't process (0, 0) again
            {
                AddForce(0, y, direction);
            }
        }
        else if (m_angle == 90)
        {
            int x = 0;
            for (int y = 0; y < resolution; y++)
            {
                AddForce(x, y, direction);
            }
        }
        else if (m_angle > 90 && m_angle < 180)
        {
            //(x == 0 || y == resolution - 1))
            for (int x = 0; x < resolution; x++)
            {
                AddForce(x, resolution - 1, direction);
            }
            for (int y = 0; y < resolution - 1; y++) // don't process (0, resolution-1) again
            {
                AddForce(0, y, direction);
            }
        }
        else if (m_angle == 180)
        {
            int y = resolution - 1;
            for (int x = 0; x < resolution; x++)
            {
                AddForce(x, y, direction);
            }
        }
        else if (m_angle > 180 && m_angle < 270)
        {
            //(y == resolution - 1 || x == resolution - 1)
            for (int x = 0; x < resolution; x++)
            {
                AddForce(x, resolution - 1, direction);
            }
            for (int y = 0; y < resolution - 1; y++) // don't process (resolution-1, resolution-1) again
            {
                AddForce(resolution - 1, y, direction);
            }
        }
        else if (m_angle == 270)
        {
            int x = resolution - 1;
            for (int y = 0; y < resolution; y++)
            {
                AddForce(x, y, direction);
            }
        }
        else if (m_angle > 270 && m_angle < 360)
        {
            //(x == resolution - 1 || y == 0)
            for (int x = 0; x < resolution; x++)
            {
                AddForce(x, 0, direction);
            }
            for (int y = 1; y < resolution; y++) // don't process (resolution-1, 0) again
            {
                AddForce(resolution - 1, y, direction);
            }
        }
    }


    private void SetCurrentDirections(RayProjector rayProjector)
    {
        var rays = rayProjector.GetRays();
        // loop through all the rays in x and y direction
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                int indexInRays = rayProjector.GetIndex(x, y);
                Ray ray = rays[indexInRays];
                int indexInSolver = fluidSolver.getIndexForCellPosition(x + 1, y + 1);
                fluidSolver.u[indexInSolver] = ray.direction.x;
                fluidSolver.v[indexInSolver] = ray.direction.z;
            }
        }
    }

    private void UpdateRayDirections(RayProjector rayProjector)
    {
        var rays = rayProjector.GetRays();
        // loop through all the rays in x and y direction
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                int indexInSolver = fluidSolver.getIndexForCellPosition(x + 1, y + 1);
                float u = fluidSolver.u[indexInSolver];
                float v = fluidSolver.v[indexInSolver];
                int indexInRays = rayProjector.GetIndex(x, y);
                Ray ray = rays[indexInRays];
                ray.direction = new Vector3(v, ray.direction.y, u);
                rays[indexInRays] = ray;
            }
        }
    }

    private void Collide(RayProjector rayProjector)
    {
        var rays = rayProjector.GetRays();
        // loop through all the rays in x and y direction
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                int indexInRays = rayProjector.GetIndex(x, y);
                var ray = rays[indexInRays];
                if (Physics.CheckSphere(ray.origin, m_radius, openFlowmapBehaviour.LayerMask))
                {
                    AddBarrier(x, y);
                }
            }
        }
    }

    private void AddBarrier(int x, int y)
    {
        int indexInSolver = fluidSolver.getIndexForCellPosition(x + 1, y + 1);
        fluidSolver.u[indexInSolver] = 0;
        fluidSolver.v[indexInSolver] = 0;
        fluidSolver.uOld[indexInSolver] = 0;
        fluidSolver.vOld[indexInSolver] = 0;
    }

    private void AddForce(int x, int y, Vector3 direction, float weight = 1.0f)
    {
        int indexInSolver = fluidSolver.getIndexForCellPosition(x + 1, y + 1);
        float u = direction.z * weight;
        float v = direction.x * weight;

        fluidSolver.uOld[indexInSolver] = u;
        fluidSolver.vOld[indexInSolver] = v;
    }
}
