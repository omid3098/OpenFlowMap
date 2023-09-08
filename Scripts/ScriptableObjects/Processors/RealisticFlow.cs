using UnityEngine;

[CreateAssetMenu(fileName = "RealisticFlow", menuName = "OpenFlowmap/Processor/RealisticFlow")]
public class RealisticFlow : RayProcessor
{
    [SerializeField] Vector2 m_directions = new Vector2(1, 0);
    [SerializeField, Range(0.001f, 2f)] float m_strength = 1;
    [SerializeField, Range(0.1f, 1f)] float m_radius = 1;
    [SerializeField, Range(1, 128)] int m_iterationCount = 10;
    [SerializeField, Range(0f, 1f)] float m_deltaT = 0.5f;
    [SerializeField, Range(0f, 0.0005f)] float m_viscosity = 0.0001f;

    private MSAFluidSolver2D fluidSolver;
    private int resolution;

    private Vector3 NormalizedDirection => new Vector3(m_directions.x, 0, m_directions.y).normalized;

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
        AddInitialForce();
        Collide(rayProjector);
        fluidSolver.update();
        UpdateRayDirections(rayProjector);
    }

    private void AddInitialForce()
    {
        // add force from all points in the first row
        for (int x = 0; x < resolution; x++)
        {
            // if (x % 5 == 0)
            {
                AddForce(x, 0);
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
                int indexRays = rayProjector.GetIndex(x, y);
                Ray ray = rays[indexRays];
                int indexSolver = fluidSolver.getIndexForCellPosition(x, y);
                fluidSolver.u[indexSolver] = ray.direction.x;
                fluidSolver.v[indexSolver] = ray.direction.z;
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
                int indexSolver = fluidSolver.getIndexForCellPosition(x, y);
                float u = fluidSolver.u[indexSolver];
                float v = fluidSolver.v[indexSolver];
                int indexRays = rayProjector.GetIndex(x, y);
                Ray ray = rays[indexRays];
                Vector3 newDirection = new Vector3(v, ray.direction.y, u).normalized;
                rays[indexRays] = new Ray(ray.origin, newDirection);
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
        if (x < 0) x = 0;
        else if (x > resolution) x = resolution;
        if (y < 0) y = 0;
        else if (y > resolution) y = resolution;
        var indexInSolver = fluidSolver.getIndexForCellPosition(x, y);
        fluidSolver.u[indexInSolver] = 0;
        fluidSolver.v[indexInSolver] = 0;
        fluidSolver.uOld[indexInSolver] = 0;
        fluidSolver.vOld[indexInSolver] = 0;
    }

    private void AddForce(int x, int y)
    {
        if (x < 0) x = 0;
        else if (x > resolution) x = resolution;
        if (y < 0) y = 0;
        else if (y > resolution) y = resolution;
        var index = fluidSolver.getIndexForCellPosition(x, y);
        float u = NormalizedDirection.z * m_strength;
        float v = NormalizedDirection.x * m_strength;
        fluidSolver.uOld[index] = u;
        fluidSolver.vOld[index] = v;
    }
}
