using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(OpenFlowmapBehaviour))]
public class OpenFlowmapBehaviourEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("Bake Texture"))
        {
            if (target is OpenFlowmapBehaviour flowmap)
            {
                flowmap.BakeTexture();
            }
        }
    }
}
