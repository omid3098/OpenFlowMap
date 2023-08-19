using UnityEngine;
using UnityEditor;

public class OpenFlowmapCreator
{
    [MenuItem("GameObject/OpenFlowmap", false, 10)]
    private static void CreateOpenFlowmapGameObject()
    {
        // Create a new GameObject
        GameObject flowmapObject = new GameObject("Flowmap_Plane");

        var _meshRenderer = flowmapObject.AddComponent<MeshRenderer>();
        var _meshFilter = flowmapObject.AddComponent<MeshFilter>();

        // assing a plane mesh to the mesh filter
        _meshFilter.sharedMesh = Resources.GetBuiltinResource<Mesh>("New-Plane.fbx");

        // Create a new material
        var _material = new Material(Shader.Find("OpenFlowmap/UnlitFlowmap"));
        _meshRenderer.sharedMaterial = _material;

        var _collider = flowmapObject.AddComponent<BoxCollider>();

        flowmapObject.AddComponent<OuterFlow>();


        // Add the OpenFlowmap component to the GameObject
        var _flowmap = flowmapObject.AddComponent<OpenFlowmap>();
        _flowmap.m_textureResolution = OpenFlowmap.Resolution._128x128;
        _flowmap.LayerMask = LayerMask.GetMask("Water");
        _flowmap.Initialize();


        // Set the new GameObject as the active selection in the Editor
        Selection.activeGameObject = flowmapObject;
    }
}
