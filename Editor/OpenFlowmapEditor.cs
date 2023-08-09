using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(OpenFlowmap))]
public class OpenFlowmapEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        OpenFlowmap openFlowmap = (OpenFlowmap)target;
        if (GUILayout.Button("Bake Flowmap"))
        {
            openFlowmap.BakeFlowmapTexture();
        }
    }
}
