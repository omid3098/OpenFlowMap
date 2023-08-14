using System;
using Unity.Mathematics;
using UnityEngine;

public class OpenFlowMapGPU : MonoBehaviour
{
    public enum Resolution { _32x32 = 32, _64x64 = 64, _128x128 = 128, _256x256 = 256, _512x512 = 512, _1024x1024 = 1024 }
    public Resolution resolutionEnum = Resolution._128x128;
    [Range(0.1f, 1)] public float radius = 0.2f;
    [SerializeField] private ComputeShader computeShader;
    private RenderTexture texture;
    private Collider myCollider;
    private Collider[] colliders;
    private int resolution;
    private ComputeBuffer sphereBuffer;

    public struct Sphere
    {
        public Vector2 position;
        public float radius;
    }

    private void Awake()
    {
        myCollider = GetComponent<Collider>();
        // detect all colliders colliding with this plane (a plane with Collider) and add them to the list
        colliders = GetIntersectingColliders();


        resolution = (int)resolutionEnum;
        texture = CreateTempTexture(resolution);

        sphereBuffer = new ComputeBuffer(colliders.Length, sizeof(float) * 3);
        computeShader.SetInt("Resolution", resolution);
        computeShader.SetTexture(0, "Result", texture);


        // set texture to material
        GetComponent<Renderer>().material.SetTexture("_FlowMap", texture);

    }

    private void OnDisable()
    {
        texture.Release();
        texture = null;
        sphereBuffer.Release();
        sphereBuffer = null;
    }

    private Collider[] GetIntersectingColliders()
    {
        Bounds bounds = myCollider.bounds;
        Vector3 center = bounds.center;
        Vector3 extents = bounds.extents;
        Quaternion rotation = transform.rotation;
        Collider[] colliders = Physics.OverlapBox(center, extents, rotation);
        // remove this collider from the list
        Collider[] collidersWithoutThis = new Collider[colliders.Length - 1];
        int index = 0;
        foreach (Collider collider in colliders)
        {
            if (collider != myCollider)
            {
                collidersWithoutThis[index] = collider;
                index++;
            }
        }
        return collidersWithoutThis;
    }

    private void Update()
    {
        // // create array of spheres with positions and radii of colliding objects
        // Sphere[] spheres = new Sphere[colliders.Length];
        // for (int i = 0; i < colliders.Length; i++)
        // {
        //     Vector3 pos = colliders[i].transform.position - myCollider.bounds.min;
        //     pos = new Vector2(pos.x / myCollider.bounds.size.x * resolution, pos.z / myCollider.bounds.size.z * resolution);
        //     var flippedY = resolution - pos.y - 1;
        //     var flippedX = resolution - pos.x - 1;
        //     spheres[i].position = new Vector2(flippedX, flippedY);

        //     // calculate radius of sphere. radius value is in pixels and we need to convert it to world space
        //     var colliderSize = colliders[i].bounds.extents.x / myCollider.bounds.size.x * resolution;
        //     spheres[i].radius = colliderSize * radius;
        // }
        // computeShader.SetFloat("Radius", radius);
        // // create buffer with spheres
        // sphereBuffer.SetData(spheres);
        // computeShader.SetBuffer(0, "Spheres", sphereBuffer);
        computeShader.Dispatch(0, (int)resolutionEnum / 8, (int)resolutionEnum / 8, 1);
        // GetComponent<Renderer>().material.SetTexture("_FlowMap", texture);
    }

    private RenderTexture CreateTempTexture(int resolution)
    {
        var texture = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        texture.enableRandomWrite = true;
        texture.Create();
        return texture;
    }
}