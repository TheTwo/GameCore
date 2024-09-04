using System.Collections.Generic;
using UnityEngine;

// 这个类用来优化Font.textureRebuilt的注册和反注册导致的GC问题
public static class U2DFontUpdateTracker
{
    static Dictionary<Font, HashSet<U2DTextMesh>> m_Tracked = new();

    public static void TrackText(U2DTextMesh t)
    {
        if (t.font == null)
            return;

        m_Tracked.TryGetValue(t.font, out var exists);
        if (exists == null)
        {
            // The textureRebuilt event is global for all fonts, so we add our delegate the first time we register *any* U2DTextMesh
            if (m_Tracked.Count == 0)
                Font.textureRebuilt += RebuildForFont;

            exists = new HashSet<U2DTextMesh>();
            m_Tracked.Add(t.font, exists);
        }

        exists.Add(t);
    }

    private static void RebuildForFont(Font f)
    {
	    m_Tracked.TryGetValue(f, out var texts);

        if (texts == null)
            return;

        foreach (var text in texts)
            text.FontTextureChanged();
    }

    public static void UntrackText(U2DTextMesh t)
    {
        if (t.font == null)
            return;

        m_Tracked.TryGetValue(t.font, out var texts);

        if (texts == null)
            return;

        texts.Remove(t);

        if (texts.Count == 0)
        {
            m_Tracked.Remove(t.font);

            // There is a global textureRebuilt event for all fonts, so once the last U2DTextMesh reference goes away, remove our delegate
            if (m_Tracked.Count == 0)
                Font.textureRebuilt -= RebuildForFont;
        }
    }

    public static void ClearTracks()
    {
	    m_Tracked.Clear();
	    Font.textureRebuilt -= RebuildForFont;
    }
}