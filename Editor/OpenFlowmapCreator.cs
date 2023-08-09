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

        var _collider = flowmapObject.AddComponent<BoxCollider>();

        // Add the OpenFlowmap component to the GameObject
        var _flowmap = flowmapObject.AddComponent<OpenFlowmap>();
        _flowmap.resolutionEnum = OpenFlowmap.Resolution._128x128;
        _flowmap.layerMask = LayerMask.GetMask("Water");
        _flowmap.InitializeFlowmapPoints();

        // Set the new GameObject as the active selection in the Editor
        Selection.activeGameObject = flowmapObject;
    }
}
