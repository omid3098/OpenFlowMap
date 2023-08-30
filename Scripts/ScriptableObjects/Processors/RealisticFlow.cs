using System;
using UnityEngine;
using Unity.EditorCoroutines.Editor;
using System.Collections;

[CreateAssetMenu(fileName = "RealisticFlow", menuName = "OpenFlowmap/Processor/RealisticFlow")]
public class RealisticFlow : RayProcessor
{
    [SerializeField] Vector2 m_directions = new Vector2(1, 0);
    [SerializeField, Range(0.001f, 100f)] float m_strenght = 1;
    [SerializeField, Range(0.1f, 1f)] float m_radius = 1;
    [SerializeField, Range(1, 128)] int m_iterationCount = 10;
    [SerializeField] bool dynamicSim = true;
    [SerializeField] bool isRunning = false;
    static MSAFluidSolver2D fluidSolver;
    private int resolution;

    Vector3 NormalizedDirection => new Vector3(m_directions.x, 0, m_directions.y).normalized;
    internal override void Execute()
    {
        resolution = openFlowmapConfig.RayResolution;
        if (fluidSolver == null || fluidSolver.getWidth() - 2 != resolution)
        {
            fluidSolver = new MSAFluidSolver2D(openFlowmapConfig.RayResolution, openFlowmapConfig.RayResolution);
        }
        fluidSolver.setFadeSpeed(0.003f).setDeltaT(0.5f).setVisc(0.0001f).setSolverIterations(m_iterationCount);

        // use EditorCoroutineUtility.StartCoroutine to start a coroutine in the editor to repaint the scene view
        EditorCoroutineUtility.StartCoroutineOwnerless(UpdateFluidSolverCoroutine());

    }

    IEnumerator UpdateFluidSolverCoroutine()
    {
        if (isRunning) yield break;
        while (true && dynamicSim)
        {
            Solve();
            isRunning = true;

#if UNITY_EDITOR
            // Repaint scene view
            UnityEditor.EditorUtility.SetDirty(this);
            UnityEditor.SceneView.RepaintAll();
#endif
            yield return null;
        }
    }

    private void Solve()
    {
        // SetCurrentDirections();
        Collide();
        AddInitialForce();
        fluidSolver.update();
        UpdateRayDirections();
    }

    private void AddInitialForce()
    {
        // add force from all points in the first row
        for (int x = 0; x < resolution; x++)
        {
            if (x % 2 == 0)
            {
                AddForce(x, 0);
            }
        }
    }

    private void SetCurrentDirections()
    {
        var rays = openFlowmapConfig.RayProjector.GetRays();
        // loop through all the rays in x and y direction
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                int indexRays = openFlowmapConfig.RayProjector.GetIndex(x, y);
                Ray ray = rays[indexRays];
                int indexSolver = fluidSolver.getIndexForCellPosition(x, y);
                fluidSolver.u[indexSolver] = ray.direction.x;
                fluidSolver.v[indexSolver] = ray.direction.z;
            }
        }
    }

    private void UpdateRayDirections()
    {
        var rays = openFlowmapConfig.RayProjector.GetRays();
        // loop through all the rays in x and y direction
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                int indexSolver = fluidSolver.getIndexForCellPosition(x, y);
                float u = fluidSolver.u[indexSolver];
                float v = fluidSolver.v[indexSolver];
                int indexRays = openFlowmapConfig.RayProjector.GetIndex(x, y);
                Ray ray = rays[indexRays];
                Vector3 newDirection = new Vector3(u, ray.direction.y, v).normalized;
                rays[indexRays] = new Ray(ray.origin, newDirection);
            }
        }
    }

    private void Collide()
    {
        var rays = openFlowmapConfig.RayProjector.GetRays();
        // loop through all the rays in x and y direction
        for (int x = 0; x < resolution; x++)
        {
            for (int y = 0; y < resolution; y++)
            {
                int indexInRays = openFlowmapConfig.RayProjector.GetIndex(x, y);
                var ray = rays[indexInRays];
                if (Physics.CheckSphere(ray.origin, m_radius, openFlowmapConfig.LayerMask))
                {
                    AddBarrier(x, y);
                }
            }
        }
    }

    private void AddBarrier(int x, int y)
    {
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

        float u = NormalizedDirection.x * m_strenght;
        float v = NormalizedDirection.z * m_strenght;
        fluidSolver.uOld[index] += u;
        fluidSolver.vOld[index] += v;
    }
}