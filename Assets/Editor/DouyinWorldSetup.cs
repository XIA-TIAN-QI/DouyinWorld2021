using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>
/// 生成一个最小可跑的抖音世界场景：示例场景 + DouyinWorldRoot + 地面。
/// 可用菜单 抖音虚拟创作SDK/生成示例世界场景 手动执行，
/// 也可命令行：-executeMethod DouyinWorldSetup.BuildScene
/// </summary>
public static class DouyinWorldSetup
{
    const string PrefabPath = "Assets/DouyinVCreateSDK/World/Examples/DouyinWorldRoot/DouyinWorldRoot.prefab";
    const string SrcScene   = "Assets/Scenes/SampleScene.unity";
    const string OutScene   = "Assets/Scenes/DouyinWorld.unity";
    const string MatPath    = "Assets/Scenes/Ground_URP.mat";

    [MenuItem("抖音虚拟创作SDK/生成示例世界场景")]
    public static void BuildScene()
    {
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(PrefabPath);
        if (prefab == null)
        {
            Debug.LogError("[DouyinWorldSetup] 预制体未找到: " + PrefabPath);
            return;
        }

        var scene = EditorSceneManager.OpenScene(SrcScene, OpenSceneMode.Single);

        foreach (var root in scene.GetRootGameObjects())
        {
            if (root.name == "DouyinWorldRoot")
            {
                Object.DestroyImmediate(root);
                break;
            }
        }

        var inst = (GameObject)PrefabUtility.InstantiatePrefab(prefab);
        inst.name = "DouyinWorldRoot";
        inst.transform.SetPositionAndRotation(Vector3.zero, Quaternion.identity);

        if (GameObject.Find("Ground") == null)
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>(MatPath);
            if (mat == null)
            {
                var lit = Shader.Find("Universal Render Pipeline/Lit");
                if (lit == null)
                {
                    Debug.LogError("[DouyinWorldSetup] 找不到 URP/Lit 着色器，URP 管线可能未挂上");
                    return;
                }
                mat = new Material(lit) { name = "Ground_URP" };
                AssetDatabase.CreateAsset(mat, MatPath);
            }

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Ground";
            ground.transform.localScale = new Vector3(5f, 1f, 5f); // 50m x 50m
            ground.transform.position = Vector3.zero;
            ground.GetComponent<Renderer>().sharedMaterial = mat;
        }

        EditorSceneManager.MarkSceneDirty(scene);
        bool ok = EditorSceneManager.SaveScene(scene, OutScene);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(OutScene, true) };
        AssetDatabase.SaveAssets();
        Debug.Log("[DouyinWorldSetup] scene saved=" + ok + " path=" + OutScene);
    }

    public static void VerifyScene()
    {
        var sb = new System.Text.StringBuilder();
        var scene = EditorSceneManager.OpenScene(OutScene, OpenSceneMode.Single);
        var root = GameObject.Find("DouyinWorldRoot");
        sb.AppendLine("scene=" + scene.name + " roots=" + scene.rootCount + " worldRoot=" + (root != null));

        if (root != null)
        {
            var names = "";
            foreach (var c in root.GetComponents<Component>())
                names += (c == null ? "<missing>" : c.GetType().Name) + ",";
            sb.AppendLine("components=" + names);
            sb.AppendLine("isPrefabInstance=" + PrefabUtility.IsPartOfPrefabInstance(root));
        }

        var rp = UnityEngine.Rendering.GraphicsSettings.currentRenderPipeline;
        sb.AppendLine("renderPipeline=" + (rp == null ? "null(Built-in)" : rp.GetType().Name + " / " + rp.name));

        var missing = "";
        foreach (var go in scene.GetRootGameObjects())
            foreach (var c in go.GetComponentsInChildren<Component>(true))
                if (c == null) missing += go.name + ";";
        sb.AppendLine("missingScripts=" + (missing == "" ? "none" : missing));

        System.IO.File.WriteAllText("Assets/../_verify.txt", sb.ToString());
    }
}
