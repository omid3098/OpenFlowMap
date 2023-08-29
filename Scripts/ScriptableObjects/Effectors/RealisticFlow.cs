using System;
using Unity.Collections;
using UnityEngine;

[CreateAssetMenu(fileName = "RealisticFlow", menuName = "OpenFlowmap/Processor/RealisticFlow")]
public class RealisticFlow : RayProcessor
{
    [SerializeField] Vector2 m_directions = new Vector2(1, 0);
    [SerializeField, Range(0.001f, 1f)] float m_strenght = 1;
    [SerializeField, Range(0.1f, 1f)] float m_radius = 1;
    [SerializeField] int m_iterationCount = 10;
    private int resolution;
    private MSAFluidSolver2D fluidSolver;

    Vector3 NormalizedDirection => new Vector3(m_directions.x, 0, m_directions.y).normalized;
    internal override void Execute()
    {
        resolution = openFlowmapConfig.RayResolution;
        fluidSolver = new MSAFluidSolver2D(openFlowmapConfig.RayResolution, openFlowmapConfig.RayResolution);
        fluidSolver.enableRGB(true).setFadeSpeed(0.003f).setDeltaT(0.5f).setVisc(0.0001f);

        // add test force to the solver
        AddForce(resolution / 2, resolution / 2);

        UpdateFluidSolver();

        UpdateRayDirections();
    }

    private void UpdateRayDirections()
    {
        var rays = openFlowmapConfig.RayProjector.GetRays();
        // loop through all the rays in x and y direction
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                int indexInSolver = fluidSolver.getIndexForNormalizedPosition(x, y);
                float u = fluidSolver.u[indexInSolver];
                float v = fluidSolver.v[indexInSolver];
                Vector2 direction = new Vector2(u, v);
                int indexInRays = openFlowmapConfig.RayProjector.GetIndex(x, y);
                Ray ray = rays[indexInRays];
                rays[indexInRays] = new Ray(ray.origin, new Vector3(direction.x, ray.direction.y, direction.y));
            }
        }
    }

    private void AddForce(int x, int y)
    {
        var index = fluidSolver.getIndexForNormalizedPosition(x, y);
        if (x < 0) x = 0;
        else if (x > resolution) x = resolution;
        if (y < 0) y = 0;
        else if (y > resolution) y = resolution;
        // var color = Utils.ConvertDirectionToColor(NormalizedDirection);
        // fluidSolver.rOld[index] += color.r * speed;
        // fluidSolver.gOld[index] += color.g * speed;
        // fluidSolver.bOld[index] += color.b * speed;

        fluidSolver.uOld[index] += NormalizedDirection.x * m_strenght;
        fluidSolver.vOld[index] += NormalizedDirection.z * m_strenght;
    }

    private void UpdateFluidSolver()
    {
        for (int i = 0; i < m_iterationCount; i++)
        {
            fluidSolver.update();
        }
    }
}