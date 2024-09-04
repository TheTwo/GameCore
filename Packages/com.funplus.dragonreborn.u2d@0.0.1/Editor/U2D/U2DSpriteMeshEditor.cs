using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(U2DSpriteMesh), true)]
public class U2DSpriteMeshEditor : Editor
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
        var spriteMesh = target as U2DSpriteMesh;
        if (!spriteMesh)
        {
            return;
        }
        
        spriteMesh.SetDirty();

        EditorUtility.SetDirty(spriteMesh);
    }

    public override void OnInspectorGUI()
	{
		var spriteMesh = target as U2DSpriteMesh;
        if (!spriteMesh)
        {
            return;
        }
        
        EditorGUI.BeginChangeCheck();
		EditorGUILayout.BeginVertical();
		
		var sprite = EditorGUILayout.ObjectField("Sprite", spriteMesh.sprite, typeof(Sprite), true) as Sprite;
        if (sprite != spriteMesh.sprite)
        {
            Undo.RecordObject(spriteMesh, "Set Sprite");
            spriteMesh.sprite = sprite;
        }
        
        if(sprite == null)
        {
	        EditorGUILayout.HelpBox("A sprite must be assigned.", MessageType.Warning);
        }
        else
        {
	        var material = EditorGUILayout.ObjectField("Material", spriteMesh.material, typeof(Material), true) as Material;
	        if (material == null)
	        {
		        material = U2DUtils.FindAsset<Material>("U2D_Sprite_Default", "Material");
	        }

	        if (material != spriteMesh.material)
	        {
		        Undo.RecordObject(spriteMesh, "Set Material");
		        spriteMesh.material = material;
	        }

	        var color = EditorGUILayout.ColorField("Color", spriteMesh.color);
	        if (color != spriteMesh.color)
	        {
		        Undo.RecordObject(spriteMesh, "Set Color");
		        spriteMesh.color = color;
	        }

	        var fillType = (U2DSpriteMesh.FillType)EditorGUILayout.EnumPopup("Fill Type", spriteMesh.fillType);
	        if (fillType != spriteMesh.fillType)
	        {
		        Undo.RecordObject(spriteMesh, "Set Fill Type");
		        spriteMesh.fillType = fillType;
	        }

	        var width = EditorGUILayout.FloatField("Width", spriteMesh.width);
	        if (width != spriteMesh.width)
	        {
		        Undo.RecordObject(spriteMesh, "Set Width");
		        spriteMesh.width = width;
	        }

	        var height = EditorGUILayout.FloatField("Height", spriteMesh.height);
	        if (height != spriteMesh.height)
	        {
		        Undo.RecordObject(spriteMesh, "Set Height");
		        spriteMesh.height = height;
	        }

	        var pivot = EditorGUILayout.Vector2Field("Pivot", spriteMesh.pivot);
	        if (pivot != spriteMesh.pivot)
	        {
		        Undo.RecordObject(spriteMesh, "Set Pivot");
		        spriteMesh.pivot = pivot;
	        }

	        var pixelSize = EditorGUILayout.FloatField("Pixel Size", spriteMesh.pixelSize);
	        if (pixelSize != spriteMesh.pixelSize)
	        {
		        Undo.RecordObject(spriteMesh, "Set Pixel Size");
		        spriteMesh.pixelSize = pixelSize;
	        }

	        var aspectRatio = (U2DSpriteMesh.AspectRatioSource)EditorGUILayout.EnumPopup("Preserve Aspect", spriteMesh.aspectRatio);
	        if (aspectRatio != spriteMesh.aspectRatio)
	        {
		        Undo.RecordObject(spriteMesh, "Set Preserve Aspect");
		        spriteMesh.aspectRatio = aspectRatio;
	        }

	        if (spriteMesh.fillType == U2DSpriteMesh.FillType.Simple)
	        {
		        var fillAmount = EditorGUILayout.Slider("Fill Amount", spriteMesh.fillAmount, 0, 1);
		        if (fillAmount != spriteMesh.fillAmount)
		        {
			        Undo.RecordObject(spriteMesh, "Set Fill Amount");
			        spriteMesh.fillAmount = fillAmount;
		        }
	        }

	        if (spriteMesh.fillType == U2DSpriteMesh.FillType.Radial)
	        {
		        var fillAmount = EditorGUILayout.Slider("Fill Amount", spriteMesh.fillAmount, 0.0f, 1.0f);
		        if (fillAmount != spriteMesh.fillAmount)
		        {
			        Undo.RecordObject(spriteMesh, "Set Fill Amount");
			        spriteMesh.fillAmount = fillAmount;
		        }

		        var clockwise = EditorGUILayout.Toggle("Clockwise", spriteMesh.clockwise);
		        if (clockwise != spriteMesh.clockwise)
		        {
			        Undo.RecordObject(spriteMesh, "Set Clockwise");
			        spriteMesh.clockwise = clockwise;
		        }
	        }

	        if (spriteMesh.fillType == U2DSpriteMesh.FillType.Sliced)
	        {
		        var degenerate = EditorGUILayout.Toggle("Degenerate", spriteMesh.degenerate);
		        if (degenerate != spriteMesh.degenerate)
		        {
			        Undo.RecordObject(spriteMesh, "Degenerate");
			        spriteMesh.degenerate = degenerate;
		        }
	        }

	        var maskType = (U2DSpriteMesh.MaskType)EditorGUILayout.EnumPopup("Mask Type", spriteMesh.maskType);
	        if (maskType != spriteMesh.maskType)
	        {
		        Undo.RecordObject(spriteMesh, "Set Mask Type");
		        spriteMesh.maskType = maskType;
	        }

	        switch (maskType)
	        {
		        case U2DSpriteMesh.MaskType.Rect:
		        {
			        var maskMin = EditorGUILayout.Vector2Field("Min", spriteMesh.maskParam1);
			        if (maskMin != spriteMesh.maskParam1)
			        {
				        Undo.RecordObject(spriteMesh, "Set Mask Param1");
				        spriteMesh.maskParam1 = maskMin;
			        }

			        var maskMax = EditorGUILayout.Vector2Field("Max", spriteMesh.maskParam2);
			        if (maskMax != spriteMesh.maskParam2)
			        {
				        Undo.RecordObject(spriteMesh, "Set Mask Param2");
				        spriteMesh.maskParam2 = maskMax;
			        }

			        break;
		        }

		        case U2DSpriteMesh.MaskType.Circle:
		        {
			        var maskCenter = EditorGUILayout.Vector2Field("Center", spriteMesh.maskParam1);
			        if (maskCenter != spriteMesh.maskParam1)
			        {
				        Undo.RecordObject(spriteMesh, "Set Mask Center");
				        spriteMesh.maskParam1 = maskCenter;
			        }

			        var maskRadius = EditorGUILayout.FloatField("Radius", spriteMesh.maskParam2.x);
			        if (maskRadius != spriteMesh.maskParam2.x)
			        {
				        Undo.RecordObject(spriteMesh, "Set Mask Radius");
				        spriteMesh.maskParam2 = new Vector2(maskRadius, 0f);
			        }

			        break;
		        }
	        }
        }

        EditorGUILayout.EndVertical();

		if (EditorGUI.EndChangeCheck())
		{
			EditorUtility.SetDirty(spriteMesh);
		}
    }
}
