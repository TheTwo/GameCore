using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(U2DTextMesh), true)]
public class U2DTextMeshEditor : Editor
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
		var textMesh = target as U2DTextMesh;
		if (!textMesh)
		{
			return;
		}

		textMesh.SetDirty();

		EditorUtility.SetDirty(textMesh);
	}

	public override void OnInspectorGUI()
	{
		var textMesh = target as U2DTextMesh;
		if (!textMesh)
		{
			return;
		}

		EditorGUI.BeginChangeCheck();
		var font = (Font)EditorGUILayout.ObjectField("Font", textMesh.font, typeof(Font), true);
		if (font != textMesh.font)
		{
			Undo.RecordObject(textMesh, "Set Font");
			textMesh.font = font;
		}

		if (font == null)
		{
			EditorGUILayout.HelpBox("A font must be assigned.", MessageType.Warning);
			return;
		}

		var fontStyle = (FontStyle)EditorGUILayout.EnumPopup("Font Style", textMesh.fontStyle);
		if (fontStyle != textMesh.fontStyle)
		{
			Undo.RecordObject(textMesh, "Set Font Style");
			textMesh.fontStyle = fontStyle;
		}

		var fontSize = EditorGUILayout.IntField("Font Size", textMesh.fontSize);
		if (fontSize != textMesh.fontSize)
		{
			Undo.RecordObject(textMesh, "Set Font Size");
			textMesh.fontSize = fontSize;
		}

		var fontScale = EditorGUILayout.FloatField("Font Scale", textMesh.fontScale);
		if (fontScale != textMesh.fontScale)
		{
			Undo.RecordObject(textMesh, "Set Font Scale");
			textMesh.fontScale = fontScale;
		}

		var lineSpacing = EditorGUILayout.FloatField("Line Spacing", textMesh.lineSpacing);
		if (lineSpacing != textMesh.lineSpacing)
		{
			Undo.RecordObject(textMesh, "Set Line Spacing");
			textMesh.lineSpacing = lineSpacing;
		}

		var anchor = (TextAnchor)EditorGUILayout.EnumPopup("Anchor", textMesh.anchor);
		if (anchor != textMesh.anchor)
		{
			Undo.RecordObject(textMesh, "Set Anchor");
			textMesh.anchor = anchor;
		}

		var horizontalWrapMode = (HorizontalWrapMode)EditorGUILayout.EnumPopup("Horizontal Wrap Mode", textMesh.horizontalWrapMode);
		if (horizontalWrapMode != textMesh.horizontalWrapMode)
		{
			Undo.RecordObject(textMesh, "Set Horizontal Wrap Mode");
			textMesh.horizontalWrapMode = horizontalWrapMode;
		}

		var verticalWrapMode = (VerticalWrapMode)EditorGUILayout.EnumPopup("Vertical Wrap Mode", textMesh.verticalWrapMode);
		if (verticalWrapMode != textMesh.verticalWrapMode)
		{
			Undo.RecordObject(textMesh, "Set Vertical Wrap Mode");
			textMesh.verticalWrapMode = verticalWrapMode;
		}

		var richText = EditorGUILayout.Toggle("Rich Text", textMesh.richText);
		if (richText != textMesh.richText)
		{
			Undo.RecordObject(textMesh, "Set Rich Text");
			textMesh.richText = richText;
		}

		EditorGUILayout.LabelField("Text");
		var text = EditorGUILayout.TextArea(textMesh.text);
		if (text != textMesh.text)
		{
			Undo.RecordObject(textMesh, "Set Text");
			textMesh.text = text;
		}

		var material = EditorGUILayout.ObjectField("Material", textMesh.material, typeof(Material), true) as Material;
		if (material == null)
		{
			material = U2DUtils.FindAsset<Material>("U2D_Text_Default", "Material");
		}
		
		if (material != textMesh.material)
		{
			Undo.RecordObject(textMesh, "Set Material");
			textMesh.material = material;
		}

		var color = EditorGUILayout.ColorField("Color", textMesh.color);
		if (color != textMesh.color)
		{
			Undo.RecordObject(textMesh, "Set Color");
			textMesh.color = color;
		}

		var width = EditorGUILayout.FloatField("Width", textMesh.width);
		if (width != textMesh.width)
		{
			Undo.RecordObject(textMesh, "Set Width");
			textMesh.width = width;
		}

		var maxWidth = EditorGUILayout.FloatField("Max Width", textMesh.maxWidth);
		if (maxWidth != textMesh.maxWidth)
		{
			Undo.RecordObject(textMesh, "Set Max Width");
			textMesh.maxWidth = maxWidth;
		}

		var height = EditorGUILayout.FloatField("Height", textMesh.height);
		if (height != textMesh.height)
		{
			Undo.RecordObject(textMesh, "Set Height");
			textMesh.height = height;
		}

		var maxHeight = EditorGUILayout.FloatField("Max Height", textMesh.maxHeight);
		if (maxHeight != textMesh.maxHeight)
		{
			Undo.RecordObject(textMesh, "Set Max Height");
			textMesh.maxHeight = maxHeight;
		}

		var pivot = EditorGUILayout.Vector2Field("Pivot", textMesh.pivot);
		if (pivot != textMesh.pivot)
		{
			Undo.RecordObject(textMesh, "Set Pivot");
			textMesh.pivot = pivot;
		}

		var pixelSize = EditorGUILayout.FloatField("Pixel Size", textMesh.pixelSize);
		if (pixelSize != textMesh.pixelSize)
		{
			Undo.RecordObject(textMesh, "Set Pixel Size");
			textMesh.pixelSize = pixelSize;
		}

		var effect = (U2DTextMesh.Effect)EditorGUILayout.EnumPopup("Effect", textMesh.effect);
		if (effect != textMesh.effect)
		{
			Undo.RecordObject(textMesh, "Set Effect");
			textMesh.effect = effect;
		}

		if (textMesh.effect == U2DTextMesh.Effect.Outline)
		{
			var outlineSize = EditorGUILayout.FloatField("Outline Size", textMesh.outlineSize);
			if (outlineSize != textMesh.outlineSize)
			{
				Undo.RecordObject(textMesh, "Set Outline Size");
				textMesh.outlineSize = outlineSize;
			}

			var outlineColor = EditorGUILayout.ColorField("Outline Color", textMesh.outlineColor);
			if (outlineColor != textMesh.outlineColor)
			{
				Undo.RecordObject(textMesh, "Set Outline Color");
				textMesh.outlineColor = outlineColor;
			}
		}
		else if (textMesh.effect == U2DTextMesh.Effect.Shadow)
		{
			var shadowOffset = EditorGUILayout.Vector2Field("Shadow Offset", textMesh.shadowOffset);
			if (shadowOffset != textMesh.shadowOffset)
			{
				Undo.RecordObject(textMesh, "Set Shadow Offset");
				textMesh.shadowOffset = shadowOffset;
			}

			var shadowColor = EditorGUILayout.ColorField("Shadow Color", textMesh.shadowColor);
			if (shadowColor != textMesh.shadowColor)
			{
				Undo.RecordObject(textMesh, "Set Shadow Color");
				textMesh.shadowColor = shadowColor;
			}
		}

		var useColorGradient = EditorGUILayout.Toggle("Use Gradient", textMesh.UseGradient);
		if(useColorGradient != textMesh.UseGradient)
		{
			Undo.RecordObject(textMesh, "Set Use Gradient");
			textMesh.UseGradient = useColorGradient;
		}
		if (useColorGradient)
		{			
			var colorGradient1 = EditorGUILayout.ColorField("Color Gradient 1", textMesh.GradientColor1);
			if (colorGradient1 != textMesh.GradientColor1)
			{
				Undo.RecordObject(textMesh, "Set Color Gradient 1");
				textMesh.GradientColor1 = colorGradient1;
			}

			var colorGradient2 = EditorGUILayout.ColorField("Color Gradient 2", textMesh.GradientColor2);
			if (colorGradient2 != textMesh.GradientColor2)
			{
				Undo.RecordObject(textMesh, "Set Color Gradient 2");
				textMesh.GradientColor2 = colorGradient2;
			}

			var gradientVertical = EditorGUILayout.Toggle("Is Gradient Vertical", textMesh.IsGradientVertical);
			if( gradientVertical != textMesh.IsGradientVertical)
			{
				Undo.RecordObject(textMesh, "Set Is Gradient Vertical");
				textMesh.IsGradientVertical = gradientVertical;
			}

			var gradientMultiply = EditorGUILayout.Toggle("Is Gradient Multiply Text Color", textMesh.IsGradientMultiplyTextColor);
			if( gradientMultiply != textMesh.IsGradientMultiplyTextColor)
			{
				Undo.RecordObject(textMesh, "Set Is Gradient Multiply Text Color");
				textMesh.IsGradientMultiplyTextColor = gradientMultiply;
			}
		}
		
		if (EditorGUI.EndChangeCheck())
		{
			EditorUtility.SetDirty(textMesh);
		}
	}
}
