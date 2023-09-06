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

        // flowmapObject.AddComponent<OuterFlow>();
        // flowmapObject.AddComponent<GlobalFlowDirection>();


        // Add the OpenFlowmap component to the GameObject
        var _flowmapBehaviour = flowmapObject.AddComponent<OpenFlowmapBehaviour>();
        _flowmapBehaviour.Process();


        // Set the new GameObject as the active selection in the Editor
        Selection.activeGameObject = flowmapObject;
    }
}
