using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

/// <summary>
/// 排查「NPC 台词不触发」：把 DouyinScript 的真实字段 / Lua 绑定 / 场景挂载状态全部 dump 出来。
/// 菜单：Tools/校园/诊断 Lua 绑定
/// 批处理：-executeMethod CampusLuaDiag.RunFromBatch
/// </summary>
public static class CampusLuaDiag
{
    const BindingFlags F = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;

    static readonly StringBuilder sb = new StringBuilder();

    static void L(string s = "") { sb.AppendLine(s); }

    static Type FindType(string name)
    {
        foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
        {
            Type[] types;
            try { types = asm.GetTypes(); } catch { continue; }
            foreach (var t in types)
                if (t.Name == name) return t;
        }
        return null;
    }

    [MenuItem("Tools/校园/诊断 Lua 绑定")]
    public static void Run()
    {
        sb.Clear();
        var scenePath = "Assets/Scenes/Campus.unity";
        var scene = EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Single);

        L("## 场景 " + scenePath);
        L("## 时间 " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
        L();

        // ---------------------------------------------------------- 1. 类型
        L("=== 1. DouyinScript 类型 ===");
        var tScript = FindType("DouyinScript");
        L("FindType(DouyinScript) = " + (tScript == null ? "NULL" : tScript.FullName + "  [" + tScript.Assembly.GetName().Name + "]"));
        if (tScript == null)
        {
            L("含 Douyin 的类型：");
            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            {
                Type[] types;
                try { types = asm.GetTypes(); } catch { continue; }
                foreach (var t in types)
                    if (t.Name.Contains("DouyinScript") || t.Name.Contains("LuaScript") || t.Name == "LuaBehaviour")
                        L("   " + t.FullName + "  [" + asm.GetName().Name + "]");
            }
        }
        L();

        if (tScript != null)
        {
            L("--- 字段（含私有）---");
            var fs = tScript.GetFields(F).OrderBy(x => x.Name).ToList();
            foreach (var f in fs)
                L(string.Format("  {0,-28} {1,-40} {2}", f.Name, f.FieldType.Name, f.IsPublic ? "public" : "nonpublic"));
            L("--- 方法（生命周期相关）---");
            foreach (var m in tScript.GetMethods(F).OrderBy(x => x.Name))
                if (m.Name.IndexOf("Update", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    m.Name.IndexOf("Awake", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    m.Name.IndexOf("Lua", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    m.Name.IndexOf("Script", StringComparison.OrdinalIgnoreCase) >= 0)
                    L("  " + m.ReturnType.Name + " " + m.Name + "(" +
                      string.Join(", ", m.GetParameters().Select(p => p.ParameterType.Name + " " + p.Name)) + ")");
            L();

            L("--- 基类链 ---");
            for (var t = tScript; t != null; t = t.BaseType)
                L("  " + t.FullName + "  [" + t.Assembly.GetName().Name + "]");
            L();
        }

        // 找 Lua 环境 / 派发器
        L("=== 2. Lua 运行环境相关类型 ===");
        foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
        {
            Type[] types;
            try { types = asm.GetTypes(); } catch { continue; }
            foreach (var t in types)
            {
                if (!t.IsClass) continue;
                var n = t.Name;
                if (n.Contains("LuaEnv") || n.Contains("LuaManager") || n.Contains("LuaRunner")
                    || n.Contains("DouyinScript") || n == "LuaTable" || n.Contains("Xlua") || n.Contains("XLua"))
                    L("  " + t.FullName + "  [" + asm.GetName().Name + "]");
            }
        }
        L();

        // ---------------------------------------------------------- 3. 场景内 NPC
        L("=== 3. 场景内 NPC / Star 的 Lua 绑定 ===");
        var all = UnityEngine.Object.FindObjectsOfType<Transform>(true);
        var targets = all.Where(x => x.name.StartsWith("NPC_") || x.name == "NPC" || x.name.StartsWith("NPC_Star")
                                     || x.name == "CampusStarHost").ToArray();

        if (tScript != null)
        {
            foreach (var tr in targets.OrderBy(x => x.name))
            {
                var comp = tr.GetComponent(tScript);
                L("--- " + tr.name + "  pos=" + tr.position.ToString("F2") +
                  "  activeInHierarchy=" + tr.gameObject.activeInHierarchy);
                if (comp == null) { L("    没有 DouyinScript 组件！"); continue; }

                var mb = comp as MonoBehaviour;
                L("    enabled=" + (mb != null ? mb.enabled.ToString() : "?"));

                foreach (var f in tScript.GetFields(F))
                {
                    object v;
                    try { v = f.GetValue(comp); } catch { v = "<err>"; }
                    string sv;
                    if (v == null) sv = "null";
                    else if (v is UnityEngine.Object uo) sv = uo == null ? "null(destroyed)" : (uo.name + " [" + uo.GetType().Name + "] " + AssetDatabase.GetAssetPath(uo));
                    else if (v is System.Collections.ICollection col) sv = "count=" + col.Count;
                    else sv = v.ToString();
                    if (f.Name == "ParaLuaBindingData" || f.Name == "ScriptAsset" || f.Name.IndexOf("Lua", StringComparison.OrdinalIgnoreCase) >= 0
                        || f.Name.IndexOf("Update", StringComparison.OrdinalIgnoreCase) >= 0
                        || f.Name.IndexOf("Manual", StringComparison.OrdinalIgnoreCase) >= 0
                        || f.Name.IndexOf("Script", StringComparison.OrdinalIgnoreCase) >= 0)
                        L("    " + f.Name + " = " + sv);
                }
            }
        }
        else
        {
            foreach (var tr in targets.OrderBy(x => x.name))
                L("  " + tr.name + " pos=" + tr.position.ToString("F2") + "  子物体=" + tr.childCount);
        }
        L();

        // ---------------------------------------------------------- 4. 关键子物体
        L("=== 4. NPC_01 子物体树（前 3 层）===");
        var npc1 = targets.FirstOrDefault(x => x.name == "NPC_01");
        if (npc1 == null) L("找不到 NPC_01");
        else DumpTree(npc1, 0, 3);
        L();

        L("=== 5. 台词 quad 状态（NPC_01）===");
        if (npc1 != null)
        {
            var bubble = npc1.Find("Label/Bubble");
            L("Label/Bubble = " + (bubble == null ? "NULL" : "childCount=" + bubble.childCount + " activeSelf=" + bubble.gameObject.activeSelf));
            var label = npc1.Find("Label");
            L("Label = " + (label == null ? "NULL" : "activeSelf=" + label.gameObject.activeSelf));
            if (bubble != null)
            {
                for (int i = 0; i < bubble.childCount; i++)
                {
                    var c = bubble.GetChild(i);
                    L("   " + c.name + " activeSelf=" + c.gameObject.activeSelf +
                      " localScale=" + c.localScale.ToString("F3"));
                }
            }
        }

        var path = System.IO.Path.Combine(System.IO.Directory.GetParent(Application.dataPath).FullName, "_lua_diag.txt");
        System.IO.File.WriteAllText(path, sb.ToString(), new UTF8Encoding(false));
        Debug.Log("[CampusLuaDiag] 写出 " + path + " (" + sb.Length + " 字符)");
    }

    static void DumpTree(Transform t, int depth, int maxDepth)
    {
        string pad = new string(' ', depth * 3);
        var comps = t.GetComponents<Component>().Where(c => c != null).Select(c => c.GetType().Name);
        L(pad + t.name + "  [" + string.Join(",", comps) + "]  activeSelf=" + t.gameObject.activeSelf);
        if (depth >= maxDepth) return;
        for (int i = 0; i < t.childCount; i++) DumpTree(t.GetChild(i), depth + 1, maxDepth);
    }

    public static void RunFromBatch()
    {
        try
        {
            Run();
            EditorApplication.Exit(0);
        }
        catch (Exception e)
        {
            Debug.LogError("[CampusLuaDiag] 失败: " + e);
            System.IO.File.WriteAllText(
                System.IO.Path.Combine(System.IO.Directory.GetParent(Application.dataPath).FullName, "_lua_diag.txt"),
                "EXCEPTION:\n" + e, new UTF8Encoding(false));
            EditorApplication.Exit(1);
        }
    }
}
