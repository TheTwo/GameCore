using UnityEditor;

[CustomEditor(typeof(U2DSlider))]
public class U2DSliderEditor : Editor
{
    private void OnEnable()
    {
        Undo.undoRedoPerformed = OnUndoRedoPerformed;
    }

    private void OnDisable()
    {
        Undo.undoRedoPerformed = null;
    }

    private void OnUndoRedoPerformed()
    {
        var slider = target as U2DSlider;
        if (!slider)
        {
            return;
        }

        EditorUtility.SetDirty(slider);
    }

	public override void OnInspectorGUI ()
	{
		var slider = target as U2DSlider;
        if (!slider)
        {
            return;
        }

        EditorGUI.BeginChangeCheck();
        var spriteMesh = EditorGUILayout.ObjectField("Sprite Mesh", slider.spriteMesh, typeof(U2DSpriteMesh), true) as U2DSpriteMesh;
        if (spriteMesh != slider.spriteMesh)
        {
            Undo.RecordObject(spriteMesh, "Set Sprite Mesh");
            slider.spriteMesh = spriteMesh;
        }
        
		var progress = EditorGUILayout.Slider ("Progress", slider.progress, 0, 1);
        if (progress != slider.progress)
        {
            Undo.RecordObject(spriteMesh, "Set Progress");
            slider.progress = progress;
        }

        if (EditorGUI.EndChangeCheck())
        {
	        EditorUtility.SetDirty(slider);
        }
	}
}
