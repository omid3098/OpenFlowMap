using UnityEngine;

[CreateAssetMenu(fileName = "RealisticFlow", menuName = "OpenFlowmap/Processor/RealisticFlow")]
public class RealisticFlow : RayProcessor
{
    [SerializeField, Range(0, 360)] float angle = 0;
    [SerializeField, Range(0.001f, 2f)] float m_strength = 1;
    [SerializeField, Range(0.1f, 1f)] float m_radius = 1;
    [SerializeField, Range(1, 128)] int m_iterationCount = 10;
    [SerializeField, Range(0f, 1f)] float m_deltaT = 0.5f;
    [SerializeField, Range(0f, 0.0005f)] float m_viscosity = 0.0001f;

    private MSAFluidSolver2D fluidSolver;
    private int resolution;

    private Vector3 NormalizedDirection
    {
        get
        {
            float radians = angle * Mathf.Deg2Rad;
            return new Vector3(Mathf.Cos(radians), 0, Mathf.Sin(radians)).normalized;
        }
    }

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
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                if (angle == 0 && y == 0)
                    AddForce(x, y);
                else if (angle > 0 && angle < 90 && (y == 0 || x == 0))
                    AddForce(x, y);
                else if (angle == 90 && x == 0)
                    AddForce(x, y);
                else if (angle > 90 && angle < 180 && (x == 0 || y == resolution - 1))
                    AddForce(x, y);
                else if (angle == 180 && y == resolution - 1)
                    AddForce(x, y);
                else if (angle > 180 && angle < 270 && (y == resolution - 1 || x == resolution - 1))
                    AddForce(x, y);
                else if (angle == 270 && x == resolution - 1)
                    AddForce(x, y);
                else if (angle > 270 && angle <= 360 && (x == resolution - 1 || y == 0))
                    AddForce(x, y);
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

    private void AddForce(int x, int y, float weight = 1.0f)
    {
        if (x < 0) x = 0;
        else if (x > resolution) x = resolution;
        if (y < 0) y = 0;
        else if (y > resolution) y = resolution;

        var index = fluidSolver.getIndexForCellPosition(x, y);
        float u = NormalizedDirection.z * m_strength * weight;
        float v = NormalizedDirection.x * m_strength * weight;

        fluidSolver.uOld[index] = u;
        fluidSolver.vOld[index] = v;
    }
}
