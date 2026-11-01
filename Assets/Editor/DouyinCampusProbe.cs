using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 探测 SDK 组件的序列化字段，输出到工程根的 _probe.txt。
/// 只读，不修改工程内容。
/// </summary>
public static class DouyinCampusProbe
{
    const string Out = "D:/DouyinWorld2021/_probe.txt";

    [MenuItem("抖音虚拟创作SDK/校园：探测组件字段")]
    public static void Probe()
    {
        var sb = new StringBuilder();
        sb.AppendLine("# DouyinWorld2021 组件字段探测");
        sb.AppendLine("time=" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
        sb.AppendLine();

        List<Type> comps;
        try
        {
            comps = AppDomain.CurrentDomain.GetAssemblies()
                .SelectMany(SafeTypes)
                .Where(t => typeof(Component).IsAssignableFrom(t) && !t.IsAbstract)
                .Where(t => t.Namespace != null || t.Name.StartsWith("Douyin"))
                .Where(t => t.Name.StartsWith("Douyin") || t.Name.Contains("WorldRoot") || t.Name.Contains("Environment"))
                .OrderBy(t => t.FullName)
                .ToList();
        }
        catch (Exception e)
        {
            File.WriteAllText(Out, "枚举类型失败: " + e);
            return;
        }

        sb.AppendLine("## 组件类型清单 (" + comps.Count + ")");
        foreach (var t in comps) sb.AppendLine("  " + t.FullName + "  [asm=" + t.Assembly.GetName().Name + "]");
        sb.AppendLine();

        foreach (var t in comps)
        {
            var fields = t.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)
                .Where(f => f.IsPublic || f.GetCustomAttribute<SerializeField>() != null)
                .ToList();
            if (fields.Count == 0) continue;

            sb.AppendLine("## " + t.Name + "   (fields=" + fields.Count + ")");
            foreach (var f in fields)
            {
                var vis = f.IsPublic ? "public" : "[SerializeField]";
                var hide = f.GetCustomAttribute<HideInInspector>() != null ? " [HideInInspector]" : "";
                var range = f.GetCustomAttribute<RangeAttribute>() != null
                    ? " range(" + f.GetCustomAttribute<RangeAttribute>().min + ".." + f.GetCustomAttribute<RangeAttribute>().max + ")"
                    : "";
                var tooltip = f.GetCustomAttribute<TooltipAttribute>() != null
                    ? " // " + f.GetCustomAttribute<TooltipAttribute>().tooltip
                    : "";
                sb.AppendLine("   " + vis + " " + Pretty(f.FieldType) + " " + f.Name + hide + range + tooltip);
            }
            sb.AppendLine();
        }

        sb.AppendLine("## 场景环境示例资源");
        foreach (var g in AssetDatabase.FindAssets("t:Object", new[] { "Assets/DouyinVCreateSDK/World/Examples/DouyinSceneEnvironment" }))
        {
            var p = AssetDatabase.GUIDToAssetPath(g);
            var o = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(p);
            sb.AppendLine("   " + p + "  ->  " + (o == null ? "null" : o.GetType().Name));
        }
        sb.AppendLine();

        sb.AppendLine("## 当前场景对象与组件");
        for (int i = 0; i < UnityEngine.SceneManagement.SceneManager.sceneCount; i++)
        {
            var sc = UnityEngine.SceneManagement.SceneManager.GetSceneAt(i);
            sb.AppendLine("   scene=" + sc.name + " path=" + sc.path + " loaded=" + sc.isLoaded);
            foreach (var go in sc.GetRootGameObjects())
                foreach (var c in go.GetComponentsInChildren<Component>(true))
                    sb.AppendLine("      " + Path(go.transform) + " :: " + (c == null ? "<missing>" : c.GetType().Name));
        }

        File.WriteAllText(Out, sb.ToString(), new UTF8Encoding(false));
        Debug.Log("[PROBE] written " + Out);
    }

    static IEnumerable<Type> SafeTypes(Assembly a)
    {
        try { return a.GetTypes(); }
        catch (ReflectionTypeLoadException e) { return e.Types.Where(t => t != null); }
        catch { return Array.Empty<Type>(); }
    }

    static string Pretty(Type t)
    {
        if (t.IsGenericType)
            return t.Name.Split('`')[0] + "<" + string.Join(",", t.GetGenericArguments().Select(Pretty)) + ">";
        return t.Name;
    }

    static string Path(Transform t)
    {
        var s = t.name;
        while (t.parent != null) { t = t.parent; s = t.name + "/" + s; }
        return s;
    }
}
