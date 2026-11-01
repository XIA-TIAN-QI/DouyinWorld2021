using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// 抖音虚拟世界 · 微缩校园（Dusk 黄昏）程序化搭建。
/// 设计约束（来自 SDK 2.21.0 与官方资源规范）：
///  - 单场景，全工程仅一个 DouyinWorldRoot
///  - 材质走 SDK 自带 World_Lit（URP/自研 shader 会占 shader 预算且光照表现不一致）
///  - 不依赖实时点光（URP-Balanced 附加光为 PerVertex）、不依赖烘焙 lightmap（上限 4 张）
///  - 阴影距离仅 8m，立体感靠贴图内 AO / 自发光 / 材质对比
///  - 尺度按"微缩"处理：广场 + 一栋教学楼 + 操场，整体控制在 90m 视距内
/// </summary>
public static class DouyinCampusBuilder
{
    const string ScenePath = "Assets/Scenes/Campus.unity";
    const string MatDir = "Assets/Campus/Materials";
    const string TexDir = "Assets/Campus/Textures";
    const string MeshDir = "Assets/Campus/Meshes";
    const string ReportPath = "D:/DouyinWorld2021/_campus_report.txt";
    const string WorldRootPrefab = "Assets/DouyinVCreateSDK/World/Examples/DouyinWorldRoot/DouyinWorldRoot.prefab";
    // 夕阳：自己生成的天光（贴图 + 材质 + 环境配置，见 _tools/make_sunset_sky.py / wire_sunset_sky.py）
    const string DuskProfile = "Assets/Campus/Environment/DouyinSceneEnvProfile_Sunset01.pbjson";
    const string DuskSkybox = "Assets/Campus/Environment/Skybox_CampusSunset_mat.mat";
    const string WorldLitShader = "Douyin/World/ENV/World_Lit";
    const string GlowShader = "Douyin/World/VFX/VFX_Add01";   // 加法混合，路灯光晕/光池用

    // 材质调色板：合并同色系后压到 13 个（材质上限约 20，SDK 示例预制体自带 4 个）
    static readonly Dictionary<string, Color> Palette = new Dictionary<string, Color>
    {
        { "M_Paving_A",  new Color(0.60f, 0.56f, 0.48f) }, // 广场主铺装
        { "M_Lawn",      new Color(0.19f, 0.29f, 0.16f) }, // 草地
        { "M_Wall",      new Color(0.78f, 0.74f, 0.66f) }, // 教学楼墙体
        { "M_Brick",     new Color(0.48f, 0.25f, 0.19f) }, // 砖红装饰带
        { "M_Concrete",  new Color(0.40f, 0.40f, 0.41f) }, // 混凝土/道路
        { "M_Glass",     new Color(0.14f, 0.20f, 0.26f) }, // 窗玻璃
        { "M_Metal",     new Color(0.22f, 0.23f, 0.25f) }, // 金属杆件
        { "M_Emissive",  new Color(0.95f, 0.72f, 0.42f) }, // 自发光：窗内灯
        // 原 M_Lamp（更亮的路灯自发光）已并入 M_Emissive —— 去掉广场 6 个玻璃灯球后
        // 它只剩操场 4 盏高杆灯在用。材质额度 20/20，这一格让给路灯氛围光 M_Glow。
        { "M_Interior",  new Color(0.87f, 0.84f, 0.77f) }, // 室内墙面/天花（比外墙更亮，补足室内环境光偏弱）
        { "M_Wood",      new Color(0.46f, 0.33f, 0.20f) }, // 木质：课桌/讲台/门框/踢脚
        { "M_Window",    new Color(0.92f, 0.68f, 0.44f) }, // 室内侧窗玻璃：黄昏透光，带自发光
        { "M_Collect",   new Color(0.20f, 0.66f, 0.72f) }, // 收集品/收集进度（青绿，与暖色校园拉开）
        { "M_Poster",    new Color(1.00f, 1.00f, 1.00f) }, // 海报（贴图自带颜色，BaseColor 取白）
        { "M_Sakura",    new Color(0.94f, 0.62f, 0.68f) }, // 樱花树冠（粉）
        { "M_SignText",  new Color(1.00f, 1.00f, 1.00f) }, // 校名牌（贴图自带颜色）
        { "M_NpcLine",   new Color(1.00f, 1.00f, 1.00f) }, // NPC 名字/台词图集（贴图自带颜色）
        { "M_StarPink",  new Color(0.96f, 0.29f, 0.50f) }, // 黄思诚：亮玫粉（短上衣 / 挑染 / 鞋边）
        { "M_Denim",     new Color(0.33f, 0.42f, 0.58f) }, // 黄思诚：水洗牛仔蓝（阔腿裤 / 腰包）
    };

    static Dictionary<string, Material> _mats = new Dictionary<string, Material>();
    static Dictionary<string, Mesh> _meshes = new Dictionary<string, Mesh>();

    [MenuItem("抖音虚拟创作SDK/校园：搭建微缩校园（Dusk）")]
    public static void BuildFromMenu()
    {
        Build();
        EditorUtility.DisplayDialog("校园搭建", "微缩校园已生成并保存。\n详见工程根 _campus_report.txt", "好");
    }

    /// <summary>
    /// 只重刷贴图与材质，不重建场景。.mat 是共享资产，改完场景里的 Renderer 立即生效，
    /// 调法线强度时用这个比跑一次完整 Build 快得多。
    /// </summary>
    [MenuItem("抖音虚拟创作SDK/校园：刷新材质（法线/粗糙度/AO）")]
    public static void RefreshMaterials()
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();
        CreatePackedNormalTextures();
        CreateGlowTexture();
        CreateMaterials();
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log("[Campus] 材质已刷新（法线/粗糙度/AO），用时 " + sw.ElapsedMilliseconds + " ms");
    }

    /// <summary>批处理用：刷材质后立刻出图，省一次编辑器启动</summary>
    public static void RefreshMaterialsAndCapture()
    {
        RefreshMaterials();
        CaptureAll();
    }

    public static void Build()
    {
        EnsureFolders();
        CreateWhiteTexture();
        CreateDetailTextures();     // 程序化细节贴图（与材质解耦，见着色器约定）
        CreatePackedNormalTextures(); // 法线XY+光滑度+AO 打包图（见 ApplyPackedNormal 注释）
        EnsureNpcLinesTexture();    // NPC 台词图集（Python 生成，见 _tools/make_npc_lines.py）
        CreateGlowTexture();        // 路灯加法光晕/光池用的径向渐变图
        CreateMaterials();

        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var campus = new GameObject("Campus").transform;
        var ground = new GameObject("Ground").transform;
        var plaza = new GameObject("Plaza").transform;
        var building = new GameObject("TeachingBuilding").transform;
        var field = new GameObject("Playground").transform;
        var gate = new GameObject("MainGate").transform;
        var props = new GameObject("Props").transform;
        var collect = new GameObject("Collectibles").transform;
        var npc = new GameObject("NPCs").transform;
        foreach (var t in new[] { ground, plaza, building, field, gate, props, collect, npc }) t.SetParent(campus, false);

        BuildGround(ground);
        BuildPlaza(plaza);
        BuildTeachingBuilding(building);
        BuildPlayground(field);
        BuildMainGate(gate);
        BuildProps(props);
        BuildDetails(props, building);
        BuildCollection(collect);
        BuildNPCs(npc);
        BuildDataStore(campus);     // 存档：官方 DataStore 预制体 + CampusSave 宿主
        BuildAudio(campus);         // BGM/音效：文件在 Assets/Campus/Audio/（缺则跳过）
        BuildCeremony(campus);      // 毕业典礼：烟花节点池 + CampusCeremony 宿主

        // 拾取物都建完了，统一玻璃材质（省 2 个额度给女主角用）
        UnifyGlassSceneWide();

        var worldRoot = SetupWorldRoot();
        var env = SetupEnvironment();

        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene, ScenePath);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };
        AssetDatabase.SaveAssets();

        WriteReport(scene, worldRoot, env);
        Debug.Log("[Campus] done: " + ScenePath);
    }

    // ---------------------------------------------------------------- 场景内容

    static void BuildGround(Transform parent)
    {
        // 主地台：1000×1000。必须比雾的终点(300m)大得多，否则地平线会露出天空盒下半球，看起来像一片海。
        // 视觉用"米制 UV 的平面"（每 6m 一个贴图循环），碰撞仍用 1m 厚的隐形 BoxCollider。
        var g = new GameObject("Ground_Base");
        g.transform.SetParent(parent, false);
        g.AddComponent<MeshFilter>().sharedMesh =
            GetMesh("PlaneGround", () => BuildPlaneUV(1000f, 1000f, 6f));
        var gmr = g.AddComponent<MeshRenderer>();
        gmr.sharedMaterial = _mats["M_Lawn"];
        var gcol = g.AddComponent<BoxCollider>();
        gcol.center = new Vector3(0f, -0.5f, 0f);
        gcol.size = new Vector3(1000f, 1f, 1000f);

        // 校门 → 广场 的主干道
        Box("Path_Main", parent, new Vector3(0, 0.02f, -18), new Vector3(7, 0.04f, 20), "M_Concrete");
        // 广场 → 教学楼 的台阶前平台
        Box("Path_Building", parent, new Vector3(0, 0.02f, 15), new Vector3(16, 0.04f, 10), "M_Concrete");
        // 广场 → 操场 的支路
        Box("Path_Field", parent, new Vector3(-17.5f, 0.02f, -3), new Vector3(7, 0.04f, 5), "M_Concrete");

        g.isStatic = true;
    }

    static void BuildPlaza(Transform parent)
    {
        // 广场只做"一整块圆盘 + 一圈抬高路缘"，避免多层近共面网格互相打架（会渲染出放射状条纹）
        var core = MeshDisc("Plaza_Core", parent, 14f, 64, new Vector3(0, 0.05f, 0), "M_Paving_A");
        MeshRing("Plaza_Curb", parent, 13.2f, 14f, 64, new Vector3(0, 0.12f, 0), "M_Concrete");

        // 中心地标台：低矮圆形台基 + 一圈发光环（黄昏主视觉）
        Cyl("Plaza_PodiumBase", parent, 3.2f, 0.5f, new Vector3(0, 0.25f, 0), "M_Concrete");
        MeshRing("Plaza_PodiumGlow", parent, 2.6f, 3.0f, 48, new Vector3(0.01f, 0.52f, 0), "M_Emissive");

        // 四向花坛，给广场提供节奏
        for (int i = 0; i < 4; i++)
        {
            float a = i * 90f + 45f;
            var p = Polar(9f, a);
            Box("Planter_" + i, parent, new Vector3(p.x, 0.3f, p.z), new Vector3(3.4f, 0.6f, 3.4f), "M_Brick");
            var soil = Box("Planter_Soil_" + i, parent, new Vector3(p.x, 0.62f, p.z), new Vector3(3.0f, 0.06f, 3.0f), "M_Lawn");
            soil.layer = LayerCameraNoCollision;
        }

        core.isStatic = true;
    }

    static void BuildTeachingBuilding(Transform parent)
    {
        // 主楼：36(宽) × 13(深) × 13.5(高)，南面朝广场
        const float w = 36f, d = 13f, h = 13.5f;
        float cz = 26f; // 中心 Z

        // 台基
        Box("Bldg_Plinth", parent, new Vector3(0, 0.35f, cz), new Vector3(w + 2.4f, 0.7f, d + 2.4f), "M_Concrete");
        // 砖红基座带：原来是环绕整栋的实心盒（会顶到室内 2.7m，把一层填死），改成外墙外贴薄板
        const float wainT = 0.08f, wainH = 2f, wainY = 1.7f;    // 0.7 ~ 2.7
        float wainZ0 = 26f - d * 0.5f, wainZ1 = 26f + d * 0.5f;
        // 南面：让开 12m 宽入口
        Box("Bldg_Wainscot_S_L", parent, new Vector3(-(6f + 6.04f), wainY, wainZ0 - wainT * 0.5f),
            new Vector3(12.08f, wainH, wainT), "M_Brick");
        Box("Bldg_Wainscot_S_R", parent, new Vector3(6f + 6.04f, wainY, wainZ0 - wainT * 0.5f),
            new Vector3(12.08f, wainH, wainT), "M_Brick");
        // 北面 / 东西山墙
        Box("Bldg_Wainscot_N", parent, new Vector3(0, wainY, wainZ1 + wainT * 0.5f),
            new Vector3(w + 0.16f, wainH, wainT), "M_Brick");
        Box("Bldg_Wainscot_W", parent, new Vector3(-w * 0.5f - wainT * 0.5f, wainY, (wainZ0 + wainZ1) * 0.5f),
            new Vector3(wainT, wainH, d), "M_Brick");
        Box("Bldg_Wainscot_E", parent, new Vector3(w * 0.5f + wainT * 0.5f, wainY, (wainZ0 + wainZ1) * 0.5f),
            new Vector3(wainT, wainH, d), "M_Brick");
        // 压顶
        Box("Bldg_Roof", parent, new Vector3(0, 0.7f + h + 0.35f, cz), new Vector3(w + 2f, 0.7f, d + 2f), "M_Concrete");

        float facadeZ = cz - d / 2f;           // 南立面（朝广场，Z 更小）
        float floorH = (h - 2.4f) / 3f;        // 三层均分，底部留基座

        // ---- 主体：由实心立方体改为 4 块有厚度的墙板 ----
        // 原来的 Box 是空心网格，从内部看所有面都被背面剔除，室内必然是"黑箱"。
        // 拆板后外轮廓保持完全一致（X ±18 / Z 19.5~32.5 / Y 0.7~14.2），但内部可进入。
        const float wallT = 0.4f;
        float y0 = 0.7f, y1 = 0.7f + h;        // 0.7 ~ 14.2
        const float doorBay = 12f;             // 南墙入口洞宽（与门厅同宽）
        const float lintelY = 4.8f;            // 洞口顶标高

        float sideW = (w - doorBay) * 0.5f;    // 12
        float wallY = (y0 + y1) * 0.5f;
        // 南墙：左右两段 + 过梁
        Box("Bldg_WallS_L", parent, new Vector3(-(doorBay * 0.5f + sideW * 0.5f), wallY, facadeZ + wallT * 0.5f),
            new Vector3(sideW, h, wallT), "M_Wall");
        Box("Bldg_WallS_R", parent, new Vector3(doorBay * 0.5f + sideW * 0.5f, wallY, facadeZ + wallT * 0.5f),
            new Vector3(sideW, h, wallT), "M_Wall");
        Box("Bldg_WallS_Lintel", parent, new Vector3(0, lintelY + (y1 - lintelY) * 0.5f, facadeZ + wallT * 0.5f),
            new Vector3(doorBay, y1 - lintelY, wallT), "M_Wall");
        // 北墙、东西山墙
        Box("Bldg_WallN", parent, new Vector3(0, wallY, cz + d * 0.5f - wallT * 0.5f),
            new Vector3(w, h, wallT), "M_Wall");
        Box("Bldg_WallW", parent, new Vector3(-w * 0.5f + wallT * 0.5f, wallY, cz),
            new Vector3(wallT, h, d - wallT * 2f), "M_Wall");
        Box("Bldg_WallE", parent, new Vector3(w * 0.5f - wallT * 0.5f, wallY, cz),
            new Vector3(wallT, h, d - wallT * 2f), "M_Wall");

        // 窗：按开间切成 9 段，约 1/3 亮灯。黄昏里"部分教室有人"比整条亮带更像真实校园
        const int segs = 9;
        float segW = (w - 2.4f) / segs;
        for (int f = 0; f < 3; f++)
        {
            float y = 2.2f + f * floorH + floorH * 0.5f;
            for (int s = 0; s < segs; s++)
            {
                float x = -w / 2f + 1.2f + segW * (s + 0.5f);
                // 一层入口范围内不放窗贴片：门厅打通后，这几扇窗会正好封在主门洞前面变成一块黑幕
                if (f == 0 && Mathf.Abs(x) < 6.2f) continue;
                bool lit = (f * 2 + s) % 3 == 0;
                var pane = Box("Bldg_Win_" + f + "_" + s, parent,
                    new Vector3(x, y, facadeZ - 0.08f),
                    new Vector3(segW * 0.86f, floorH * 0.62f, 0.14f),
                    lit ? "M_Emissive" : "M_Glass");
                pane.layer = LayerCameraNoCollision;
            }
        }

        // 竖向壁柱：每 3.6m 一根，贯穿三层。入口门洞范围内不放（原来藏在门厅实心体块里，
        // 门厅打通后会变成立在门口正中的挡路柱）
        for (int i = 0; i <= 10; i++)
        {
            float x = -w / 2f + 1.2f + i * ((w - 2.4f) / 10f);
            if (Mathf.Abs(x) < 6.2f) continue;
            Box("Bldg_Mullion_" + i, parent,
                new Vector3(x, 0.7f + h / 2f, facadeZ - 0.2f), new Vector3(0.35f, h - 1.4f, 0.3f), "M_Wall");
        }

        // 入口门厅：由实心出挑体块改为可穿行的门斗（两侧墙 + 顶板 + 带门洞的前脸）
        float porchZ = facadeZ - 1.5f;   // 门厅中心，凸出 1.5m
        float porchFront = porchZ - 1.5f;
        Box("Bldg_Canopy", parent, new Vector3(0, 6.4f, facadeZ - 2.5f), new Vector3(14f, 0.5f, 5f), "M_Concrete");

        Box("Bldg_Porch_L", parent, new Vector3(-6f + wallT * 0.5f, 3f, porchZ), new Vector3(wallT, 6f, 3f), "M_Wall");
        Box("Bldg_Porch_R", parent, new Vector3(6f - wallT * 0.5f, 3f, porchZ), new Vector3(wallT, 6f, 3f), "M_Wall");
        Box("Bldg_Porch_Top", parent, new Vector3(0, 5.75f, porchZ), new Vector3(12f - wallT * 2f, 0.5f, 3f), "M_Wall");

        const float openW = 5f, openH = 4.8f;  // 门洞净宽 / 顶标高
        float frontSeg = (12f - openW) * 0.5f; // 3.5
        Box("Bldg_Porch_FrontL", parent, new Vector3(-(openW * 0.5f + frontSeg * 0.5f), 3f, porchFront + wallT * 0.5f),
            new Vector3(frontSeg, 6f, wallT), "M_Wall");
        Box("Bldg_Porch_FrontR", parent, new Vector3(openW * 0.5f + frontSeg * 0.5f, 3f, porchFront + wallT * 0.5f),
            new Vector3(frontSeg, 6f, wallT), "M_Wall");
        Box("Bldg_Porch_FrontLintel", parent, new Vector3(0, (openH + 6f) * 0.5f, porchFront + wallT * 0.5f),
            new Vector3(openW, 6f - openH, wallT), "M_Wall");
        // 主立面校名牌：过梁只有 4.8~6.0 这一段是净墙，牌匾就卡在这儿，正对广场
        // 同上：pos 是底边中心，过梁 4.8~6.0，字面 1.15 高 → 底边 4.845
        AddSignQuad("Bldg_SignFront", parent, new Vector3(0, 4.845f, porchFront - 0.02f), 4.7f, 1.15f, 180f);

        // 门框（金属）+ 两扇向外敞开 90° 的玻璃门，中间完全通透，黄昏时能看到室内暖光
        Box("Bldg_DoorFrame_T", parent, new Vector3(0, openH - 0.05f, porchFront - 0.04f),
            new Vector3(openW + 0.16f, 0.12f, 0.18f), "M_Metal");
        Box("Bldg_DoorFrame_L", parent, new Vector3(-openW * 0.5f - 0.06f, (0.7f + openH) * 0.5f, porchFront - 0.04f),
            new Vector3(0.12f, openH - 0.7f, 0.18f), "M_Metal");
        Box("Bldg_DoorFrame_R", parent, new Vector3(openW * 0.5f + 0.06f, (0.7f + openH) * 0.5f, porchFront - 0.04f),
            new Vector3(0.12f, openH - 0.7f, 0.18f), "M_Metal");
        // 两扇门完全打开、贴在前脸外侧：位置必须让到洞口边缘(±2.5)之外，
        // 否则从室内看出去，门扇的侧投影会像两块黑墙堵在门口
        Box("Bldg_DoorLeaf_L", parent, new Vector3(-openW * 0.5f - 0.36f, 2.4f, porchFront - 1.15f),
            new Vector3(0.1f, 3.3f, 2.2f), "M_Glass");
        Box("Bldg_DoorLeaf_R", parent, new Vector3(openW * 0.5f + 0.36f, 2.4f, porchFront - 1.15f),
            new Vector3(0.1f, 3.3f, 2.2f), "M_Glass");

        // 入口台阶：视觉用真实台阶，碰撞用一条隐形斜坡（官方规范：台阶必须有斜面碰撞）
        for (int i = 0; i < 4; i++)
        {
            Box("Bldg_Step_" + i, parent,
                new Vector3(0, 0.15f + i * 0.3f, porchFront - 2.1f + i * 0.6f),
                new Vector3(8f, 0.3f, 0.6f), "M_Concrete");
        }
        var ramp = new GameObject("Bldg_StairCollider");
        ramp.transform.SetParent(parent, false);
        ramp.transform.position = new Vector3(0, 0.62f, porchFront - 1.6f);
        ramp.transform.rotation = Quaternion.Euler(-12f, 0, 0);
        ramp.AddComponent<BoxCollider>().size = new Vector3(8f, 0.3f, 3.8f);
        ramp.layer = LayerCameraNoCollision;

        // 侧翼：两侧各一个低体块，打破盒子感
        Box("Bldg_WingL", parent, new Vector3(-w / 2f - 4f, 3.5f, cz + 1f), new Vector3(8f, 7f, 10f), "M_Wall");
        Box("Bldg_WingR", parent, new Vector3(w / 2f + 4f, 3.5f, cz + 1f), new Vector3(8f, 7f, 10f), "M_Wall");
        Box("Bldg_WingRoofL", parent, new Vector3(-w / 2f - 4f, 7.35f, cz + 1f), new Vector3(8.6f, 0.7f, 10.6f), "M_Concrete");
        Box("Bldg_WingRoofR", parent, new Vector3(w / 2f + 4f, 7.35f, cz + 1f), new Vector3(8.6f, 0.7f, 10.6f), "M_Concrete");

        // ---- 一层室内 ----
        BuildInterior(parent);
    }

    // ================================================================ 室内（两层）

    const float IN_WALL = 0.4f;
    const float F1 = 1.2f, C1 = 5.3f;       // 一层：地面 / 天花底
    const float F2 = 5.5f, C2 = 9.6f;       // 二层（F2 = C1 + 楼板 0.2）
    const float F3 = 9.8f, C3 = 13.9f;      // 三层（F3 = C2 + 楼板 0.2；C3 已到屋顶 14.2）
    const float CORR_Z = 23.4f, CORR_T = 0.3f;
    const float X_IN = 17.6f, Z_S = 19.9f, Z_N = 32.1f, Z_ROOM = 23.7f;
    const float STAIR_X = 13.4f;            // 楼梯间西墙位置（教室 3 缩到 8.8~13.4）
    const float DOOR_W = 1.7f, DOOR_H = 2.2f;

    static void BuildInterior(Transform parent)
    {
        BuildGroundFloor(parent);
        BuildStairwell(parent);
        BuildSecondFloor(parent);
        BuildThirdFloor(parent);
    }

    // ---------------------------------------------------------------- 通用件

    // 楼板 0.15 + 天花 0.05，两块严格贴合但不重叠。
    // 之前两者都是 0.2 且上下完全重合，属于"共面互踢"，靠渲染顺序侥幸没出问题。
    static void FloorSlab(string name, Transform parent, float x0, float x1, float z0, float z1, float topY, string mat)
        => Box(name, parent, new Vector3((x0 + x1) * 0.5f, topY - 0.075f, (z0 + z1) * 0.5f),
            new Vector3(x1 - x0, 0.15f, z1 - z0), mat);

    static void CeilingSlab(string name, Transform parent, float x0, float x1, float z0, float z1, float bottomY, string mat)
        => Box(name, parent, new Vector3((x0 + x1) * 0.5f, bottomY + 0.025f, (z0 + z1) * 0.5f),
            new Vector3(x1 - x0, 0.05f, z1 - z0), mat);

    /// <summary>走廊墙：在 [x0,x1] 之间按门洞中心列表开洞，附带门套与班级牌</summary>
    static void CorridorWall(string prefix, Transform parent, float x0, float x1,
        float floorY, float ceilY, float[] doorCenters)
    {
        float top = floorY + DOOR_H;
        float cursor = x0;
        int n = 0;
        foreach (float dc in doorCenters)
        {
            float d0 = dc - DOOR_W * 0.5f, d1 = dc + DOOR_W * 0.5f;
            if (d0 - cursor > 0.05f)
                Box(prefix + "_Seg" + (n++), parent,
                    new Vector3((cursor + d0) * 0.5f, (floorY + ceilY) * 0.5f, CORR_Z + CORR_T * 0.5f),
                    new Vector3(d0 - cursor, ceilY - floorY, CORR_T), "M_Interior");
            Box(prefix + "_Lintel" + (n++), parent,
                new Vector3(dc, (top + ceilY) * 0.5f, CORR_Z + CORR_T * 0.5f),
                new Vector3(DOOR_W, ceilY - top, CORR_T), "M_Interior");
            for (int s = -1; s <= 1; s += 2)
                Box(prefix + "_Jamb" + n + "_" + s, parent,
                    new Vector3(dc + s * (DOOR_W * 0.5f + 0.05f), (floorY + top) * 0.5f, CORR_Z - 0.03f),
                    new Vector3(0.1f, top - floorY, 0.12f), "M_Wood");
            Box(prefix + "_Plate" + n, parent, new Vector3(dc, top + 0.42f, CORR_Z - 0.04f),
                new Vector3(1.05f, 0.42f, 0.06f), "M_Wood");
            cursor = d1;
        }
        if (x1 - cursor > 0.05f)
            Box(prefix + "_Seg" + (n), parent,
                new Vector3((cursor + x1) * 0.5f, (floorY + ceilY) * 0.5f, CORR_Z + CORR_T * 0.5f),
                new Vector3(x1 - cursor, ceilY - floorY, CORR_T), "M_Interior");
    }

    /// <summary>走廊南墙内侧的窗（内衬 / 玻璃 / 窗台 / 踢脚 / 窗棂）。内衬必须比墙内表面更靠 +Z</summary>
    static void WindowRun(string prefix, Transform parent, float cx, float segW, float floorY, float ceilY, float zS)
    {
        float h = ceilY - floorY;
        float sillY = floorY + 1.66f;
        const float winH = 2.3f;
        float winC = sillY + 0.04f + winH * 0.5f;

        Box(prefix + "_Lining", parent, new Vector3(cx, floorY + h * 0.5f, zS + 0.03f), new Vector3(segW, h, 0.06f), "M_Interior");
        Box(prefix + "_Win", parent, new Vector3(cx, winC, zS + 0.09f), new Vector3(segW, winH, 0.04f), "M_Window");
        Box(prefix + "_Sill", parent, new Vector3(cx, sillY, zS + 0.16f), new Vector3(segW, 0.1f, 0.2f), "M_Wood");
        Box(prefix + "_Skirt", parent, new Vector3(cx, floorY + 0.1f, zS + 0.12f), new Vector3(segW, 0.16f, 0.08f), "M_Wood");
        for (int m = 0; m <= 7; m++)
            Box(prefix + "_Mul" + m, parent,
                new Vector3(cx - segW * 0.5f + m * (segW / 7f), winC, zS + 0.13f),
                new Vector3(0.1f, winH, 0.06f), "M_Metal");
        Box(prefix + "_MulH", parent, new Vector3(cx, winC, zS + 0.13f), new Vector3(segW, 0.1f, 0.06f), "M_Metal");
    }

    /// <summary>一间教室：黑板+高侧窗贴北墙，讲台朝北，课桌按 cols 列排布</summary>
    static void Classroom(string p, Transform parent, float cx, float floorY, float ceilY, int cols, float boardW = 5.4f)
    {
        Box(p + "_BoardFrame", parent, new Vector3(cx, floorY + 1.80f, Z_N - 0.015f), new Vector3(boardW + 0.3f, 1.62f, 0.03f), "M_Wood");
        Box(p + "_Board", parent, new Vector3(cx, floorY + 1.80f, Z_N - 0.05f), new Vector3(boardW, 1.36f, 0.04f), "M_Lawn");
        Box(p + "_BoardTray", parent, new Vector3(cx, floorY + 1.04f, Z_N - 0.09f), new Vector3(boardW, 0.08f, 0.16f), "M_Wood");
        Box(p + "_Clerestory", parent, new Vector3(cx, floorY + 3.48f, Z_N - 0.03f), new Vector3(Mathf.Min(boardW + 1f, 6.4f), 0.72f, 0.04f), "M_Window");

        Box(p + "_Podium", parent, new Vector3(cx, floorY + 0.13f, 31.05f), new Vector3(2.6f, 0.26f, 0.9f), "M_Concrete");
        Box(p + "_Desk", parent, new Vector3(cx, floorY + 0.44f, 30.2f), new Vector3(1.2f, 0.86f, 0.55f), "M_Wood");

        float[] colX = cols >= 3 ? new[] { -2.7f, 0f, 2.7f } : new[] { -1.4f, 1.4f };
        // 排距 2.0：原来最前排 29.7 会顶进讲桌（29.93 起），两件家具叠在一起
        float[] rowZ = { 29.35f, 27.35f, 25.35f };

        // 一套桌椅 = 木件（桌面 + 座面 + 靠背）+ 铁件（桌腿 + 椅腿）+ 桌上书本，三个合并网格复用
        var deskWood = GetMesh("DeskUnit_Wood", () => BuildBoxCluster(new[]
        {
            new BoxPart(0f, 0.73f, 0f, 1.25f, 0.06f, 0.58f),       // 桌面
            new BoxPart(0f, 0.42f, -0.95f, 0.44f, 0.08f, 0.44f),   // 座面
            new BoxPart(0f, 0.67f, -1.15f, 0.44f, 0.42f, 0.06f),   // 靠背
        }));
        var deskMetal = GetMesh("DeskUnit_Metal", () => BuildBoxCluster(new[]
        {
            new BoxPart(-0.56f, 0.36f, 0f, 0.05f, 0.72f, 0.50f),
            new BoxPart( 0.56f, 0.36f, 0f, 0.05f, 0.72f, 0.50f),
            new BoxPart(-0.18f, 0.19f, -0.78f, 0.04f, 0.38f, 0.04f),
            new BoxPart( 0.18f, 0.19f, -0.78f, 0.04f, 0.38f, 0.04f),
            new BoxPart(-0.18f, 0.19f, -1.12f, 0.04f, 0.38f, 0.04f),
            new BoxPart( 0.18f, 0.19f, -1.12f, 0.04f, 0.38f, 0.04f),
        }));
        var deskBooks = DeskBooksMesh();
        // 书本只用"哑光"材质：M_Sign / M_Collect 是自发光，做书会亮成霓虹板
        string[] bookMats = { "M_Wall", "M_Brick", "M_Lawn", "M_Glass" };

        for (int c = 0; c < colX.Length; c++)
        {
            for (int r = 0; r < rowZ.Length; r++)
            {
                float dx = cx + colX[c], dz = rowZ[r];
                var pos = new Vector3(dx, floorY, dz);
                PlaceCluster(p + "_Desk" + c + r, parent, pos, Quaternion.identity, deskWood, "M_Wood", true);
                PlaceCluster(p + "_Frame" + c + r, parent, pos, Quaternion.identity, deskMetal, "M_Metal", false);
                PlaceCluster(p + "_Books" + c + r, parent, pos, Quaternion.identity, deskBooks,
                    bookMats[(c + r) % bookMats.Length], false);
            }
        }

        // 教室前角书柜：独立隔墙的书架会让房间瞬间"有人住"。小教室（开间只有 4.6m）放不下，跳过。
        if (cols >= 3)
        {
            float cxx = cx + 3.55f, czz = Z_N - 0.30f;
            var frame = GetMesh("CabinetFrame", () => BuildBoxCluster(new[]
            {
                new BoxPart(0f, 0.98f, 0f, 1.30f, 1.96f, 0.06f),      // 背板
                new BoxPart(-0.625f, 0.98f, -0.15f, 0.05f, 1.96f, 0.36f),
                new BoxPart( 0.625f, 0.98f, -0.15f, 0.05f, 1.96f, 0.36f),
                new BoxPart(0f, 0.34f, -0.15f, 1.30f, 0.05f, 0.36f),
                new BoxPart(0f, 0.92f, -0.15f, 1.30f, 0.05f, 0.36f),
                new BoxPart(0f, 1.50f, -0.15f, 1.30f, 0.05f, 0.36f),
            }));
            PlaceCluster(p + "_Cabinet", parent, new Vector3(cxx, floorY, czz), Quaternion.identity,
                frame, "M_Wood", true);
            // 每层拆成两段不同材质：一个网格只能有一种材质，整排同色会糊成一块板
            var rowA = BookRowMesh(5, 0.55f, 0.34f, 0.30f, 7);
            var rowB = BookRowMesh(4, 0.50f, 0.34f, 0.30f, 11);
            string[] cabMats = { "M_Wall", "M_Brick", "M_Lawn", "M_Glass", "M_Interior", "M_Paving_A" };
            for (int s = 0; s < 3; s++)
            {
                float y = floorY + 0.37f + s * 0.58f;
                PlaceCluster(p + "_CabBookA" + s, parent,
                    new Vector3(cxx - 0.525f, y, czz - 0.20f), Quaternion.identity, rowA, cabMats[s], false);
                PlaceCluster(p + "_CabBookB" + s, parent,
                    new Vector3(cxx + 0.025f, y, czz - 0.20f), Quaternion.identity, rowB, cabMats[s + 1], false);
            }
        }

        Box(p + "_LightA", parent, new Vector3(cx, ceilY - 0.07f, 28.6f), new Vector3(3.0f, 0.07f, 0.62f), "M_Emissive");
        Box(p + "_LightB", parent, new Vector3(cx, ceilY - 0.07f, 26.2f), new Vector3(3.0f, 0.07f, 0.62f), "M_Emissive");
    }

    /// <summary>方凳（座面 + 4 条腿合并成一个网格）—— 阅览角原来直接用 Cube，看着像木箱</summary>
    static Mesh StoolMesh()
        => GetMesh("StoolUnitV2", () => BuildBoxCluster(new[]
        {
            new BoxPart(0f, 0.42f, 0f, 0.44f, 0.06f, 0.44f),
            new BoxPart(-0.17f, 0.20f, -0.17f, 0.05f, 0.40f, 0.05f),
            new BoxPart( 0.17f, 0.20f, -0.17f, 0.05f, 0.40f, 0.05f),
            new BoxPart(-0.17f, 0.20f,  0.17f, 0.05f, 0.40f, 0.05f),
            new BoxPart( 0.17f, 0.20f,  0.17f, 0.05f, 0.40f, 0.05f),
        }));

    /// <summary>课桌上那摞书（3 本叠放，局部 y 相对地面，桌面高 0.76）</summary>
    static Mesh DeskBooksMesh()
        => GetMesh("DeskUnit_Books", () => BuildBoxCluster(new[]
        {
            new BoxPart(-0.34f, 0.775f, 0.05f, 0.30f, 0.035f, 0.22f),
            new BoxPart(-0.33f, 0.808f, 0.04f, 0.28f, 0.030f, 0.21f),
            new BoxPart(-0.31f, 0.837f, 0.05f, 0.25f, 0.028f, 0.19f),
        }));

    static GameObject BoxRot(string name, Transform parent, Vector3 pos, Vector3 size, string mat, Vector3 euler)    {
        var go = Box(name, parent, pos, size, mat);
        go.transform.localRotation = Quaternion.Euler(euler);
        return go;
    }

    // ---------------------------------------------------------------- 一层

    static void BuildGroundFloor(Transform parent)
    {
        float floorT = F1 - 0.7f;
        float h = C1 - F1;

        // 地坪：门厅（16.5 起接台阶）+ 室内
        Box("In_Floor_Lobby", parent, new Vector3(0, 0.7f + floorT * 0.5f, 18.2f),
            new Vector3(12f - IN_WALL * 2f, floorT, 3.4f), "M_Concrete");
        Box("In_Floor", parent, new Vector3(0, 0.7f + floorT * 0.5f, (Z_S + Z_N) * 0.5f),
            new Vector3(X_IN * 2f, floorT, Z_N - Z_S), "M_Concrete");

        // 天花层（0.05 厚，贴在二层楼板下）。楼梯井上方必须挖空，否则一层天花板会把井封死。
        // X 13.4~17.6 / Z 25.4~32.1 是井；南侧那一条（Z 19.9~25.4）要补上，否则从一层能看到楼板侧面。
        CeilingSlab("In_Ceiling", parent, -X_IN, STAIR_X, Z_S, Z_N, C1, "M_Interior");
        CeilingSlab("In_Ceiling_StairS", parent, STAIR_X, X_IN, Z_S, 25.4f, C1, "M_Interior");
        CeilingSlab("In_Ceiling_Lobby", parent, -5.6f, 5.6f, 16.5f, 19.9f, C1, "M_Interior");

        // 入口门套：否则从走廊回看入口时，洞口上方是一整块背光的暗墙
        Box("In_PortalHead", parent, new Vector3(0, 4.65f, 19.7f), new Vector3(12f, 0.32f, IN_WALL + 0.02f), "M_Interior");
        Box("In_Portal_L", parent, new Vector3(-5.85f, 3.0f, 19.7f), new Vector3(0.32f, 3.6f, IN_WALL + 0.02f), "M_Interior");
        Box("In_Portal_R", parent, new Vector3(5.85f, 3.0f, 19.7f), new Vector3(0.32f, 3.6f, IN_WALL + 0.02f), "M_Interior");

        // 门斗内衬：门斗四面是外墙材质（M_Wall，无自发光），黄昏从室内看是黑的
        Box("In_PorchLining_L", parent, new Vector3(-5.46f, 3.25f, 18.2f), new Vector3(0.1f, 4.1f, 2.6f), "M_Interior");
        Box("In_PorchLining_R", parent, new Vector3(5.46f, 3.25f, 18.2f), new Vector3(0.1f, 4.1f, 2.6f), "M_Interior");
        Box("In_PorchLining_Top", parent, new Vector3(0, 5.16f, 18.2f), new Vector3(10.9f, 0.1f, 2.6f), "M_Interior");
        Box("In_PorchLining_BackL", parent, new Vector3(-4.05f, 3.25f, 16.94f), new Vector3(3.1f, 4.1f, 0.08f), "M_Interior");
        Box("In_PorchLining_BackR", parent, new Vector3(4.05f, 3.25f, 16.94f), new Vector3(3.1f, 4.1f, 0.08f), "M_Interior");
        Box("In_PorchLining_BackTop", parent, new Vector3(0, 5.4f, 16.94f), new Vector3(5f, 1.2f, 0.08f), "M_Interior");

        // 走廊窗
        WindowRun("In_WinW", parent, -11.8f, 11.2f, F1, C1, Z_S);
        WindowRun("In_WinE", parent, 11.8f, 11.2f, F1, C1, Z_S);

        // 走廊墙：3 间标准教室 + 1 间小教室 + 楼梯间门
        CorridorWall("In_CW", parent, -X_IN, X_IN, F1, C1,
            new[] { -13.2f, -4.4f, 4.4f, 11.1f, 15.5f });

        // 隔墙（含楼梯间西墙 X 13.4）
        foreach (float px in new[] { -8.8f, 0f, 8.8f, STAIR_X })
            Box("In_PartWall_" + px, parent, new Vector3(px, (F1 + C1) * 0.5f, (Z_ROOM + Z_N) * 0.5f),
                new Vector3(CORR_T, h, Z_N - Z_ROOM), "M_Interior");

        // 走廊灯带
        for (int i = 0; i < 8; i++)
            Box("In_CorrLight" + i, parent, new Vector3(-15.4f + i * 4.4f, C1 - 0.05f, 21.6f),
                new Vector3(2.0f, 0.06f, 0.42f), "M_Emissive");
        Box("In_LobbyLight", parent, new Vector3(0, C1 - 0.05f, 18.2f), new Vector3(4.0f, 0.06f, 0.35f), "M_Emissive");

        // 门厅服务台
        Box("In_ReceptionBody", parent, new Vector3(-9.0f, 1.72f, 20.55f), new Vector3(3.4f, 1.0f, 0.7f), "M_Wood");
        Box("In_ReceptionTop", parent, new Vector3(-9.0f, 2.26f, 20.55f), new Vector3(3.7f, 0.08f, 0.92f), "M_Concrete");

        // 教室
        Classroom("In_R0", parent, -13.2f, F1, C1, 3);
        Classroom("In_R1", parent, -4.4f, F1, C1, 3);
        Classroom("In_R2", parent, 4.4f, F1, C1, 3);
        Classroom("In_R3", parent, 11.1f, F1, C1, 2, 3.8f);   // 4.6m 宽的小教室，黑板不能超出开间
    }

    // ---------------------------------------------------------------- 楼梯间

    /// <summary>
    /// 斜碰撞板：给定"顶面"必须经过的两点 (z0,y0) → (z1,y1)，生成一块隐形的斜板。
    /// 板厚 0.2，沿坡向在起点侧多伸出 extend，避免起步处出现细缝；终点严格落在给定高度上，不多也不少。
    /// 之前是手算中心点 + 长度（水平长度用了 runZ=3.0，比真实 13 级踏步的 3.25 少了一级，
    /// 又额外 +0.06 抬高、+0.3 加长），结果每跑顶端比踏面高出 0.22m —— 每次登顶都被顶一下再掉下来。
    /// </summary>
    static GameObject StairRamp(string name, Transform parent, float xc, float width,
        float z0, float y0, float z1, float y1, float extend = 0.45f)
    {
        float dz = z1 - z0, dy = y1 - y0;
        float len = Mathf.Sqrt(dz * dz + dy * dy);
        float uz = dz / len, uy = dy / len;

        // 起点沿坡向往回延一段，坡度保持不变
        float sz = z0 - uz * extend, sy = y0 - uy * extend;
        float lz = z1 - sz, ly = y1 - sy;
        float llen = Mathf.Sqrt(lz * lz + ly * ly);

        // (z,y) 平面内的上侧法线，保证 y 分量为正
        float nz = -ly / llen, ny = lz / llen;
        if (ny < 0f) { nz = -nz; ny = -ny; }

        const float halfT = 0.1f;
        var center = new Vector3(xc,
            (sy + y1) * 0.5f - halfT * ny,
            (sz + z1) * 0.5f - halfT * nz);
        var go = Box(name, parent, center, new Vector3(width, halfT * 2f, llen), "M_Metal");
        // 局部 +Y 转到法线方向
        go.transform.localRotation = Quaternion.Euler(Mathf.Atan2(nz, ny) * Mathf.Rad2Deg, 0f, 0f);
        go.GetComponent<Renderer>().enabled = false;
        return go;
    }

    /// <summary>
    /// 每层 26 级、4.3m 高差，双跑（各 13 级 + 中间休息平台）。
    /// 楼层之间完全镜像堆叠：上层梯段压在下层梯段正上方，这是双跑楼梯的标准做法。
    /// 视觉踏步是实心 Box（各自删掉 collider），碰撞另外用一块隐形斜板 ——
    /// 官方规范要求台阶必须有斜面碰撞，只靠台阶自身的 collider 在 stepOffset 不足时会走不上去。
    /// </summary>
    static void BuildStairwell(Transform parent)
    {
        const float stepH = 0.1654f, stepD = 0.25f;
        const int steps = 13;                          // 每跑 13 级，两跑 4.3m
        const float runZ = steps * stepD;              // 3.25：13 级 × 0.25（原来按 12 级算，斜板因此比踏步陡）
        const float landD = 1.7f;
        const float soffitT = 0.34f;                   // 梯板厚度（踏步底面随坡度倾斜）

        // 标准 U 形双跑：上下两跑在同一段 z 上相邻（西道 / 东道，中间不留缝），休息平台在整个北端。
        // 两跑的起步 / 落点都在 z=25.4，正好是二、三层楼板的洞口边，上下楼都是平的接口。
        const float zA0 = 25.4f;                       // 一跑起步 / 二跑落点（洞口南沿）
        const float zA1 = zA0 + runZ;                  // 28.65 一跑顶端 = 平台南沿
        const float zL0 = zA1, zL1 = zA1 + landD;      // 休息平台 28.65~30.35（整宽）
        const float zB0 = zA0;                         // 二跑顶端（= 上层楼板面）
        const float zB1 = zL0;                         // 二跑起步（平台上，与一跑顶同一 z）

        // 两跑道严丝合缝地并在一起（15.6 是对缝），东沿顶到外墙 17.6 —— 原来中间留 15cm、东边留 10cm 的缝，
        // 从上往下能直接看到一层地面，就是"楼梯根漏了个洞"的来源
        const float runAW = 1.9f, runAX = 13.7f + 0.95f;     // 14.65 西道 13.7~15.6
        const float runBW = 2.0f, runBX = 15.6f + 1.0f;      // 16.60 东道 15.6~17.6

        for (int lv = 0; lv < 2; lv++)
        {
            float baseY = F1 + lv * (F2 - F1);         // 1.2 / 5.5
            float midY = baseY + steps * stepH;        // 3.35 / 7.65
            float topY = baseY + 2f * steps * stepH;   // 5.5  / 9.8
            string p = "Stair" + lv;

            // 一跑（西道）：南 → 北。踏步实心，但底面沿坡度下沉成一个斜梯板。
            // 之前踏步是从 baseY 起的一个个方块、二跑下方再塞一整块填充墙 —— 那块墙正好堵在
            // 下一层二跑的头顶上，爬到一半只剩 1.1m 净空，人是过不去的。改成梯板跟着坡走就没这问题。
            for (int i = 0; i < steps; i++)
            {
                float top = baseY + (i + 1) * stepH;
                float z = zA0 + i * stepD + stepD * 0.5f;
                float t = (z - zA0) / runZ;
                float bottom = Mathf.Lerp(baseY - soffitT, midY - soffitT, t);
                var go = Box(p + "_A" + i, parent,
                    new Vector3(runAX, (bottom + top) * 0.5f, z),
                    new Vector3(runAW, top - bottom, stepD), "M_Concrete");
                UnityEngine.Object.DestroyImmediate(go.GetComponent<Collider>());
            }

            // 休息平台（北端，整宽）。**这里必须保留 Collider**：原来跟踏步一样把它删了，
            // 等于平台是一块纯视觉的悬空薄板 —— 一跑登顶后脚下就什么都没有，玩家直接掉回一层。
            Box(p + "_Landing", parent, new Vector3(15.625f, midY - 0.15f, (zL0 + zL1) * 0.5f),
                new Vector3(3.95f, 0.3f, landD), "M_Concrete");

            // 平台下方填实（平台不再被二跑压住，整块都要有支撑，否则从一层抬头能看到一块悬空的薄板）
            float fillH = midY - 0.3f - baseY;         // 1.85
            Box(p + "_LandingFill", parent,
                new Vector3(15.625f, baseY + fillH * 0.5f, (zL0 + zL1) * 0.5f + 0.08f),
                new Vector3(3.95f, fillH, landD - 0.16f), "M_Concrete");

            // 平台北沿护栏：平台北侧是通高楼梯井（井一直到屋顶），没有栏杆玩家顺着惯性就掉下去了
            for (int i = 0; i <= 7; i++)
                Box(p + "_LandRail" + i, parent, new Vector3(13.75f + i * 0.51f, midY + 0.55f, zL1 - 0.06f),
                    new Vector3(0.06f, 1.1f, 0.06f), "M_Metal");
            Box(p + "_LandHand", parent, new Vector3(15.6f, midY + 1.12f, zL1 - 0.06f),
                new Vector3(3.6f, 0.08f, 0.08f), "M_Wood");

            // 二跑（东道）：北 → 南。梯板同样随坡度下沉，下方是空的（那就是下一层二跑的通行空间）
            for (int i = 0; i < steps; i++)
            {
                float top = midY + (i + 1) * stepH;
                float z = zB1 - i * stepD - stepD * 0.5f;
                float t = (zB1 - z) / runZ;
                float bottom = Mathf.Lerp(midY - soffitT, topY - soffitT, t);
                var go = Box(p + "_B" + i, parent,
                    new Vector3(runBX, (bottom + top) * 0.5f, z),
                    new Vector3(runBW, top - bottom, stepD), "M_Concrete");
                UnityEngine.Object.DestroyImmediate(go.GetComponent<Collider>());
            }

            // 隐形斜碰撞：顶面走"踏面中点连线"，两端严格对齐平台面 / 上层楼板面，
            // 全程与踏面的偏差控制在 ±8cm（比原来顶端 22cm 的坎小一个量级，走上去察觉不到）。
            StairRamp(p + "_RampA", parent, runAX, runAW, zA0, baseY + stepH * 0.5f, zA1, midY);
            StairRamp(p + "_RampB", parent, runBX, runBW, zB1, midY + stepH * 0.5f, zB0, topY);

            // 壁灯贴在楼梯井北墙（z=Z_N）上：原来这两块发光板浮在井道中间、还有一半插在二跑实体里
            Box(p + "_LightA", parent, new Vector3(15.5f, midY + 1.70f, Z_N - 0.05f),
                new Vector3(1.8f, 0.42f, 0.05f), "M_Emissive");
            Box(p + "_LightB", parent, new Vector3(15.5f, midY + 3.40f, Z_N - 0.05f),
                new Vector3(1.8f, 0.42f, 0.05f), "M_Emissive");
        }
    }

    // ---------------------------------------------------------------- 二层

    static void BuildSecondFloor(Transform parent)
    {
        float h = C2 - F2;

        // 地板：主区 + 楼梯口南侧一条（楼梯井 13.4~17.6 / 23.7~32.1 留空）
        FloorSlab("In2_Floor", parent, -X_IN, STAIR_X, Z_S, Z_N, F2, "M_Concrete");
        FloorSlab("In2_FloorCorr", parent, STAIR_X, X_IN, Z_S, 25.4f, F2, "M_Concrete");
        // 楼梯井西沿的楼板压边：楼板到 13.4 就断了，梯段从 13.7 起，中间 0.3m 原来是直接看得到一层的缝，
        // 栏杆也正好站在这一条上（原来是悬空的）
        FloorSlab("In2_EdgeW", parent, 13.4f, 13.7f, 25.4f, Z_N, F2, "M_Concrete");

        // 天花（= 三层楼板下皮）。楼梯井上方留空，否则二层到三层上不去
        CeilingSlab("In2_Ceiling", parent, -X_IN, STAIR_X, Z_S, Z_N, C2, "M_Interior");
        CeilingSlab("In2_Ceiling_S", parent, STAIR_X, X_IN, Z_S, 25.4f, C2, "M_Interior");

        // 走廊窗
        WindowRun("In2_WinW", parent, -11.8f, 11.2f, F2, C2, Z_S);
        WindowRun("In2_WinE", parent, 11.8f, 11.2f, F2, C2, Z_S);

        // 走廊墙：3 间教室（8.8~13.4 是楼梯厅，敞开）
        CorridorWall("In2_CW", parent, -X_IN, 8.8f, F2, C2, new[] { -13.2f, -4.4f, 4.4f });

        // 隔墙（楼梯井西侧不开墙，改栏杆，让楼梯厅能看到楼梯）
        foreach (float px in new[] { -8.8f, 0f, 8.8f })
            Box("In2_PartWall_" + px, parent, new Vector3(px, (F2 + C2) * 0.5f, (Z_ROOM + Z_N) * 0.5f),
                new Vector3(CORR_T, h, Z_N - Z_ROOM), "M_Interior");

        // 楼梯井西侧栏杆
        for (int i = 0; i <= 7; i++)
            Box("In2_RailW" + i, parent, new Vector3(STAIR_X + 0.05f, F2 + 0.55f, 25.4f + i * 0.9f),
                new Vector3(0.06f, 1.1f, 0.06f), "M_Metal");
        Box("In2_HandrailW", parent, new Vector3(STAIR_X + 0.05f, F2 + 1.12f, (25.4f + Z_N) * 0.5f),
            new Vector3(0.08f, 0.08f, Z_N - 25.4f), "M_Wood");

        // 走廊灯带
        for (int i = 0; i < 7; i++)
            Box("In2_CorrLight" + i, parent, new Vector3(-14.4f + i * 4.4f, C2 - 0.05f, 21.6f),
                new Vector3(2.0f, 0.06f, 0.42f), "M_Emissive");
        // 楼梯厅灯
        Box("In2_HallLight", parent, new Vector3(11.1f, C2 - 0.05f, 27.8f), new Vector3(2.4f, 0.06f, 0.5f), "M_Emissive");

        // 教室
        Classroom("In2_R0", parent, -13.2f, F2, C2, 3);
        Classroom("In2_R1", parent, -4.4f, F2, C2, 3);
        Classroom("In2_R2", parent, 4.4f, F2, C2, 3);

        // 楼梯厅：公告板 + 长椅（给二层一个能停下来的点）
        Box("In2_BoardFrame", parent, new Vector3(11.1f, F2 + 1.75f, Z_N - 0.02f), new Vector3(3.2f, 1.4f, 0.06f), "M_Wood");
        Box("In2_BoardFace", parent, new Vector3(11.1f, F2 + 1.75f, Z_N - 0.06f), new Vector3(3.0f, 1.2f, 0.04f), "M_Lawn");
        Box("In2_Bench", parent, new Vector3(11.1f, F2 + 0.24f, 25.2f), new Vector3(2.4f, 0.48f, 0.5f), "M_Wood");

        // 洞口南沿不再设栏杆：东道是二跑落地口，西道是上三层梯段的起步，
        // 两边都必须是开口。漏边由梯段本身挡住。
    }

    // ---------------------------------------------------------------- 三层

    /// <summary>
    /// 三层：走廊 + 3 间教室 + 阅览角。外立面原本就是 3 层窗（f=0..2），所以只需要补室内。
    /// 楼梯间上方只铺到 Z 25.6 —— 那是二跑（上三层的东道）的落地口，再往里就是井。
    /// </summary>
    static void BuildThirdFloor(Transform parent)
    {
        float h = C3 - F3;

        FloorSlab("In3_Floor", parent, -X_IN, STAIR_X, Z_S, Z_N, F3, "M_Concrete");
        FloorSlab("In3_FloorCorr", parent, STAIR_X, X_IN, Z_S, 25.4f, F3, "M_Concrete");
        FloorSlab("In3_EdgeW", parent, 13.4f, 13.7f, 25.4f, Z_N, F3, "M_Concrete");

        // 顶层天花，把楼梯井封在 13.9
        CeilingSlab("In3_Ceiling", parent, -X_IN, X_IN, Z_S, Z_N, C3, "M_Interior");

        WindowRun("In3_WinW", parent, -11.8f, 11.2f, F3, C3, Z_S);
        WindowRun("In3_WinE", parent, 11.8f, 11.2f, F3, C3, Z_S);

        CorridorWall("In3_CW", parent, -X_IN, 8.8f, F3, C3, new[] { -13.2f, -4.4f, 4.4f });

        foreach (float px in new[] { -8.8f, 0f, 8.8f })
            Box("In3_PartWall_" + px, parent, new Vector3(px, (F3 + C3) * 0.5f, (Z_ROOM + Z_N) * 0.5f),
                new Vector3(CORR_T, h, Z_N - Z_ROOM), "M_Interior");

        // 楼梯井西侧栏杆
        for (int i = 0; i <= 7; i++)
            Box("In3_RailW" + i, parent, new Vector3(STAIR_X + 0.05f, F3 + 0.55f, 25.4f + i * 0.9f),
                new Vector3(0.06f, 1.1f, 0.06f), "M_Metal");
        Box("In3_HandrailW", parent, new Vector3(STAIR_X + 0.05f, F3 + 1.12f, (25.4f + Z_N) * 0.5f),
            new Vector3(0.08f, 0.08f, Z_N - 25.4f), "M_Wood");

        // 洞口南沿只封西道（东道是二跑的落地口）
        for (int i = 0; i <= 3; i++)
            Box("In3_RailS" + i, parent, new Vector3(13.6f + i * 0.5f, F3 + 0.55f, 25.42f),
                new Vector3(0.06f, 1.1f, 0.06f), "M_Metal");
        Box("In3_HandrailS", parent, new Vector3(14.4f, F3 + 1.12f, 25.42f),
            new Vector3(1.6f, 0.08f, 0.08f), "M_Wood");

        for (int i = 0; i < 7; i++)
            Box("In3_CorrLight" + i, parent, new Vector3(-14.4f + i * 4.4f, C3 - 0.05f, 21.6f),
                new Vector3(2.0f, 0.06f, 0.42f), "M_Emissive");
        Box("In3_HallLight", parent, new Vector3(11.1f, C3 - 0.05f, 27.4f),
            new Vector3(2.4f, 0.06f, 0.5f), "M_Emissive");

        Classroom("In3_R0", parent, -13.2f, F3, C3, 3);
        Classroom("In3_R1", parent, -4.4f, F3, C3, 3);
        Classroom("In3_R2", parent, 4.4f, F3, C3, 3);

        BuildReadingCorner(parent, 11.1f);
    }

    /// <summary>三层 8.8~13.4 的开间做成阅览角：一排书架 + 两张阅览桌</summary>
    static void BuildReadingCorner(Transform parent, float cx)
    {
        // 书架本体（背板 + 3 层板 + 2 侧板）合成一个网格；书是"一排一个网格"，
        // 原来每层只有一块平板挡在前面，走近看是一面墙，不像书。
        var frame = GetMesh("ReadingShelfFrame", () => BuildBoxCluster(new[]
        {
            new BoxPart(0f, 1.00f, 0f, 1.40f, 2.00f, 0.06f),
            new BoxPart(-0.675f, 1.00f, -0.18f, 0.05f, 2.00f, 0.40f),
            new BoxPart( 0.675f, 1.00f, -0.18f, 0.05f, 2.00f, 0.40f),
            new BoxPart(0f, 0.36f, -0.18f, 1.40f, 0.05f, 0.40f),
            new BoxPart(0f, 0.96f, -0.18f, 1.40f, 0.05f, 0.40f),
            new BoxPart(0f, 1.56f, -0.18f, 1.40f, 0.05f, 0.40f),
        }));
        string[] bookMats = { "M_Brick", "M_Wall", "M_Lawn", "M_Glass" };

        for (int i = 0; i < 3; i++)
        {
            float x = cx + (i - 1) * 1.5f;
            PlaceCluster("In3_Shelf" + i, parent, new Vector3(x, F3, Z_N - 0.26f), Quaternion.identity,
                frame, "M_Wood", true);
            var row = BookRowMesh(8, 1.26f, 0.40f, 0.30f, i + 1);
            for (int s = 0; s < 3; s++)
                PlaceCluster("In3_Books" + i + "_" + s, parent,
                    new Vector3(x - 0.63f, F3 + 0.39f + s * 0.60f, Z_N - 0.44f), Quaternion.identity,
                    row, bookMats[(i + s) % bookMats.Length], false);
        }

        var deskBooks = DeskBooksMesh();
        for (int i = 0; i < 2; i++)
        {
            float x = cx + (i - 0.5f) * 1.55f;
            Box("In3_Table" + i, parent, new Vector3(x, F3 + 0.74f, 28.8f),
                new Vector3(1.35f, 0.08f, 0.85f), "M_Wood");
            Box("In3_TableLeg" + i, parent, new Vector3(x, F3 + 0.37f, 28.8f),
                new Vector3(0.12f, 0.74f, 0.55f), "M_Metal");
            // 桌上摊着几本书
            PlaceCluster("In3_TableBook" + i, parent, new Vector3(x - 0.22f, F3, 28.8f), Quaternion.identity,
                deskBooks, i == 0 ? "M_Wall" : "M_Brick", false);
            // 每桌 4 个座位（原来只有 2 个，看着像空桌）
            var stool = StoolMesh();
            for (int s = -1; s <= 1; s += 2)
            {
                PlaceCluster("In3_Stool" + i + "_" + s, parent, new Vector3(x, F3, 28.8f + s * 0.72f),
                    Quaternion.Euler(0, s * 8f, 0), stool, "M_Wood", false);
                PlaceCluster("In3_StoolA" + i + "_" + s, parent, new Vector3(x + s * 0.78f, F3, 28.8f),
                    Quaternion.Euler(0, 90f + s * 8f, 0), stool, "M_Wood", false);
            }
        }
        Box("In3_ReadLight", parent, new Vector3(cx, C3 - 0.07f, 28.8f),
            new Vector3(2.6f, 0.07f, 0.5f), "M_Emissive");
    }

    // ---------------------------------------------------------------- 校徽收集

    public const int CollectTotal = 8;

    /// <summary>
    /// 校徽收集：8 枚校徽分散在校园 8 个地标，玩家拾取后拿到门厅的陈列架前，
    /// 触发区里的 CampusCollect.lua 会把校徽收进对应槽位并点亮该格；集齐 8 枚点亮广场地标。
    ///
    /// 逻辑放在 Lua（SDK 唯一的运行时脚本通道），场景这边只负责几何与命名约定：
    ///   物品名 Collect_01..08 —— 拾取物是 SDK 的 DouyinPickupGlass 预制体实例
    ///   陈列架 CollectShelf，子物体 Slot_01..08，每格下挂 Glow（初始隐藏）
    ///   奖励  Plaza_Reward（初始隐藏）
    /// </summary>
    // ---------------------------------------------------------------- NPC（会走路、能搭话的同学）

    /// <summary>
    /// 一个 NPC 的定义。Path 是世界坐标路点，运行时 NPCTalk.lua 沿点循环走。
    /// 外观全部用现有材质拼（材质只剩 1 个额度，不能再为衣服调色开工）。
    /// </summary>
    class NpcSpec
    {
        public readonly string Name, Hair, HairMat, TopMat, BotMat, SkirtMat;
        public readonly float Speed, Scale;
        public readonly bool Bag;
        public readonly Vector3[] Path;

        public NpcSpec(string name, string hair, string hairMat, string topMat, string botMat,
                       float speed, float scale, bool bag, Vector3[] path, string skirtMat = null)
        {
            Name = name; Hair = hair; HairMat = hairMat; TopMat = topMat; BotMat = botMat;
            SkirtMat = skirtMat ?? botMat;
            Speed = speed; Scale = scale; Bag = bag; Path = path;
        }
    }

    static Vector3 P(float x, float z, float y = 0f) => new Vector3(x, y, z);

    static readonly NpcSpec[] NpcSpecs =
    {
        // 校门 → 广场 的樱花道，两个人对向走
        new NpcSpec("林小满", "long", "M_Wood", "M_Wall", "M_Metal", 1.15f, 0.97f, true,
            new[] { P(1.9f, -21.5f), P(1.9f, -11.0f), P(-2.1f, -11.0f), P(-2.1f, -21.5f) }, "M_Brick"),
        new NpcSpec("周亦辰", "short", "M_Metal", "M_Interior", "M_Glass", 1.30f, 1.04f, false,
            new[] { P(-2.6f, -19.0f), P(-2.6f, -7.5f), P(2.0f, -3.0f), P(6.2f, 1.2f), P(7.2f, 3.2f) }),

        // 广场外圈绕行（半径 12，避开 9m 处的四个花坛）
        new NpcSpec("苏晚", "long", "M_Metal", "M_Paving_A", "M_Metal", 0.95f, 0.99f, false,
            new[] { P(12f, 0f), P(8.49f, 8.49f), P(0f, 12f), P(-8.49f, 8.49f),
                    P(-12f, 0f), P(-8.49f, -8.49f), P(0f, -12f), P(8.49f, -8.49f) }, "M_Metal"),

        // 操场跑道中线（中心 -38,-2 / 15.25×9.75），12 个点
        new NpcSpec("陈野", "short", "M_Metal", "M_Wall", "M_Glass", 1.85f, 1.05f, false,
            new[]
            {
                P(-38f + 15.25f, -2f),  P(-38f + 13.21f, -2f + 4.88f),
                P(-38f + 7.63f, -2f + 8.44f),  P(-38f, -2f + 9.75f),
                P(-38f - 7.63f, -2f + 8.44f),  P(-38f - 13.21f, -2f + 4.88f),
                P(-38f - 15.25f, -2f),  P(-38f - 13.21f, -2f - 4.88f),
                P(-38f - 7.63f, -2f - 8.44f),  P(-38f, -2f - 9.75f),
                P(-38f + 7.63f, -2f - 8.44f),  P(-38f + 13.21f, -2f - 4.88f),
            }),

        // 教学楼台阶前（入口两侧 x ±5.6 之外，走的是 Path_Building 上）
        new NpcSpec("何老师", "bun", "M_Wood", "M_Interior", "M_Metal", 0.85f, 1.00f, false,
            new[] { P(7.0f, 15.5f), P(-7.0f, 15.5f) }),

        // 一层走廊（z 19.9~23.7，净宽 3.8）
        new NpcSpec("阿澄", "pony", "M_Brick", "M_Wall", "M_Metal", 1.20f, 0.96f, true,
            new[] { P(11f, 21.4f, F1), P(-12f, 21.4f, F1) }, "M_Brick"),

        // 校门内，门卫在主干道东沿来回。
        // 原来走 x=4.2 —— 正好压在 Hedge_E1 的 x 范围（4.15~5.05）里，人会插进绿篱
        new NpcSpec("老陈", "short", "M_Metal", "M_Glass", "M_Metal", 0.70f, 1.06f, false,
            // 门卫不巡逻，只在门内小范围踱步（1.4m）。原来从 -22 走到 -18.2 会走离出生点，
            // 玩家一睁眼就看到他已经晃到 4m 外了
            new[] { P(2.4f, -20.3f), P(2.4f, -18.9f) }),
    };

    static Font _npcFont;

    /// <summary>人形部件：立方体 + 指定材质，删掉碰撞体（NPC 不该挡住玩家），不参与静态合批</summary>
    static GameObject NpcBox(string name, Transform parent, Vector3 pos, Vector3 size, string mat)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = name;
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.transform.localScale = size;
        go.GetComponent<Renderer>().sharedMaterial = _mats[mat];
        var c = go.GetComponent<Collider>();
        if (c != null) UnityEngine.Object.DestroyImmediate(c);
        go.isStatic = false;                 // 会动的物体不能进静态合批，否则运行时位置被锁死
        return go;
    }

    /// <summary>摆动枢轴（肩/髋）：本身是空物体，子部件挂在它下面绕 x 轴转</summary>
    static Transform NpcPivot(string name, Transform parent, Vector3 pos)
    {
        var t = new GameObject(name).transform;
        t.SetParent(parent, false);
        t.localPosition = pos;
        t.gameObject.isStatic = false;
        return t;
    }

    /// <summary>
    /// 低多边形人形。身高约 1.66m × Scale，脚在 y=0。
    /// 结构：Model 下挂 Body/Skirt/Neck/Head/Hair + 左右臂枢轴 + 左右腿枢轴，
    /// 枢轴名固定（ArmL/ArmR/LegL/LegR），Lua 靠名字找它们做摆动。
    /// </summary>
    static void BuildNpcFigure(Transform root, NpcSpec spec)
    {
        var m = new GameObject("Model").transform;
        m.SetParent(root, false);
        m.localScale = Vector3.one * spec.Scale;

        // 躯干 / 肩 / 裙裤 / 脖子 / 头 / 头发
        // 尺寸按"肩宽 ≈ 身高 1/4"定：第一版宽 0.34、四肢细 0.085，远看就是两根竹竿
        NpcBox("Body", m, new Vector3(0f, 1.16f, 0f), new Vector3(0.38f, 0.44f, 0.22f), spec.TopMat);
        NpcBox("Shoulder", m, new Vector3(0f, 1.335f, 0f), new Vector3(0.435f, 0.10f, 0.235f), spec.TopMat);
        NpcBox("Skirt", m, new Vector3(0f, 0.90f, 0f), new Vector3(0.43f, 0.22f, 0.26f), spec.SkirtMat);
        NpcBox("Neck", m, new Vector3(0f, 1.415f, 0f), new Vector3(0.12f, 0.07f, 0.12f), "M_Interior");
        NpcBox("Head", m, new Vector3(0f, 1.56f, 0f), new Vector3(0.24f, 0.26f, 0.23f), "M_Interior");
        NpcBox("HairTop", m, new Vector3(0f, 1.685f, -0.008f), new Vector3(0.252f, 0.085f, 0.242f), spec.HairMat);
        NpcBox("HairBack", m, new Vector3(0f, 1.59f, -0.108f), new Vector3(0.242f, 0.21f, 0.05f), spec.HairMat);
        NpcBox("HairFringe", m, new Vector3(0f, 1.635f, 0.108f), new Vector3(0.244f, 0.075f, 0.028f), spec.HairMat);

        switch (spec.Hair)
        {
            case "long":
                NpcBox("HairLong", m, new Vector3(0.105f, 1.42f, -0.085f), new Vector3(0.11f, 0.36f, 0.11f), spec.HairMat);
                NpcBox("HairLong2", m, new Vector3(-0.105f, 1.42f, -0.085f), new Vector3(0.11f, 0.36f, 0.11f), spec.HairMat);
                break;
            case "pony":
                NpcBox("HairPony", m, new Vector3(0f, 1.45f, -0.165f), new Vector3(0.095f, 0.32f, 0.095f), spec.HairMat);
                NpcBox("HairTie", m, new Vector3(0f, 1.61f, -0.145f), new Vector3(0.055f, 0.055f, 0.055f), "M_Brick");
                break;
            case "bun":
                var bun = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                bun.name = "HairBun";
                bun.transform.SetParent(m, false);
                bun.transform.localPosition = new Vector3(0f, 1.735f, -0.08f);
                bun.transform.localScale = Vector3.one * 0.125f;
                bun.GetComponent<Renderer>().sharedMaterial = _mats[spec.HairMat];
                UnityEngine.Object.DestroyImmediate(bun.GetComponent<Collider>());
                bun.isStatic = false;
                break;
        }

        // 手臂：枢轴在肩（y 1.26），部件往下伸 0.44
        foreach (int s in new[] { -1, 1 })
        {
            var arm = NpcPivot(s < 0 ? "ArmL" : "ArmR", m, new Vector3(s * 0.255f, 1.315f, 0f));
            NpcBox("ArmBox", arm, new Vector3(0f, -0.21f, 0f), new Vector3(0.10f, 0.42f, 0.11f), spec.TopMat);
            NpcBox("ArmHand", arm, new Vector3(0f, -0.44f, 0f), new Vector3(0.10f, 0.085f, 0.10f), "M_Interior");
        }

        // 腿：枢轴在髋（y 0.72），部件往下伸 0.68
        foreach (int s in new[] { -1, 1 })
        {
            var leg = NpcPivot(s < 0 ? "LegL" : "LegR", m, new Vector3(s * 0.10f, 0.80f, 0f));
            NpcBox("LegBox", leg, new Vector3(0f, -0.38f, 0f), new Vector3(0.132f, 0.76f, 0.15f), spec.BotMat);
            NpcBox("Shoe", leg, new Vector3(0f, -0.775f, 0.025f), new Vector3(0.155f, 0.058f, 0.205f), "M_Metal");
        }

        if (spec.Bag)
            NpcBox("Bag", m, new Vector3(0f, 1.15f, -0.175f), new Vector3(0.28f, 0.31f, 0.14f), "M_Wood");
    }

    // ---------------------------------------------------------------- 女主角：黄思诚

    /// <summary>待机点：广场南口，玩家从校门进来抬头就能看见她（正对主干道）</summary>
    static readonly Vector3 StarHome = new Vector3(1.5f, 0f, -5.8f);

    /// <summary>
    /// 黄思诚。和别的 NPC 共用 ArmL/ArmR/LegL/LegR 的骨架命名（Lua 靠名字找四肢），
    /// 但整个轮廓是重新搭的：
    ///   · 腰线抬到 1.06（普通 NPC 裙摆在 0.90），同样的身高，腿看起来长一截；
    ///   · 短上衣 + 露腰 10cm，下面接高腰阔腿裤，脚口比大腿还宽，走起来有摆动感；
    ///   · 厚底鞋、头顶架墨镜、choker、圈形耳环、斜挎链 + 腰包。
    /// 没有做任何体型夸张 —— 她是"会穿、敢穿、站得住场"，不是靠瘦或靠露。
    /// </summary>
    static void BuildStarFigure(Transform root)
    {
        var m = new GameObject("Model").transform;
        m.SetParent(root, false);

        // ---- 下半身：阔腿裤（脚口比大腿宽）+ 粉色厚底鞋。
        // 两条腿的轴距拉到 ±0.12、脚口收到 0.20，中间留 4cm 缝 —— 否则两条深色裤腿会糊成一根柱子
        foreach (int s in new[] { -1, 1 })
        {
            var leg = NpcPivot(s < 0 ? "LegL" : "LegR", m, new Vector3(s * 0.12f, 0.88f, 0f));
            NpcBox("Thigh", leg, new Vector3(0f, -0.17f, 0f), new Vector3(0.17f, 0.34f, 0.19f), "M_Denim");
            // 裤脚到 0.16 就收，把 10cm 让给鞋 —— 原来裤脚盖到 0.135，厚底鞋只剩一条白线
            NpcBox("Flare", leg, new Vector3(0f, -0.53f, 0f), new Vector3(0.20f, 0.38f, 0.215f), "M_Denim");
            NpcBox("Shoe", leg, new Vector3(0f, -0.775f, 0.03f), new Vector3(0.205f, 0.10f, 0.30f), "M_Interior");
            NpcBox("Sole", leg, new Vector3(0f, -0.8475f, 0.03f), new Vector3(0.218f, 0.045f, 0.315f), "M_StarPink");
            // 裤腿外侧的白色缝线：两条同色阔腿裤并在一起时，远看会糊成一根柱子，
            // 这条 6mm 的侧缝就是让"两条腿"能读出来的分界线（顺便也是牛仔的细节）
            NpcBox("Seam", leg, new Vector3(s * 0.1005f, -0.52f, 0f), new Vector3(0.008f, 0.36f, 0.075f), "M_Interior");
        }

        // ---- 腰腹：露腰一段 + 粉色腰带。短上衣必须有腰线，没有腰线就是普通 T 恤
        NpcBox("Belt", m, new Vector3(0f, 0.925f, 0f), new Vector3(0.315f, 0.05f, 0.205f), "M_Denim");
        NpcBox("Waist", m, new Vector3(0f, 0.985f, 0f), new Vector3(0.30f, 0.065f, 0.18f), "M_Interior");

        // ---- 上衣：白底 + 粉色主体，两段拼接。纯色块在微缩尺度下没有"设计"，拼色才有 Y2K 的味道
        NpcBox("TopWhite", m, new Vector3(0f, 1.075f, 0f), new Vector3(0.375f, 0.115f, 0.222f), "M_Wall");
        NpcBox("CropTop", m, new Vector3(0f, 1.26f, 0f), new Vector3(0.395f, 0.255f, 0.228f), "M_StarPink");
        NpcBox("Shoulder", m, new Vector3(0f, 1.415f, 0f), new Vector3(0.435f, 0.075f, 0.232f), "M_StarPink");

        // ---- 颈 / 颈圈 / 头
        NpcBox("Neck", m, new Vector3(0f, 1.485f, 0f), new Vector3(0.115f, 0.07f, 0.115f), "M_Interior");
        NpcBox("Choker", m, new Vector3(0f, 1.515f, 0f), new Vector3(0.128f, 0.028f, 0.128f), "M_Metal");
        NpcBox("Head", m, new Vector3(0f, 1.625f, 0f), new Vector3(0.235f, 0.245f, 0.225f), "M_Interior");

        // 五官：只有这几毫米，但没有它们，近景就是一块空白皮肤（第一版就是这样，像戴了面具）
        foreach (int s in new[] { -1, 1 })
        {
            NpcBox("Eye", m, new Vector3(s * 0.055f, 1.616f, 0.114f), new Vector3(0.036f, 0.026f, 0.008f), "M_Metal");
            NpcBox("Brow", m, new Vector3(s * 0.056f, 1.652f, 0.113f), new Vector3(0.048f, 0.012f, 0.008f), "M_Metal");
        }
        NpcBox("Mouth", m, new Vector3(0f, 1.566f, 0.114f), new Vector3(0.042f, 0.012f, 0.008f), "M_Brick");

        // ---- 头发：中长 + 两缕玫粉挑染（挑染露在侧发外侧，否则等于没做）
        NpcBox("HairTop", m, new Vector3(0f, 1.75f, -0.008f), new Vector3(0.247f, 0.08f, 0.238f), "M_Metal");
        NpcBox("HairBack", m, new Vector3(0f, 1.665f, -0.105f), new Vector3(0.24f, 0.20f, 0.05f), "M_Metal");
        NpcBox("HairFringe", m, new Vector3(0f, 1.70f, 0.098f), new Vector3(0.24f, 0.072f, 0.03f), "M_Metal");
        foreach (int s in new[] { -1, 1 })
        {
            NpcBox("HairSide", m, new Vector3(s * 0.114f, 1.565f, -0.015f), new Vector3(0.07f, 0.27f, 0.10f), "M_Metal");
            NpcBox("HairStreak", m, new Vector3(s * 0.146f, 1.555f, 0.015f), new Vector3(0.025f, 0.28f, 0.032f), "M_StarPink");
            var ear = Sphere("Earring", m, new Vector3(s * 0.124f, 1.605f, 0f), 0.03f, "M_StarPink");
            ear.isStatic = false;   // Sphere() 默认 isStatic，挂在会动的人身上必须关
        }

        // ---- 墨镜推到头顶。必须**高过发顶**（发顶 1.79），否则会糊进头发里变成一顶黑帽子
        NpcBox("GlassesFrame", m, new Vector3(0f, 1.846f, 0.045f), new Vector3(0.25f, 0.038f, 0.028f), "M_Wall");
        foreach (int s in new[] { -1, 1 })
            NpcBox("GlassesLens", m, new Vector3(s * 0.061f, 1.821f, 0.10f), new Vector3(0.10f, 0.046f, 0.012f), "M_Glass");

        // ---- 手臂：粉色短袖口 + 露出的手臂
        foreach (int s in new[] { -1, 1 })
        {
            var arm = NpcPivot(s < 0 ? "ArmL" : "ArmR", m, new Vector3(s * 0.222f, 1.40f, 0f));
            // 袖口盖到肩下 13cm，把"肩→上臂"这段接起来；不然粉色躯干两侧直接挂着两条肤色，像没穿上衣
            NpcBox("Sleeve", arm, new Vector3(0f, -0.065f, 0f), new Vector3(0.098f, 0.135f, 0.118f), "M_StarPink");
            NpcBox("ArmBox", arm, new Vector3(0f, -0.235f, 0f), new Vector3(0.078f, 0.33f, 0.095f), "M_Interior");
            NpcBox("ArmHand", arm, new Vector3(0f, -0.425f, 0f), new Vector3(0.08f, 0.075f, 0.09f), "M_Interior");
        }

        // ---- 斜挎链（右肩 → 左腰）+ 腰包。带子收窄到 3cm，端点落在肩线和腰线上，不悬空
        var strap = NpcBox("BagStrap", m, new Vector3(0.012f, 1.20f, 0.118f),
            new Vector3(0.028f, 0.375f, 0.022f), "M_Metal");
        strap.transform.localRotation = Quaternion.Euler(0f, 0f, -37f);
        NpcBox("Bag", m, new Vector3(-0.19f, 1.06f, 0.02f), new Vector3(0.11f, 0.15f, 0.095f), "M_Denim");
        NpcBox("BagClasp", m, new Vector3(-0.19f, 1.06f, 0.072f), new Vector3(0.082f, 0.04f, 0.012f), "M_StarPink");

        // 静态初始姿态：右手叉腰。角度不能太大 —— -34° 时手会甩到身体外面，看着像在推人
        // 叉腰：右臂向**内**收（z 正角）才贴得住胯；向外张只会把手甩到身体外面悬空
        var armR = m.Find("ArmR");
        if (armR != null) armR.localRotation = Quaternion.Euler(-12f, 0f, 9f);
        // z 必须是正角（向内）。给负角会让手臂向外张开，和躯干之间裂出一道缝，远看像企鹅
        var armL = m.Find("ArmL");
        if (armL != null) armL.localRotation = Quaternion.Euler(-3f, 0f, 5f);
    }

    /// <summary>生成女主角：人形 + 名牌/台词 + 待机点，挂 CampusStar.lua</summary>
    static void BuildStar(Transform parent, Dictionary<string, int> nameCells, Dictionary<string, int[]> lineCellsByNpc, Dictionary<string, int[]> lineTiersByNpc, int promptCell)
    {
        const string id = "NPC_08";
        var host = CreateNpcHost(parent, id, StarHome, "Assets/Campus/Lua/CampusStar.lua");
        if (host == null) return;

        BuildStarFigure(host.transform);

        int nameCell = nameCells.ContainsKey(id) ? nameCells[id] : 0;
        var cells = lineCellsByNpc.ContainsKey(id) ? lineCellsByNpc[id] : new[] { 0 };
        var tiers = (lineTiersByNpc != null && lineTiersByNpc.ContainsKey(id)) ? lineTiersByNpc[id] : null;
        BuildNpcLabel(host.transform, nameCell, cells, tiers, id, promptCell);

        // 待机点：Lua 用 Path/Waypoint_01 作为"回家"的坐标（她不像别人那样沿路点巡逻）
        var pathRoot = new GameObject("Path").transform;
        pathRoot.SetParent(host.transform, false);
        var wp = new GameObject("Waypoint_01").transform;
        wp.SetParent(pathRoot, false);
        wp.position = StarHome;

        Debug.Log("[Campus] 黄思诚 = NPC_08 @ " + StarHome + "，台词 " + cells.Length + " 句");
    }

    /// <summary>台词图集里第 index 格的 UV（4 列 × 16 行，索引从左上往右下）</summary>
    static Rect NpcCellUV(int index)
    {
        const int cols = 4, rows = 16;
        int col = index % cols, row = index / cols;
        float cw = 1f / cols, ch = 1f / rows;
        float u0 = col * cw, v1 = 1f - row * ch;
        return new Rect(u0, v1 - ch, cw, ch);
    }

    /// <summary>一格名字/台词的 quad：1.0 × 0.25 m（4:1），按格号缓存复用</summary>
    static Mesh NpcCellMesh(int index)
        => GetMesh("NpcCell_" + index, () => BuildPosterQuad(1f, 0.25f, NpcCellUV(index)));

    /// <summary>
    /// 头顶名牌 + 对话气泡。用"贴图 quad"而不是 TextMesh：
    /// TextMesh 走 GUI/Text Shader，在 URP 下（尤其是离屏渲染）根本不出现；
    /// 而 quad + World_Lit 和校名牌是同一条已验证的管线，截图和真机都能看到。
    /// 代价是台词要预先画进图集 —— 所以每句话一个 quad，Lua 只负责切显隐。
    /// </summary>
    static void BuildNpcLabel(Transform root, int nameCell, int[] lineCells, int[] lineTiers = null, string npcId = null, int promptCell = -1)
    {
        var pivot = new GameObject("Label").transform;
        pivot.SetParent(root, false);
        pivot.localPosition = new Vector3(0f, 1.98f, 0f);
        pivot.gameObject.isStatic = false;

        // 名牌：一块小纸片，常显。底边贴在 1.93，顶到 2.17
        var nameGo = new GameObject("NameQuad");
        nameGo.transform.SetParent(pivot, false);
        nameGo.transform.localPosition = new Vector3(0f, 0.01f, 0f);
        nameGo.transform.localScale = new Vector3(0.76f, 0.76f, 1f);
        nameGo.AddComponent<MeshFilter>().sharedMesh = NpcCellMesh(nameCell);
        var nmr = nameGo.AddComponent<MeshRenderer>();
        nmr.sharedMaterial = _mats["M_NpcLine"];
        nmr.shadowCastingMode = ShadowCastingMode.Off;
        nmr.receiveShadows = false;
        nameGo.isStatic = false;

        // 气泡：一句话一个 quad，默认全关，Lua 切"开哪一个"
        var bubble = new GameObject("Bubble").transform;
        bubble.SetParent(pivot, false);
        bubble.localPosition = new Vector3(0f, 0.30f, 0f);
        bubble.gameObject.isStatic = false;

        for (int i = 0; i < lineCells.Length; i++)
        {
            // 有分档信息时把档号编进名字（Line_2_09），CampusStar.lua 靠它分组；
            // 没有就沿用旧的 Line_09，NPC_01..07 完全不受影响。
            string quadName = (lineTiers != null && i < lineTiers.Length)
                ? "Line_" + lineTiers[i] + "_" + (i + 1).ToString("00")
                : "Line_" + (i + 1).ToString("00");
            var go = new GameObject(quadName);
            go.transform.SetParent(bubble, false);
            go.transform.localPosition = Vector3.zero;
            go.transform.localScale = new Vector3(1.26f, 1.26f, 1f);
            go.AddComponent<MeshFilter>().sharedMesh = NpcCellMesh(lineCells[i]);
            var mr = go.AddComponent<MeshRenderer>();
            mr.sharedMaterial = _mats["M_NpcLine"];
            mr.shadowCastingMode = ShadowCastingMode.Off;
            mr.receiveShadows = false;
            go.isStatic = false;

            // 台词配音：AudioSource 直接挂在 quad 上。气泡隐藏（SetActive(false)）时
            // Unity 会自动停掉它身上的声音 —— "话没说完人走开了"正好符合直觉，
            // 不需要 Lua 管停。文件按 NPC 分目录：Voice/<npcId>/<quadName>.ogg
            // —— 不同 NPC 的 quad 名会重名（都是 Line_01...），扁平命名必撞车。
            if (npcId != null)
            {
                var vclip = LoadVoiceClip(npcId + "/" + quadName);
                if (vclip != null)
                {
                    var vs = go.AddComponent<AudioSource>();
                    vs.clip = vclip;
                    vs.playOnAwake = false;
                    vs.loop = false;
                    vs.spatialBlend = 0f;   // 2D：跟着 NPC 走，不随距离衰减
                    vs.volume = 0.9f;
                }
            }
        }
        // 按键提示：气泡下方的小纸条「按 F 继续 ▼」，Lua 在对话可推进时点亮。
        // 初始隐藏；复用台词图集的格子，不占新材质。
        if (promptCell >= 0)
        {
            var pg = new GameObject("Prompt_F");
            pg.transform.SetParent(bubble, false);
            pg.transform.localPosition = new Vector3(0f, -0.55f, 0f);
            pg.transform.localScale = new Vector3(0.72f, 0.72f, 1f);
            pg.AddComponent<MeshFilter>().sharedMesh = NpcCellMesh(promptCell);
            var pmr = pg.AddComponent<MeshRenderer>();
            pmr.sharedMaterial = _mats["M_NpcLine"];
            pmr.shadowCastingMode = ShadowCastingMode.Off;
            pmr.receiveShadows = false;
            pg.isStatic = false;
            pg.SetActive(false);
        }
        bubble.gameObject.SetActive(false);
    }

    /// <summary>语音片段：Voice/<NPC>/<quad>.ogg|.wav|.mp3。短语音不设 Streaming，走默认导入。</summary>
    static AudioClip LoadVoiceClip(string relPath)
    {
        foreach (var ext in new[] { ".ogg", ".wav", ".mp3" })
        {
            var path = "Assets/Campus/Audio/Voice/" + relPath + ext;
            if (!File.Exists(path)) continue;
            return AssetDatabase.LoadAssetAtPath<AudioClip>(path);
        }
        return null;
    }

    /// <summary>
    /// 生成台词配音清单 Assets/Campus/Audio/Voice/_manifest.txt：
    /// 每行「NPC/文件名(不含扩展名)|台词文本」，配音的人照着这个列表做文件。
    /// 命名必须与 BuildNpcLabel 生成 quad 的规则完全一致 —— 清单和 quad 名字对不上，
    /// 配了音也对不上嘴。注意两个调用点的不对称：只有 BuildStar 给 NPC_08 传档位，
    /// 其余 NPC 走扁平 Line_01 —— 这里必须复刻同样的规则，否则清单全是错名。
    /// </summary>
    static void WriteVoiceManifest(Dictionary<string, string[]> lineTexts,
                                   Dictionary<string, int[]> lineTiersByNpc)
    {
        if (lineTexts == null || lineTexts.Count == 0) return;

        var dir = "Assets/Campus/Audio/Voice";
        Directory.CreateDirectory(dir);
        var sb = new StringBuilder();
        sb.AppendLine("# 台词配音清单：把配音存成 Voice/<NPC>/文件名.ogg/.wav/.mp3，重建场景即生效");
        sb.AppendLine("# 目前只有 NPC_08（黄思诚）的台词会播配音；其他 NPC 配了音源也不会响");
        sb.AppendLine("# 格式：NPC编号/文件名|台词文本");
        foreach (var kv in lineTexts)
        {
            var texts = kv.Value;
            // 与 BuildNPCs（不传档位）/ BuildStar（只给 NPC_08 传）的调用方式保持一致
            var tiers = (kv.Key == "NPC_08" && lineTiersByNpc.ContainsKey(kv.Key))
                ? lineTiersByNpc[kv.Key] : null;
            for (int i = 0; i < texts.Length; i++)
            {
                string quadName = (tiers != null && i < tiers.Length)
                    ? "Line_" + tiers[i] + "_" + (i + 1).ToString("00")
                    : "Line_" + (i + 1).ToString("00");
                sb.AppendLine(kv.Key + "/" + quadName + "|" + texts[i]);
            }
        }
        File.WriteAllText(dir + "/_manifest.txt", sb.ToString(), new UTF8Encoding(false));
        Debug.Log("[Campus] 台词配音清单已更新：" + dir + "/_manifest.txt");
    }

    /// <summary>
    /// 读 NpcLines.txt：名字格号 + 每人的台词格号 + 每句的档号。
    /// 格号必须和图集脚本铺的顺序一致（先名字、后台词出现顺序）。
    /// 档号来自 kind：L → 1，L2/L3/L4 → 2/3/4（黄思诚好感度分档用）。
    /// </summary>
    static void LoadNpcLineCells(out Dictionary<string, int> nameCells,
                                 out Dictionary<string, int[]> lineCells,
                                 out Dictionary<string, int[]> lineTiers,
                                 out Dictionary<string, string[]> lineTexts,
                                 out int promptCell)
    {
        nameCells = new Dictionary<string, int>();
        lineCells = new Dictionary<string, int[]>();
        lineTiers = new Dictionary<string, int[]>();
        lineTexts = new Dictionary<string, string[]>();
        promptCell = -1;

        const string path = "Assets/Campus/NpcLines.txt";
        if (!File.Exists(path))
        {
            Debug.LogWarning("[Campus] 缺少 " + path);
            return;
        }

        var nameOrder = new List<string>();
        var ids = new List<string>();        // 每句台词属于谁，按文件出现顺序
        var tierOfLine = new List<int>();    // 与 ids 一一对应
        var textOfLine = new List<string>(); // 与 ids 一一对应（配音清单用）
        string promptText = null;            // kind=P 的按键提示（全 NPC 共用一格）

        foreach (var raw in File.ReadAllLines(path))
        {
            var line = raw.Trim();
            if (line.Length == 0 || line.StartsWith("#")) continue;
            var parts = line.Split('|');
            if (parts.Length != 3) continue;
            string who = parts[0].Trim(), kind = parts[1].Trim();
            if (kind == "N") { nameOrder.Add(who); }
            else if (kind == "P") { promptText = parts[2].Trim(); }
            else if (kind.StartsWith("L"))
            {
                int t = 1;
                if (kind.Length > 1) int.TryParse(kind.Substring(1), out t);
                if (t < 1) t = 1;
                ids.Add(who);
                tierOfLine.Add(t);
                textOfLine.Add(parts[2].Trim());
            }
        }

        // 格位顺序与图集脚本一致：先名字、后台词、最后提示
        int cell = 0;
        foreach (var who in nameOrder) nameCells[who] = cell++;

        int k = 0;
        foreach (var who in ids)
        {
            int t = tierOfLine[k++];
            string txt = textOfLine[k - 1];
            if (lineCells.ContainsKey(who))
            {
                var old = lineCells[who];
                var grown = new int[old.Length + 1];
                old.CopyTo(grown, 0);
                grown[old.Length] = cell++;
                lineCells[who] = grown;

                var oldT = lineTiers[who];
                var grownT = new int[oldT.Length + 1];
                oldT.CopyTo(grownT, 0);
                grownT[oldT.Length] = t;
                lineTiers[who] = grownT;

                var oldX = lineTexts[who];
                var grownX = new string[oldX.Length + 1];
                oldX.CopyTo(grownX, 0);
                grownX[oldX.Length] = txt;
                lineTexts[who] = grownX;
            }
            else
            {
                lineCells[who] = new[] { cell++ };
                lineTiers[who] = new[] { t };
                lineTexts[who] = new[] { txt };
            }
        }

        if (promptText != null) promptCell = cell++;

        // 兜底：图集只有 64 格，越界就全指回第 0 格（宁可显示错字也不要空 mesh）
        foreach (var kv in nameCells.ToArray())
            if (kv.Value >= 64) nameCells[kv.Key] = 0;
        foreach (var kv in lineCells.ToArray())
            for (int i = 0; i < kv.Value.Length; i++)
                if (kv.Value[i] >= 64) kv.Value[i] = 0;
        if (promptCell >= 64) promptCell = 0;
    }


    /// <summary>
    /// NPC 主体：用 SDK 拾取预制体当宿主（它有 NetGUID + DouyinScript，直接 new 一个未必齐），
    /// 解包后清空子物体与碰撞体，把人形挂上去，再把脚本换成 NPCTalk.lua。
    /// </summary>
    /// <summary>
    /// 造一个 NPC 宿主：用 SDK 拾取预制体当壳（它有 NetGUID + DouyinScript，
    /// 直接 new 一个未必齐），解包后清空子物体与碰撞体，再挂上指定的 lua。
    /// </summary>
    static GameObject CreateNpcHost(Transform parent, string id, Vector3 pos, string luaPath)
    {
        const string pickupPath = "Assets/DouyinVCreateSDK/World/Examples/DouyinPickup/DouyinPickupGlass.prefab";
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(pickupPath);
        var lua = AssetDatabase.LoadMainAssetAtPath(luaPath);
        if (prefab == null || lua == null)
        {
            Debug.LogWarning("[Campus] " + id + " 未生成：prefab=" + (prefab != null) + " lua=" + (lua != null));
            return null;
        }

        var host = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
        host.name = id;
        host.transform.position = pos;
        PrefabUtility.UnpackPrefabInstance(host, PrefabUnpackMode.Completely, InteractionMode.AutomatedAction);

        // 清掉拾取物自带的玻璃体 / 碰撞 / 刚体自重
        foreach (Transform child in host.transform.Cast<Transform>().ToArray())
            UnityEngine.Object.DestroyImmediate(child.gameObject);
        var mf = host.GetComponent<MeshFilter>();
        if (mf != null) UnityEngine.Object.DestroyImmediate(mf);
        var mr = host.GetComponent<MeshRenderer>();
        if (mr != null) UnityEngine.Object.DestroyImmediate(mr);
        foreach (var c in host.GetComponents<Collider>())
            UnityEngine.Object.DestroyImmediate(c);
        var rb = host.GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.useGravity = false;
            rb.isKinematic = true;              // 位置由 Lua 推，别让物理插手
            rb.constraints = RigidbodyConstraints.FreezeAll;
        }
        host.isStatic = false;

        var script = host.GetComponent(FindType("DouyinScript"));
        if (script == null) { Debug.LogWarning("[Campus] " + id + " 缺少 DouyinScript"); return host; }
        var so = new SerializedObject(script);
        SetProp(so, "ScriptAsset", lua);
        var arr = so.FindProperty("ParaLuaBindingData");
        if (arr != null) arr.arraySize = 0;
        SetBool(so, "IsManualedVar", true);
        SetBool(so, "autoUpdate", true);        // 行走/说话全靠 Update
        so.ApplyModifiedPropertiesWithoutUndo();
        EditorUtility.SetDirty(script);
        return host;
    }

    static void BuildNPCs(Transform parent)
    {
        LoadNpcLineCells(out var nameCells, out var lineCellsByNpc, out var lineTiersByNpc,
                         out var lineTextsByNpc, out var promptCell);

        for (int i = 0; i < NpcSpecs.Length; i++)
        {
            var spec = NpcSpecs[i];
            string id = "NPC_" + (i + 1).ToString("00");

            var host = CreateNpcHost(parent, id, spec.Path[0], "Assets/Campus/Lua/NPCTalk.lua");
            if (host == null) continue;

            BuildNpcFigure(host.transform, spec);
            int nameCell = nameCells.ContainsKey(id) ? nameCells[id] : 0;
            var lineCells = lineCellsByNpc.ContainsKey(id) ? lineCellsByNpc[id] : new[] { 0 };
            BuildNpcLabel(host.transform, nameCell, lineCells, null, id, promptCell);

            // 路点：空物体存世界坐标，Lua 直接读 position
            var pathRoot = new GameObject("Path").transform;
            pathRoot.SetParent(host.transform, false);
            for (int k = 0; k < spec.Path.Length; k++)
            {
                var wp = new GameObject("Waypoint_" + (k + 1).ToString("00")).transform;
                wp.SetParent(pathRoot, false);
                wp.position = spec.Path[k];
            }

        }
        Debug.Log("[Campus] NPC = " + NpcSpecs.Length);

        BuildStar(parent, nameCells, lineCellsByNpc, lineTiersByNpc, promptCell);

        // 台词配音清单：quad 名 ↔ 台词文本。配音的人照着这个列表提供文件。
        WriteVoiceManifest(lineTextsByNpc, lineTiersByNpc);
    }

    /// <summary>
    /// 存档系统：两个对象。
    ///   1) 官方 DouyinDataStore 预制体 —— 它身上有 NetGUID（网络对象），必须实例化，
    ///      自己 new 一个空物体挂 DouyinScript 未必能注册到网络层。里面是 3 个 manager
    ///      脚本（DataStore / PlayerDataStore / PetDataStore），Pet 那个没有宠物就什么都不做。
    ///   2) CampusSave 宿主 —— 我们自己的业务层（内存缓存 + 串行化 + 节流 + 就绪回调），
    ///      复用 CreateNpcHost 造壳，因为 DouyinScript 的 ScriptAsset / autoUpdate
    ///      这些序列化字段只有走那条路才设得对。
    /// </summary>
    static void BuildDataStore(Transform parent)
    {
        const string prefabPath = "Assets/DouyinVCreateSDK/World/Examples/DouyinDataStore/DouyinDataStore.prefab";
        const string saveLua = "Assets/Campus/Lua/CampusSave.lua";

        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
        if (prefab == null)
        {
            Debug.LogWarning("[Campus] 缺少 " + prefabPath + "，存档不可用（玩法仍可跑，只是不保存）");
        }
        else
        {
            var store = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
            store.name = "CampusDataStore";
            store.transform.localPosition = Vector3.zero;
            var mgr = FindType("DouyinScript");
            int n = 0;
            if (mgr != null)
            {
                foreach (var s in store.GetComponents(mgr)) n++;
            }
            Debug.Log("[Campus] 存档 DataStore 就位，manager 脚本 " + n + " 个");
        }

        var host = CreateNpcHost(parent, "CampusSave", Vector3.zero, saveLua);
        if (host != null)
        {
            // 存档宿主只是挂脚本用的，别留刚体参与物理
            var rb = host.GetComponent<Rigidbody>();
            if (rb != null) UnityEngine.Object.DestroyImmediate(rb);
            Debug.Log("[Campus] 存档业务宿主 CampusSave 已建成");
        }
    }

    /// <summary>
    /// BGM / 音效。音乐文件由作者提供 —— 平台审核拒收未授权音乐，这里只挂原创音频。
    /// 约定：文件放进 Assets/Campus/Audio/ 并按名字命名（ogg/wav/mp3 任一），重建即生效：
    ///   BGM_Ambient   进世界日常 loop（playOnAwake + 循环 + 2D）
    ///   BGM_Ceremony  毕业典礼主题（不循环；Lua 开演时播，并把日常 BGM 音量压低）
    ///   SFX_Firework_Close / _Far   烟花声床（15s 多响录音，开演各播一次，一近一远）
    /// 缺文件就跳过对应音源 —— 宁可没有，也不引用空 clip。
    ///
    /// AudioListener：本场景和 SDK 全部 prefab 里都没有；玩家相机是引擎运行时生成的，
    /// 有没有 listener 无法本地验证。挂一个兜底 —— 双 listener 只是一条警告、且 2D 音
    /// 不受影响，0 listener 是彻底静音，两害相权取其轻。真机若报双 listener 就删这里。
    /// </summary>
    static void BuildAudio(Transform parent)
    {
        var root = new GameObject("CampusAudio");
        root.transform.SetParent(parent, false);
        root.transform.localPosition = Vector3.zero;
        root.AddComponent<AudioListener>();
        Debug.Log("[Campus] 音频根节点 CampusAudio 已建成（含兜底 AudioListener）");

        BuildAudioSource(root.transform, "BGM_Ambient", loop: true, awake: true, vol: 0.55f);
        BuildAudioSource(root.transform, "BGM_Ceremony", loop: false, awake: false, vol: 0.80f);
        // 烟花声床：两个都是 15s 的多响烟花秀录音（不是单响），典礼开演各播一次。
        // 近景清脆 0.85 / 远景闷响 0.5 —— 一近一远叠出纵深。
        BuildAudioSource(root.transform, "SFX_Firework_Close", loop: false, awake: false, vol: 0.85f);
        BuildAudioSource(root.transform, "SFX_Firework_Far", loop: false, awake: false, vol: 0.50f);
    }

    static void BuildAudioSource(Transform root, string name, bool loop, bool awake, float vol)
    {
        var clip = LoadCampusClip(name);
        if (clip == null)
        {
            Debug.LogWarning("[Campus] 缺少音频 " + name +
                "（Assets/Campus/Audio/ 下没有同名 ogg/wav/mp3），跳过该音源");
            return;
        }

        var go = new GameObject(name);
        go.transform.SetParent(root, false);
        go.transform.localPosition = Vector3.zero;
        var src = go.AddComponent<AudioSource>();
        src.clip = clip;
        src.loop = loop;
        src.playOnAwake = awake;
        src.volume = vol;
        src.spatialBlend = 0f;   // 2D：BGM 与全局音效不随距离衰减，也不依赖 listener 位置
        Debug.Log("[Campus] 音源 " + name + " 就位（" + clip.name +
            ", loop=" + loop + ", playOnAwake=" + awake + "）");
    }

    static AudioClip LoadCampusClip(string baseName)
    {
        foreach (var ext in new[] { ".ogg", ".wav", ".mp3" })
        {
            var path = "Assets/Campus/Audio/" + baseName + ext;
            if (!System.IO.File.Exists(path)) continue;

            // 长音频走 Streaming：手机内存紧（<1400MB 预算），整段解压进内存不划算。
            // BGM 和 15s 的烟花声床都算长音频。
            // ⚠️ 属性叫 defaultSampleSettings（不是 defaultSettings），且是结构体 ——
            //    不能直接 imp.defaultSampleSettings.loadType=x（CS1612：属性返回副本）。
            //    要取出来改完再存回去。
            if (baseName.StartsWith("BGM_") || baseName.StartsWith("SFX_Firework"))
            {
                var imp = AssetImporter.GetAtPath(path) as AudioImporter;
                if (imp != null && imp.defaultSampleSettings.loadType != AudioClipLoadType.Streaming)
                {
                    var s = imp.defaultSampleSettings;
                    s.loadType = AudioClipLoadType.Streaming;
                    imp.defaultSampleSettings = s;
                    imp.SaveAndReimport();
                }
            }
            return AssetDatabase.LoadAssetAtPath<AudioClip>(path);
        }
        return null;
    }

    /// <summary>
    /// 毕业典礼的烟花节点池：1 个升空弹 + 12 个爆散火星，**循环复用**。
    ///
    /// 为什么不给 4 发各配一套：4×13=52 个节点，多出来的 39 个只占 Renderer 永远用不上。
    /// 这里 13 个就是全部，每发重新给它们定位置和初速度。
    ///
    /// ⚠️ 父节点 Fireworks 必须常驻 active。Lua 里 GameObject.Find **不返回** inactive 物体，
    ///    所以只能先 Find 到 active 的父节点，再 Transform:Find 拿隐藏的子物体
    ///    （Transform.Find 是能找到 inactive 子物体的）。
    ///
    /// 不占材质额度：全部复用 M_Glow（VFX_Add01 加法），网格是 80 面 icosphere。
    /// 火星用 uvU=0.5 取贴图中心（最亮），路灯球用的是 0.75（暗一档）。
    /// </summary>
    static void BuildFireworks(Transform parent)
    {
        var root = new GameObject("Fireworks").transform;
        root.SetParent(parent, false);
        root.position = Vector3.zero;

        var sparkMesh  = GetMesh("Glow_Ball_0p30", () => BuildGlowBall(0.30f, 0.50f));
        var rocketMesh = GetMesh("Glow_Ball_0p38", () => BuildGlowBall(0.38f, 0.50f));

        var rocket = new GameObject("Firework_Rocket");
        rocket.transform.SetParent(root, false);
        rocket.AddComponent<MeshFilter>().sharedMesh = rocketMesh;
        rocket.AddComponent<MeshRenderer>().sharedMaterial = _mats["M_Glow"];
        rocket.layer = LayerCameraNoCollision;
        rocket.SetActive(false);      // 构建时就熄掉，Lua 靠 Transform:Find 找

        for (int i = 1; i <= 12; i++)
        {
            var s = new GameObject("Firework_Spark" + i.ToString("00"));
            s.transform.SetParent(root, false);
            s.AddComponent<MeshFilter>().sharedMesh = sparkMesh;
            s.AddComponent<MeshRenderer>().sharedMaterial = _mats["M_Glow"];
            s.layer = LayerCameraNoCollision;
            s.SetActive(false);
        }

        Debug.Log("[Campus] 烟花节点池：1 火箭 + 12 火星");
    }

    /// <summary>毕业典礼：烟花节点 + 演出脚本宿主。</summary>
    static void BuildCeremony(Transform parent)
    {
        BuildFireworks(parent);
        var host = CreateNpcHost(parent, "CampusCeremony", Vector3.zero,
            "Assets/Campus/Lua/CampusCeremony.lua");
        if (host == null) return;
        var rb = host.GetComponent<Rigidbody>();
        if (rb != null) UnityEngine.Object.DestroyImmediate(rb);
        Debug.Log("[Campus] 典礼宿主 CampusCeremony 已建成");
    }

    /// <summary>
    /// 拾取预制体（校徽、以及门厅/走廊的 4 个示例玻璃球）都由三层同心玻璃球组成，
    /// 每层各用一个材质 Glass_mat01/02/03，在资源检查里白白占掉 3 个额度
    /// —— 而三层叠在一起看就是一个青绿玻璃球。
    ///
    /// 全场景统一到 01，省下 2 个额度（世界材质上限只有 20）。
    /// 必须扫全场景而不是只扫 Collect_xx：`Props/Pickup_0..3` 是另几个未解包的
    /// 预制体实例，不在校徽的父子链里，按物体扫会漏。
    /// </summary>
    static void UnifyGlassSceneWide()
    {
        const string path = "Assets/DouyinVCreateSDK/World/Examples/DouyinPickup/Mat/Glass_mat01.mat";
        var glass = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (glass == null) { Debug.LogWarning("[Campus] 找不到 Glass_mat01，跳过材质合并"); return; }

        int changed = 0;
        foreach (var r in UnityEngine.Object.FindObjectsOfType<MeshRenderer>(true))
        {
            var mats = r.sharedMaterials;
            bool dirty = false;
            for (int k = 0; k < mats.Length; k++)
            {
                var mat = mats[k];
                if (mat != null && mat != glass && mat.name.StartsWith("Glass_mat"))
                {
                    mats[k] = glass; dirty = true; changed++;
                }
            }
            if (dirty) r.sharedMaterials = mats;
        }
        Debug.Log("[Campus] 玻璃材质合并 " + changed + " 处 -> Glass_mat01（省 2 个材质额度）");
    }

    static void BuildCollection(Transform parent)
    {
        var spots = new[]
        {
            new Vector3(-4.4f, 0f,  -21.6f),   // 1 校门内侧
            new Vector3( 3.4f, 0f,    2.2f),   // 2 广场地标台旁
            new Vector3( 3.8f, F1,  18.4f),    // 3 一层门厅（东侧）
            new Vector3(-13.2f, F1, 30.4f),    // 4 一层教室讲台
            new Vector3(-15.4f, F2,  22.4f),   // 5 二层走廊西端
            new Vector3( 10.8f, F2,  30.4f),   // 6 二层楼梯厅（公告板下）
            new Vector3(  9.7f, F3,  31.0f),   // 7 三层阅览角
            new Vector3(-38.0f, 0f,  10.6f),   // 8 操场看台前（跑道与前排看台之间）
        };

        const string pickupPath = "Assets/DouyinVCreateSDK/World/Examples/DouyinPickup/DouyinPickupGlass.prefab";
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(pickupPath);

        for (int i = 0; i < spots.Length; i++)
        {
            var b = spots[i];
            // 只留基座。原先基座上还有"青绿光圈 + 竖直光柱 + 顶端小球"三件套标出收集点，
            // 光柱正好从玻璃杯中间穿过，杯子看起来像被人打了个洞 —— 已整体去掉。
            // 现在靠杯体本身在光池里，找起来反而更自然。
            // 命名必须和 Glow_xx / Collect_xx 一样是 1 基。原来是 "Pedestal_" + i（0 基），
            // 于是第 2 枚校徽的基座叫 Pedestal_1 —— 谁按 Pedestal_%02d 去找都会拿错对象。
            Cyl("Pedestal_" + (i + 1).ToString("00"), parent, 0.30f, 0.9f,
                new Vector3(b.x, b.y + 0.45f, b.z), "M_Concrete");

            // 未收集提示：基座顶面一圈呼吸光。
            // 之前那套"光圈 + 竖直光柱 + 顶端小球"因为光柱从玻璃杯中间穿过、杯子像被打了个洞
            // 而整体删掉了。这次只补回**水平**的一圈 —— 不穿过杯子、不挡视线，
            // 远远看见地上有团暖光就知道这儿还有东西没拿。
            // 收集后由 CampusCollect.lua 把 localScale 压到 0（不用 SetActive(false)，
            // 那样 GameObject.Find 就再也找不到了）。
            var glow = new GameObject("Glow_" + (i + 1).ToString("00"));
            glow.transform.SetParent(parent, false);
            glow.transform.position = new Vector3(b.x, b.y + 0.92f, b.z);
            glow.AddComponent<MeshFilter>().sharedMesh =
                GetMesh("Glow_Disc_0p55", () => BuildGlowDisc(0.55f, 32));
            glow.AddComponent<MeshRenderer>().sharedMaterial = _mats["M_Glow"];
            glow.layer = LayerCameraNoCollision;

            if (prefab == null) continue;
            var go = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
            go.name = "Collect_" + (i + 1).ToString("00");
            go.transform.position = new Vector3(b.x, b.y + 1.10f, b.z);
            go.transform.localScale = Vector3.one * 1.9f;

            // 预制体自带的 DouyinPickup.lua 默认 DropDestroy=true：放下 5 秒后 NetDestroy，
            // 徽章刚摆上架就会消失。改成 false，让它放上去就留在那儿。
            // 必须解包 —— SerializeReference 数组（ParaLuaBindingData）改在预制体实例上
            // 存不成 override，只有解包成普通场景物体才写得进去。
            PrefabUtility.UnpackPrefabInstance(go, PrefabUnpackMode.Completely, InteractionMode.AutomatedAction);
            SetLuaBool(go, "DropDestroy", false);
            if (GetLuaBool(go, "DropDestroy") != false)
                Debug.LogWarning("[Campus] " + go.name + " 的 DropDestroy 没改成功");
        }
        if (prefab == null) Debug.LogWarning("[Campus] 未找到拾取预制体，校徽未生成");

        BuildCollectShelf(parent);
        BuildCollectStation(parent);
        BuildPlazaReward(parent);
    }

    /// <summary>门厅陈列架：8 个槽位，每个槽位下有 Glow（初始隐藏，由 Lua 点亮）</summary>
    /// <remarks>
    /// 朝向很关键：柜子要背靠门厅南墙（z≈17.2）、正面朝 +z 对着从大门进来的人。
    /// 之前把背板放在 +z 侧，结果玩家进门先看到柜子背面，正面只剩 0.85m 挤在外墙和柜子之间，
    /// 交付触发盒有一半埋进墙体 —— 触发不了。现在整套 z 偏移取反，柜子整体挪到 z=17.75。
    /// </remarks>
    static void BuildCollectShelf(Transform parent)
    {
        var root = new GameObject("CollectShelf").transform;
        root.SetParent(parent, false);
        root.position = new Vector3(-3.55f, F1, 17.75f);

        // 宽度收到 3.4：门厅西侧内衬在 x=-5.46，原来的 3.7 会插进墙里 0.4m
        Box("Shelf_Body", root, new Vector3(0, 0.42f, 0), new Vector3(3.4f, 0.84f, 1.05f), "M_Wood");
        // 台面用室内亮色：柜子正面朝北，处在门厅背光面，用混凝土灰会整块糊成黑影
        Box("Shelf_Top", root, new Vector3(0, 0.86f, 0), new Vector3(3.6f, 0.06f, 1.2f), "M_Interior");
        Box("Shelf_Title", root, new Vector3(0, 1.86f, -0.45f), new Vector3(2.4f, 0.36f, 0.04f), "M_Emissive");
        Box("Shelf_Back", root, new Vector3(0, 1.05f, -0.52f), new Vector3(3.6f, 2.1f, 0.08f), "M_Wood");
        // 架内灯带：门斗是背光面，没有它这排槽位在黄昏里几乎看不见
        Box("Shelf_Light", root, new Vector3(0, 1.62f, -0.42f), new Vector3(3.4f, 0.06f, 0.06f), "M_Emissive");

        for (int i = 0; i < CollectTotal; i++)
        {
            int col = i % 4, row = i / 4;
            var slot = new GameObject("Slot_" + (i + 1).ToString("00")).transform;
            slot.SetParent(root, false);
            // 槽位本身的 y = 校徽摆上去之后的中心高度（Lua 直接把物体移到 slot.position），
            // 底盘和光圈往下偏，落在台面（局部 0.89）上，这样东西是"坐在盘里"而不是陷进桌子。
            // 第一排靠正面（+z），所以 row 0 取正号。
            slot.localPosition = new Vector3(-1.35f + col * 0.9f, 1.08f, row == 0 ? 0.28f : -0.28f);

            Cyl("Socket", slot, 0.13f, 0.04f, new Vector3(0, -0.19f, 0), "M_Interior");
            var glow = MeshRing("Glow", slot, 0.14f, 0.2f, 20, new Vector3(0, -0.16f, 0), "M_Collect");
            glow.SetActive(false);
        }
    }

    /// <summary>
    /// 集齐 8 枚后点亮的广场地标。
    ///
    /// ⚠️ 根节点必须保持 active：Lua 用 GameObject.Find 找它，而 Find 不返回 active=false 的物体。
    /// 所以根节点常驻激活，点亮的是它的子物体 —— 根上没有任何 Renderer，看不见也不占 Draw Call。
    /// </summary>
    static void BuildPlazaReward(Transform parent)
    {
        var root = new GameObject("Plaza_Reward").transform;
        root.SetParent(parent, false);
        root.position = new Vector3(0f, 0.55f, 0f);

        for (int i = 0; i < 6; i++)
        {
            float a = i * 60f;
            var p = Polar(2.75f, a);
            Cyl("Reward_Beam" + i, root, 0.06f, 3.4f, new Vector3(p.x, 1.7f, p.z), "M_Collect");
        }
        MeshRing("Reward_RingTop", root, 2.55f, 2.85f, 40, new Vector3(0, 3.4f, 0), "M_Collect");
        Sphere("Reward_Orb", root, new Vector3(0, 4.3f, 0), 0.55f, "M_Collect");

        foreach (Transform child in root.Cast<Transform>().ToArray())
            child.gameObject.SetActive(false);
    }

    /// <summary>
    /// 交付触发区：复用 SDK 拾取预制体的组件链（NetGUID + 网络状态 + DouyinScript），
    /// 只把脚本换成 CampusCollect.lua。手拼这几个组件很容易漏掉网络注册，实例化再改最稳。
    /// </summary>
    static void BuildCollectStation(Transform parent)
    {
        const string pickupPath = "Assets/DouyinVCreateSDK/World/Examples/DouyinPickup/DouyinPickupGlass.prefab";
        const string luaPath = "Assets/Campus/Lua/CampusCollect.lua";

        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(pickupPath);
        var lua = AssetDatabase.LoadMainAssetAtPath(luaPath);
        if (prefab == null || lua == null)
        {
            Debug.LogWarning("[Campus] 交付区创建失败：prefab=" + (prefab != null) + " lua=" + (lua != null));
            return;
        }

        var go = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
        go.name = "CollectStation";
        // 交付区必须落在柜子正面（+z 侧）的空地上，且整块可站立。这里贴着柜沿往前放，
        // 体积 3.6×1.2 覆盖 x -5.35..-1.75 / z 18.25..19.45，门厅这一段是净空的。
        go.transform.position = new Vector3(-3.55f, F1 + 1.2f, 18.85f);

        // 预制体实例里不允许删子物体，先完全解包再改
        PrefabUtility.UnpackPrefabInstance(go, PrefabUnpackMode.Completely, InteractionMode.AutomatedAction);
        foreach (Transform child in go.transform.Cast<Transform>().ToArray())
            UnityEngine.Object.DestroyImmediate(child.gameObject);

        // 触发器要能收到 OnPlayerTriggerEnter，碰撞对里必须至少有一个 Rigidbody。
        // 这里保留预制体的刚体但关掉重力并锁死姿态：动态刚体既能和角色（CharacterController
        // 或 kinematic）配对触发，又不会自己掉下去。删掉刚体是最容易踩的坑 —— 事件直接不派发。
        var rb = go.GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.useGravity = false;
            rb.isKinematic = false;
            rb.constraints = RigidbodyConstraints.FreezeAll;
            rb.collisionDetectionMode = CollisionDetectionMode.ContinuousSpeculative;
        }
        else
        {
            rb = go.AddComponent<Rigidbody>();
            rb.useGravity = false;
            rb.constraints = RigidbodyConstraints.FreezeAll;
        }

        var col = go.GetComponent<BoxCollider>();
        if (col != null)
        {
            col.isTrigger = true;
            col.center = Vector3.zero;
            col.size = new Vector3(3.6f, 2.4f, 1.2f);
        }

        var script = go.GetComponent(FindType("DouyinScript"));
        if (script == null)
        {
            Debug.LogWarning("[Campus] 交付区缺少 DouyinScript 组件");
            return;
        }
        var so = new SerializedObject(script);
        SetProp(so, "ScriptAsset", lua);
        var arr = so.FindProperty("ParaLuaBindingData");
        if (arr != null) arr.arraySize = 0;     // 脚本不带 ---@var，绑定表留空
        SetBool(so, "IsManualedVar", true);
        SetBool(so, "autoUpdate", false);
        so.ApplyModifiedPropertiesWithoutUndo();
        EditorUtility.SetDirty(script);
    }

    // 操场几何参数：场地中心与半径，树/灯的避让判断也用它
    static readonly Vector3 FieldC = new Vector3(-38f, 0f, -2f);
    const float FieldRx = 17f, FieldRz = 11.5f;      // 跑道外沿
    const float FieldLane = 3.5f;                    // 跑道宽度

    /// <summary>判断一个摆点是否落在操场范围内（含 1m 余量），种树/立灯杆前先问一句</summary>
    static bool InFieldArea(Vector3 p, float pad = 1f)
        => Mathf.Abs(p.x - FieldC.x) < FieldRx + pad && Mathf.Abs(p.z - FieldC.z) < FieldRz + pad;

    static void BuildPlayground(Transform parent)
    {
        var c = FieldC;
        float rxIn = FieldRx - FieldLane, rzIn = FieldRz - FieldLane;

        // 外圈路缘：一条窄的混凝土环，把跑道从草地上"收"住，边缘不会直接切进草地
        MeshEllipseRing("Field_Curb", parent, c + new Vector3(0, 0.04f, 0),
            FieldRx, FieldRz, FieldRx + 0.3f, FieldRz + 0.3f, 96, "M_Concrete");

        // 跑道（砖红）+ 两条分道线
        MeshEllipseRing("Field_Track", parent, c + new Vector3(0, 0.05f, 0),
            rxIn, rzIn, FieldRx, FieldRz, 96, "M_Brick");
        for (int i = 1; i <= 2; i++)
        {
            float k = i / 3f;
            float rx = Mathf.Lerp(rxIn, FieldRx, k), rz = Mathf.Lerp(rzIn, FieldRz, k);
            MeshEllipseRing("Field_Lane" + i, parent, c + new Vector3(0, 0.062f, 0),
                rx - 0.05f, rz - 0.035f, rx + 0.05f, rz + 0.035f, 96, "M_Interior");
        }

        // 内场草坪
        MeshEllipseDisc("Field_Lawn", parent, c + new Vector3(0, 0.055f, 0), rxIn, rzIn, 72, "M_Lawn");

        // 足球场标线：18×9，中圈 + 中线 + 两端球门
        const float halfL = 9f, halfW = 4.5f, lineW = 0.12f, lineY = 0.075f;
        float px0 = c.x - halfL, px1 = c.x + halfL, pz0 = c.z - halfW, pz1 = c.z + halfW;
        Box("Pitch_N", parent, new Vector3(c.x, lineY, pz1), new Vector3(halfL * 2f + lineW, 0.02f, lineW), "M_Interior");
        Box("Pitch_S", parent, new Vector3(c.x, lineY, pz0), new Vector3(halfL * 2f + lineW, 0.02f, lineW), "M_Interior");
        Box("Pitch_W", parent, new Vector3(px0, lineY, c.z), new Vector3(lineW, 0.02f, halfW * 2f), "M_Interior");
        Box("Pitch_E", parent, new Vector3(px1, lineY, c.z), new Vector3(lineW, 0.02f, halfW * 2f), "M_Interior");
        Box("Pitch_Mid", parent, new Vector3(c.x, lineY, c.z), new Vector3(lineW, 0.02f, halfW * 2f), "M_Interior");
        MeshRing("Pitch_Circle", parent, 1.5f, 1.62f, 40, c + new Vector3(0, lineY, 0), "M_Interior");

        foreach (float gx in new[] { px0, px1 })
        {
            for (int s = -1; s <= 1; s += 2)
                Cyl("GoalPost_" + gx + "_" + s, parent, 0.07f, 1.7f, new Vector3(gx, 0.85f, c.z + s * 1.6f), "M_Metal");
            Box("GoalBar_" + gx, parent, new Vector3(gx, 1.7f, c.z), new Vector3(0.14f, 0.14f, 3.34f), "M_Metal");
        }

        // 北侧看台：五级台阶 + 背墙（面向场地，也是从广场走过来的第一眼背景）
        for (int i = 0; i < 5; i++)
            Box("Field_Stand" + i, parent, new Vector3(c.x, 0.23f + i * 0.42f, 11.4f + i * 0.95f),
                new Vector3(24f, 0.42f, 0.95f), "M_Concrete");
        Box("Field_StandBack", parent, new Vector3(c.x, 1.1f, 15.35f), new Vector3(24f, 2.0f, 0.35f), "M_Wall");

        // 四角灯杆（自发光，靠材质而非实时灯）
        foreach (var p in new[] { new Vector3(-53f, 0, -15f), new Vector3(-23f, 0, -15f),
                                  new Vector3(-53f, 0, 12f),  new Vector3(-23f, 0, 12f) })
        {
            Cyl("Field_Pole", parent, 0.14f, 8.5f, p + new Vector3(0, 4.25f, 0), "M_Metal");
            var head = Box("Field_LampHead", parent, p + new Vector3(0, 8.7f, 0), new Vector3(1.7f, 0.2f, 0.6f), "M_Emissive");
            head.layer = LayerCameraNoCollision;
        }
    }

    static void BuildMainGate(Transform parent)
    {
        const float z = -22f;
        Box("Gate_PillarL", parent, new Vector3(-6f, 3f, z), new Vector3(1.6f, 6f, 1.6f), "M_Brick");
        Box("Gate_PillarR", parent, new Vector3(6f, 3f, z), new Vector3(1.6f, 6f, 1.6f), "M_Brick");
        Box("Gate_Beam", parent, new Vector3(0, 6.6f, z), new Vector3(14f, 1.2f, 1.8f), "M_Concrete");
        // 校名牌「樱花大学」：木底衬 + 正反两贴字。
        // 位置顶到横梁下沿（横梁底 6.0），才像是"挂"在门梁上；贴着横梁前脸 z-0.9 放，不留悬空的缝
        var plate = Box("Gate_NamePlate", parent, new Vector3(0, 5.42f, z - 0.9f - 0.09f),
            new Vector3(4.98f, 1.26f, 0.18f), "M_Wood");
        plate.layer = LayerCameraNoCollision;
        // quad 的正面朝 +Z（海报都是靠 yaw=180 贴到朝南/朝北的墙上），
        // 所以"朝来客（-Z）"要 yaw=180，"朝校园（+Z）"才是 yaw=0
        float signY = 5.42f - 1.2f * 0.5f;     // 牌匾中心 5.42 → 底边 4.82
        AddSignQuad("Gate_SignOut", parent, new Vector3(0, signY, z - 1.09f), 4.8f, 1.2f, 180f);
        AddSignQuad("Gate_SignIn", parent, new Vector3(0, signY, z - 0.89f), 4.8f, 1.2f, 0f);
        // 两侧围墙
        Box("Gate_WallL", parent, new Vector3(-13f, 0.9f, z), new Vector3(12f, 1.8f, 0.8f), "M_Wall");
        Box("Gate_WallR", parent, new Vector3(13f, 0.9f, z), new Vector3(12f, 1.8f, 0.8f), "M_Wall");

        // 门口地面
        Box("Gate_Apron", parent, new Vector3(0, 0.02f, z - 2f), new Vector3(30f, 0.04f, 8f), "M_Concrete");
    }

    static void BuildProps(Transform parent)
    {
        // 樱花树：校道两侧 + 操场四周 + 楼前。全部显式摆点，
        // 落点前用 InFieldArea 过一道，避免再出现"树长在跑道中间"这种事
        var treeSpots = new List<Vector3>
        {
            // 原校园里的 8 棵（改成樱花）
            new Vector3(19f, 0, 3f),  new Vector3(21f, 0, -7f), new Vector3(12f, 0, -18f),
            new Vector3(-19f, 0, -9f), new Vector3(-20f, 0, 12f), new Vector3(-11f, 0, 17f),
            new Vector3(11f, 0, 17f),  new Vector3(-7f, 0, -20f),

            // 校门 → 广场 的樱花道（主干道两侧各三棵）
            new Vector3(7.4f, 0, -25.5f),  new Vector3(-7.4f, 0, -25.5f),
            new Vector3(7.4f, 0, -19.0f),  new Vector3(-7.4f, 0, -19.0f),
            new Vector3(7.4f, 0, -13.0f),  new Vector3(-7.4f, 0, -13.0f),

            // 操场南侧一排
            new Vector3(-52f, 0, -15.8f), new Vector3(-45f, 0, -15.5f), new Vector3(-38f, 0, -16.0f),
            new Vector3(-31f, 0, -15.5f), new Vector3(-24f, 0, -15.8f),
            // 操场西侧
            new Vector3(-56.5f, 0, -9f), new Vector3(-57f, 0, -2f), new Vector3(-56.5f, 0, 5f),
            // 看台背后
            new Vector3(-50f, 0, 16.2f), new Vector3(-43f, 0, 16.5f),
            new Vector3(-36f, 0, 16.2f), new Vector3(-29f, 0, 16.5f),
        };

        int ti = 0;
        foreach (var spot in treeSpots)
        {
            if (InFieldArea(spot, 0.5f)) continue;      // 兜底：任何落进操场的点直接跳过
            MakeCherryTree("Cherry_" + ti, parent, spot, 1.0f + (ti % 4) * 0.08f, 11 + ti * 7);
            ti++;
        }
        Debug.Log("[Campus] cherry trees = " + ti + " / " + treeSpots.Count);

        BuildStreetLamps(parent);

        // 社交节点：复用 SDK 的椅子预制体（自带 Lua 交互），面向广场中心
        var chairPrefab = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/DouyinVCreateSDK/World/Examples/DouyinSeat/DouyinChair.prefab");
        if (chairPrefab != null)
        {
            for (int i = 0; i < 4; i++)
            {
                float a = i * 90f;
                var p = Polar(12.6f, a);
                var chair = (GameObject)PrefabUtility.InstantiatePrefab(chairPrefab, parent);
                chair.name = "Bench_" + i;
                chair.transform.position = new Vector3(p.x, 0.06f, p.z);
                chair.transform.rotation = Quaternion.LookRotation(new Vector3(-p.x, 0, -p.z));
                // SDK 椅子自带 Chair01_mat：材质上限只有 20，这一张椅子就吃掉一个额度。
                // 统一换成校园的木色（视觉上也更统一），把额度让给樱花和校名牌。
                foreach (var mr in chair.GetComponentsInChildren<MeshRenderer>(true))
                {
                    var mats = mr.sharedMaterials;
                    for (int k = 0; k < mats.Length; k++) mats[k] = _mats["M_Wood"];
                    mr.sharedMaterials = mats;
                }
            }
        }
        else
        {
            Debug.LogWarning("[Campus] 未找到椅子预制体，跳过社交节点");
        }

        AddPickups(parent);
    }

    /// <summary>
    /// 可拾取物：直接用 SDK 预制体，不手拼组件。
    /// DouyinPickup 是 Lua 驱动的（DouyinPickup.lua），Awake 里会 SetLayer(PropsLayer) 并接管
    /// Rigidbody；手工创建的话 NetGUID / ScriptAsset 的绑定极易出错，实例化是最稳的做法。
    /// </summary>
    static void AddPickups(Transform parent)
    {
        const string path = "Assets/DouyinVCreateSDK/World/Examples/DouyinPickup/DouyinPickupGlass.prefab";
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
        if (prefab == null)
        {
            Debug.LogWarning("[Campus] 未找到拾取预制体，跳过");
            return;
        }

        // 全部贴着地面放：预制体带重力，悬空会直接掉到楼板上
        var spots = new[]
        {
            new Vector3(-9.2f, 1.35f, 21.3f),   // 一层门厅
            new Vector3(-15.6f, 1.35f, 28.2f),  // 一层教室 0
            new Vector3(-1.6f, 5.65f, 21.6f),   // 二层走廊
            new Vector3(10.8f, 5.65f, 26.4f),   // 二层楼梯厅（公告板前）
        };
        for (int i = 0; i < spots.Length; i++)
        {
            var go = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
            go.name = "Pickup_" + i;
            go.transform.position = spots[i];
            go.transform.localScale = Vector3.one * 0.85f;
        }
        Debug.Log("[Campus] pickups = " + spots.Length);
    }

    /// <summary>
    /// 樱花树：木色树干 + 两根斜枝 + 三团压扁的粉色树冠。
    /// 树冠必须比绿树更宽更扁（樱花是一团团摊开的，不是一个球），否则远看只是一棵"粉色绿树"。
    /// </summary>
    static void MakeCherryTree(string name, Transform parent, Vector3 pos, float scale, int seed)
    {
        var root = new GameObject(name).transform;
        root.SetParent(parent, false);
        root.position = pos;
        root.localScale = Vector3.one * scale;
        root.gameObject.layer = LayerCameraNoCollision;

        var rnd = new System.Random(seed);
        float yaw = (float)(rnd.NextDouble() * 360.0);
        Cyl("Trunk", root, 0.15f, 2.5f, new Vector3(0, 1.25f, 0), "M_Wood");

        // 两根斜枝：每棵转向不同，远处看成一片时不会像复制粘贴
        for (int i = 0; i < 2; i++)
        {
            float a = yaw + i * 150f;
            var br = Cyl("Branch" + i, root, 0.07f, 1.35f, Vector3.zero, "M_Wood");
            br.transform.localRotation = Quaternion.Euler(i == 0 ? 26f : -22f, a, 0f);
            br.transform.localPosition = new Vector3(Mathf.Sin(a * Mathf.Deg2Rad) * 0.22f, 2.45f,
                                                     Mathf.Cos(a * Mathf.Deg2Rad) * 0.22f);
        }

        // 花冠：8 团低面球合并成单个网格，轮廓是碎的叶团而不是一个光滑椭球。
        // 5 种变体按种子轮换，远处连成一片时看不出复制粘贴。
        int variant = Mathf.Abs(seed) % 5;
        var crown = GetMesh("Crown_Sakura_" + variant, () => BuildCherryCrown(7300 + variant * 17, 10));
        var cg = PlaceMesh("Crown", root, crown, new Vector3(0.06f, 2.88f, 0.02f), "M_Sakura");
        UnityEngine.Object.DestroyImmediate(cg.GetComponent<MeshCollider>());   // 树冠不该挡人
        cg.transform.localRotation = Quaternion.Euler(0, yaw, 0);
    }

    static void MakeTree(string name, Transform parent, Vector3 pos, float scale)
    {
        var root = new GameObject(name).transform;
        root.SetParent(parent, false);
        root.position = pos;
        root.localScale = Vector3.one * scale;
        root.gameObject.layer = LayerCameraNoCollision;

        Cyl("Trunk", root, 0.2f, 3.0f, new Vector3(0, 1.5f, 0), "M_Brick");
        // 树冠用球体压扁，风格化处理；比起自造圆锥网格更稳，也不会有法线/绕序问题
        Sphere("Crown_Low", root, new Vector3(0, 3.3f, 0), 1.15f, "M_Lawn");
        var high = Sphere("Crown_High", root, new Vector3(0.25f, 4.1f, 0.15f), 0.85f, "M_Lawn");
        high.transform.localScale = new Vector3(1.5f, 1.2f, 1.5f);
    }

    // ---------------------------------------------------------------- SDK 接线

    static GameObject SetupWorldRoot()
    {
        var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(WorldRootPrefab);
        if (prefab == null) throw new Exception("找不到 DouyinWorldRoot 预制体");

        var go = (GameObject)PrefabUtility.InstantiatePrefab(prefab);
        go.name = "DouyinWorldRoot";
        go.transform.position = Vector3.zero;

        // 出生点：校门内侧，老陈斜前方 2.4m —— 让他成为玩家进世界看到的第一个人。
        // 之前出生在广场中心 (0,-3)，玩家几乎必然先捡到广场那枚校徽（离出生点 6m），
        // 触发"第一枚自动接取任务"，老陈的发任务台词就永远播不出来了。
        var spawn = new GameObject("Spawn_SchoolGate").transform;
        spawn.position = new Vector3(0f, 0.2f, -20.5f);
        spawn.rotation = Quaternion.Euler(0, 0, 0);

        var so = new SerializedObject(go.GetComponent(FindType("DouyinWorldRoot")));
        var spawns = so.FindProperty("Spawns");
        if (spawns != null)
        {
            spawns.arraySize = 1;
            spawns.GetArrayElementAtIndex(0).objectReferenceValue = spawn;
        }
        SetProp(so, "GuestSpawn", spawn);
        SetFloat(so, "MoveSpeed", 3.2f);
        SetFloat(so, "JumpHeight", 1.2f);
        SetFloat(so, "RespawnHeightY", -20f);
        SetBool(so, "IsCheckMoveColliderObj", true);
        so.ApplyModifiedPropertiesWithoutUndo();

        return go;
    }

    /// <summary>
    /// 编辑器里的天光/雾。运行时以 pbjson 配置为准，这里是为了"打开场景就能看到夕阳"。
    /// RenderSettings 光在 Build 里赋值会被场景重载丢掉，所以 RunAll 末尾还要再存一次。
    /// </summary>
    static void ApplyRenderSettings()
    {
        var sky = AssetDatabase.LoadAssetAtPath<Material>(DuskSkybox);
        if (sky != null) RenderSettings.skybox = sky;

        RenderSettings.ambientMode = AmbientMode.Skybox;
        RenderSettings.ambientIntensity = 1.15f;
        RenderSettings.fog = true;
        RenderSettings.fogMode = FogMode.Linear;
        RenderSettings.fogColor = new Color(0.85f, 0.57f, 0.40f);
        RenderSettings.fogStartDistance = 30f;
        RenderSettings.fogEndDistance = 320f;
        RenderSettings.sun = null;
    }

    /// <summary>把 RenderSettings 真正写进场景文件</summary>
    public static void PersistRenderSettings()
    {
        var sc = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        ApplyRenderSettings();
        EditorSceneManager.MarkSceneDirty(sc);
        EditorSceneManager.SaveScene(sc, ScenePath);
        AssetDatabase.SaveAssets();
    }

    static GameObject SetupEnvironment()
    {
        // 主光：方向光由 DouyinSceneEnvironment 接管，参数以 Dusk01 配置为准
        var lightGo = new GameObject("MainLight");
        var light = lightGo.AddComponent<Light>();
        light.type = LightType.Directional;
        // 太阳压到 18°：长影 + 暖光，跟天空贴图里的太阳方位（240°）对齐
        light.color = new Color(1f, 0.62f, 0.40f);
        light.intensity = 3.6f;
        light.shadows = LightShadows.Soft;
        light.shadowStrength = 0.9f;
        lightGo.transform.rotation = Quaternion.Euler(18f, 60f, 0f);

        var envComp = lightGo.AddComponent(FindType("DouyinSceneEnvironment"));
        if (envComp == null)
        {
            Debug.LogWarning("[Campus] 未找到 DouyinSceneEnvironment 类型，环境配置未接线");
            return lightGo;
        }

        var profile = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(DuskProfile);
        var so = new SerializedObject(envComp);
        SetObj(so, "JsonAsset", profile);
        SetObj(so, "mainLight", light);
        so.ApplyModifiedPropertiesWithoutUndo();

        ApplyRenderSettings();
        return lightGo;
    }

    // ---------------------------------------------------------------- 报告

    static void WriteReport(UnityEngine.SceneManagement.Scene scene, GameObject worldRoot, GameObject envGo)
    {
        var sb = new StringBuilder();
        sb.AppendLine("# 微缩校园构建报告");
        sb.AppendLine("time=" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
        sb.AppendLine("scene=" + ScenePath);
        sb.AppendLine();

        var renderers = UnityEngine.Object.FindObjectsOfType<Renderer>(true);
        var meshes = new HashSet<Mesh>();
        var mats = new HashSet<Material>();
        long trisTotal = 0;   // 场景内所有实例相加（性能口径）
        long trisUnique = 0;  // 唯一网格相加（资源口径）
        foreach (var r in renderers)
        {
            var mf = r.GetComponent<MeshFilter>();
            if (mf != null && mf.sharedMesh != null)
            {
                int t = mf.sharedMesh.triangles.Length / 3;
                trisTotal += t;
                if (meshes.Add(mf.sharedMesh)) trisUnique += t;
            }
            foreach (var m in r.sharedMaterials) if (m != null) mats.Add(m);
        }

        int colliders = UnityEngine.Object.FindObjectsOfType<Collider>(true).Length;
        int lights = UnityEngine.Object.FindObjectsOfType<Light>(true).Length;
        int particles = UnityEngine.Object.FindObjectsOfType<ParticleSystem>(true).Length;

        sb.AppendLine("## 资源占用（SDK 资源检查口径的近似值）");
        sb.AppendLine("  Renderer      = " + renderers.Length);
        sb.AppendLine("  唯一 Mesh     = " + meshes.Count);
        sb.AppendLine("  唯一 Material = " + mats.Count + "   -> " + string.Join(", ", mats.Select(m => m.name).OrderBy(n => n)));
        sb.AppendLine("  三角面(实例合计) = " + trisTotal);
        sb.AppendLine("  三角面(唯一网格) = " + trisUnique);
        sb.AppendLine("  Collider      = " + colliders);
        sb.AppendLine("  Light         = " + lights);
        sb.AppendLine("  ParticleSystem= " + particles);
        var allT = UnityEngine.Object.FindObjectsOfType<Transform>(true);
        sb.AppendLine("  校徽拾取物    = " + allT.Count(t => t.name.StartsWith("Collect_") && t.name.Length == 10));
        var shelf = allT.FirstOrDefault(t => t.name == "CollectShelf");
        sb.AppendLine("  CollectShelf  = " + (shelf == null ? "<缺失>" : shelf.childCount + " 个子物体（应有 8 槽 + 4 结构）"));
        var reward = allT.FirstOrDefault(t => t.name == "Plaza_Reward");
        sb.AppendLine("  Plaza_Reward  = " + (reward == null ? "<缺失>" :
            "根 activeSelf=" + reward.gameObject.activeSelf +
            "（必须 true，否则 Lua 的 GameObject.Find 找不到）；子物体 " + reward.childCount +
            " 个，其中亮着的 " + reward.Cast<Transform>().Count(c => c.gameObject.activeSelf)));
        sb.AppendLine("  海报          = " + allT.Count(t => t.name.StartsWith("Poster_")));
        sb.AppendLine("  盆栽          = " + allT.Count(t => t.name.StartsWith("Plant_")));
        sb.AppendLine("  灌木/绿篱     = " + allT.Count(t => t.name.StartsWith("Bush_") || t.name.StartsWith("Hedge")));
        sb.AppendLine("  樱花树        = " + allT.Count(t => t.name.StartsWith("Cherry_")));
        sb.AppendLine("  NPC           = " + allT.Count(t => System.Text.RegularExpressions.Regex.IsMatch(t.name, @"^NPC_\d\d$")) +
            " 个（路点 " + allT.Count(t => t.name.StartsWith("Waypoint_")) + "，名牌 " +
            allT.Count(t => t.name == "NameQuad") + "，气泡 " + allT.Count(t => t.name == "Bubble") +
            "，台词quad " + allT.Count(t => t.name.StartsWith("Line_")) + "）");
        sb.AppendLine("  校名牌        = " + allT.Count(t => t.name.StartsWith("Gate_Sign") || t.name == "Bldg_SignFront") +
            "（门梁正反两面 + 主立面）");
        sb.AppendLine("  操场          = 跑道 17×11.5 / 内场 13.5×8，看台 " +
            allT.Count(t => t.name.StartsWith("Field_Stand")) + " 级，球门 " +
            allT.Count(t => t.name.StartsWith("GoalPost")) + " 根立柱");
        var station = allT.FirstOrDefault(t => t.name == "CollectStation");
        sb.AppendLine("  CollectStation= " + (station == null ? "<缺失>" :
            "已创建，trigger=" + (station.GetComponent<Collider>() != null && station.GetComponent<Collider>().isTrigger) +
            "，Rigidbody=" + (station.GetComponent<Rigidbody>() != null) +
            "，DouyinScript=" + (station.GetComponent(FindType("DouyinScript")) != null)));

        // 收集链路的关键前置条件，任何一条不满足都会让运行时"什么都不发生"
        var collectChecks = new List<string>();
        var items = allT.Where(t => t.name.StartsWith("Collect_") && t.name.Length == 10).OrderBy(t => t.name).ToList();
        collectChecks.Add("拾取物 " + items.Count + "/8");
        int keepCount = items.Count(t =>
        {
            var s = t.GetComponent(FindType("DouyinScript"));
            if (s == null) return false;
            var so = new SerializedObject(s);
            var arr = so.FindProperty("ParaLuaBindingData");
            if (arr == null) return false;
            const BindingFlags F = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
            for (int i = 0; i < arr.arraySize; i++)
            {
                var o = arr.GetArrayElementAtIndex(i).managedReferenceValue;
                if (o == null) continue;
                var tt = o.GetType();
                var fn = tt.GetField("varName", F);
                if (fn == null || !(fn.GetValue(o) is string n) || n != "DropDestroy") continue;
                var fd = tt.GetField("Data", F);
                return fd != null && fd.GetValue(o) is bool b && !b;
            }
            return false;
        });
        collectChecks.Add("DropDestroy=false 的 " + keepCount + "/8");
        if (shelf != null)
        {
            int glow = 0;
            for (int i = 1; i <= 8; i++)
            {
                var slot = shelf.Find("Slot_" + i.ToString("00"));
                if (slot == null) continue;
                var g = slot.Find("Glow");
                if (g != null && !g.gameObject.activeSelf) glow++;
            }
            collectChecks.Add("初始熄灭的 Glow " + glow + "/8");
        }
        sb.AppendLine("  收集链路      = " + string.Join("，", collectChecks));
        sb.AppendLine();

        sb.AppendLine("## SDK 接线");
        var wr = worldRoot.GetComponent(FindType("DouyinWorldRoot"));
        if (wr != null)
        {
            var so = new SerializedObject(wr);
            var sp = so.FindProperty("Spawns");
            var t = sp != null && sp.arraySize > 0 ? sp.GetArrayElementAtIndex(0).objectReferenceValue as Transform : null;
            int wrCount = 0;
            foreach (var go in scene.GetRootGameObjects())
                wrCount += go.GetComponentsInChildren(wr.GetType(), true).Length;
            sb.AppendLine("  DouyinWorldRoot 数量 = " + wrCount);
            sb.AppendLine("  Spawn[0] = " + (t == null ? "<未设置>" : t.name + " @ " + t.position));
            sb.AppendLine("  MoveSpeed = " + so.FindProperty("MoveSpeed").floatValue + "  JumpHeight = " + so.FindProperty("JumpHeight").floatValue);
        }

        var env = envGo.GetComponent(FindType("DouyinSceneEnvironment"));
        if (env != null)
        {
            var so = new SerializedObject(env);
            var ja = so.FindProperty("JsonAsset");
            sb.AppendLine("  SceneEnvironment.JsonAsset = " + (ja == null || ja.objectReferenceValue == null ? "<未设置>" : ja.objectReferenceValue.name));
            var ml = so.FindProperty("mainLight");
            sb.AppendLine("  SceneEnvironment.mainLight = " + (ml == null || ml.objectReferenceValue == null ? "<未设置>" : ml.objectReferenceValue.name));
        }

        sb.AppendLine();
        sb.AppendLine("## 场景根对象");
        foreach (var go in scene.GetRootGameObjects()) sb.AppendLine("  " + go.name);

        File.WriteAllText(ReportPath, sb.ToString(), new UTF8Encoding(false));

        // 同时校验：没有 Missing Script
        var missing = new List<string>();
        foreach (var go in scene.GetRootGameObjects())
            foreach (var c in go.GetComponentsInChildren<Component>(true))
                if (c == null) missing.Add(go.name);
        Debug.Log("[Campus] missingScripts=" + (missing.Count == 0 ? "none" : string.Join(",", missing)));
    }

    // ---------------------------------------------------------------- 资源构造

    static void CreateWhiteTexture()
    {
        var path = TexDir + "/T_White.png";
        if (File.Exists(path)) return;

        var tex = new Texture2D(4, 4, TextureFormat.RGBA32, false);
        var px = new Color32[16];
        for (int i = 0; i < 16; i++) px[i] = new Color32(255, 255, 255, 255);
        tex.SetPixels32(px);
        tex.Apply();
        File.WriteAllBytes(path, tex.EncodeToPNG());
        UnityEngine.Object.DestroyImmediate(tex);
        AssetDatabase.ImportAsset(path);

        var imp = (TextureImporter)AssetImporter.GetAtPath(path);
        imp.sRGBTexture = false;
        imp.mipmapEnabled = false;
        imp.wrapMode = TextureWrapMode.Clamp;
        imp.textureCompression = TextureImporterCompression.Uncompressed;
        imp.SaveAndReimport();
    }

    static void CreateMaterials()
    {
        var shader = Shader.Find(WorldLitShader);
        if (shader == null) throw new Exception("找不到着色器 " + WorldLitShader);
        var white = AssetDatabase.LoadAssetAtPath<Texture2D>(TexDir + "/T_White.png");

        foreach (var kv in Palette)
        {
            var path = MatDir + "/" + kv.Key + ".mat";
            var m = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (m == null)
            {
                m = new Material(shader);
                AssetDatabase.CreateAsset(m, path);
            }
            m.shader = shader;
            m.SetColor("_BaseColor", kv.Value);
            m.SetFloat("_BaseColorPower", 1f);
            m.SetFloat("_Metallic", 0f);
            m.SetFloat("_Smoothness", 0.55f);
            // 关键：默认白法线贴图经 (RG*2-1) 会得到 (1,1,1) 的错误法线，置 0 后恒为平面法线
            m.SetFloat("_NormalScale", 0f);
            m.SetFloat("_RimPower", 0f);
            m.SetFloat("_FresnelInt", 5f);
            m.SetTexture("_RGNormalBSmoothAAO", white);
            m.SetTexture("_ColorCoverTex", white);
            m.SetTexture("_Emission", white);
            m.SetColor("_EmissionColor", Color.black);
            m.SetFloat("_EmissionPower", 1f);
            ApplyDetailTexture(m, kv.Key);

            if (kv.Key == "M_Emissive")
            {
                m.SetColor("_BaseColor", new Color(0.35f, 0.26f, 0.18f));
                m.SetColor("_EmissionColor", new Color(1f, 0.66f, 0.32f));
                m.SetFloat("_EmissionPower", 1.4f);
            }
            if (kv.Key == "M_Glass")
            {
                m.SetFloat("_Metallic", 0.85f);
                m.SetFloat("_Smoothness", 1.6f);
                m.SetColor("_EmissionColor", new Color(0.12f, 0.10f, 0.07f));
            }
            if (kv.Key == "M_Wall")
            {
                // 墙体同时是"建筑外表面"和"室内可见的内表面"。纯环境光下内表面会黑成一块，
                // 从室外透过入口看进去就是一块纯黑；给极弱自发光兜底（0.12，不影响外观立体感）。
                m.SetColor("_EmissionColor", new Color(0.88f, 0.84f, 0.76f));
                m.SetFloat("_EmissionPower", 0.12f);
            }
            if (kv.Key == "M_Lawn" || kv.Key == "M_Sakura")
            {
                m.SetFloat("_Smoothness", 0.15f);
            }
            if (kv.Key == "M_Sakura")
            {
                // 黄昏 + 无实时 GI：树冠纯靠环境光会发灰发脏，给一点点自发光托底，
                // 让粉色在逆光里也能立住（和 M_Interior 同一套思路）
                m.SetColor("_EmissionColor", new Color(0.98f, 0.63f, 0.68f));
                m.SetFloat("_EmissionPower", 0.32f);
            }
            if (kv.Key == "M_StarPink")
            {
                // 亮玫粉是她的主视觉，逆光下不能塌成暗红：给 0.16 自发光托底。
                // 再高就会像霓虹灯牌，反而廉价。
                m.SetColor("_EmissionColor", new Color(0.98f, 0.42f, 0.58f));
                m.SetFloat("_EmissionPower", 0.16f);
                m.SetFloat("_Smoothness", 0.35f);
            }
            if (kv.Key == "M_Denim")
            {
                m.SetFloat("_Smoothness", 0.12f);   // 丹宁是粗斜纹，不该反光
            }
            if (kv.Key == "M_NpcLine")
            {
                // 纸面哑光；自发光取自贴图本身（见 ApplyDetailTexture），强度 0.85 ——
                // 太低会在背光面变成灰板，太高白纸会过曝把字冲淡
                m.SetFloat("_Smoothness", 0.05f);
                m.SetFloat("_Metallic", 0f);
                m.SetColor("_EmissionColor", new Color(0.92f, 0.92f, 0.92f));
                m.SetFloat("_EmissionPower", 0.85f);
                m.SetColor("_BaseColor", new Color(0.35f, 0.35f, 0.35f));   // 压暗底图，避免自发光叠加后过曝
                // 双面渲染：名牌/气泡是单面 quad，靠 Lua 每帧 billboard 朝向相机。
                // 真机上 Camera.main 可能拿不到（或不是玩家视角相机），billboard 一旦失效，
                // quad 就保持背对玩家被背面剔除 —— 表现为"头顶名字和台词全都看不见"。
                // World_Lit 的 Forward pass 读 _CullMode（0=Off 双面），把它关掉就彻底根治：
                // 背面看文字是镜像的，但"能看到"永远优于"看不到"。
                m.SetFloat("_CullMode", 0f);
            }
            if (kv.Key == "M_SignText")
            {
                // 校名牌朝北，黄昏完全照不到；用自身贴图做弱自发光，等于给牌匾打了个内打光
                var signTex = AssetDatabase.LoadAssetAtPath<Texture2D>(TexDir + "/T_SchoolSign.png");
                if (signTex != null)
                {
                    m.SetTexture("_Emission", signTex);
                    m.SetColor("_EmissionColor", new Color(0.72f, 0.66f, 0.54f));
                    m.SetFloat("_EmissionPower", 0.85f);
                }
                m.SetFloat("_Smoothness", 0.7f);
            }
            if (kv.Key == "M_Interior")
            {
                // 室内只靠环境光：黄昏天空色约 0.21，且 SDK 无实时 GI（吸顶灯不照亮周围）；
                // 天花的 Skybox 环境光按法线采样，朝下只拿到 GroundColor(0.047)，几乎全黑。
                // 用极弱自发光把暗部抬到可读亮度，同时保留明暗层次。
                // 光滑度不在这里设：已交给法线图 B 通道（0.30），这里再乘一次会把室内压成死哑。
                m.SetColor("_EmissionColor", new Color(0.92f, 0.88f, 0.80f));
                m.SetFloat("_EmissionPower", 0.30f);
            }
            if (kv.Key == "M_Collect")
            {
                // 收集品与进度槽：黄昏下必须自己发光，否则和 M_Emissive 的暖光混在一起看不出来
                m.SetFloat("_Smoothness", 0.5f);
                m.SetColor("_BaseColor", new Color(0.14f, 0.42f, 0.46f));
                m.SetColor("_EmissionColor", new Color(0.30f, 0.88f, 1.0f));
                m.SetFloat("_EmissionPower", 1.5f);
            }
            if (kv.Key == "M_Poster")
            {
                // 黄昏主光强度 4.0、色温很暖，纯反射的印刷品会被照成一片褐色。
                // 让海报用自己当自发光贴图，暗部才保得住本来颜色（观感接近覆膜/灯箱海报）。
                var atlas = AssetDatabase.LoadAssetAtPath<Texture2D>(TexDir + "/T_PosterAtlas.png");
                if (atlas != null) m.SetTexture("_Emission", atlas);
                m.SetColor("_EmissionColor", new Color(0.62f, 0.62f, 0.62f));
                m.SetFloat("_EmissionPower", 0.9f);
                m.SetFloat("_Smoothness", 0.15f);
            }
            if (kv.Key == "M_Window")
            {
                m.SetFloat("_Smoothness", 0.4f);
                m.SetColor("_EmissionColor", new Color(1f, 0.66f, 0.40f));
                m.SetFloat("_EmissionPower", 0.55f);
            }
            if (kv.Key == "M_Brick")
            {
                // 光滑度已由法线图的 B 通道给（0.34），这里不再乘衰减，只把反射色调压一点
                m.SetFloat("_NormalScale", 0.85f);
            }
            if (kv.Key == "M_Sakura")
            {
                // 颜色和光滑度都交给 T_Sakura：这张贴图是彩色的（深粉→浅粉→近白），
                // 再乘 Palette 里的粉色会整体压暗、层次全丢
                m.SetColor("_BaseColor", Color.white);
            }

            EditorUtility.SetDirty(m);
            _mats[kv.Key] = m;
        }
        CreateGlowMaterial();   // 不走 Palette：它是 VFX 加法着色器，参数体系完全不同
        AssetDatabase.SaveAssets();
    }

    /// <summary>
    /// 每个材质挂哪张细节贴图、平铺几倍。
    /// 平铺值是"按该材质最常见的那个大面"定的：世界里的 UV 有两套来源 ——
    /// 盒体（Cube 原始 UV 0..1）和自建网格（圆盘/地面用米制 UV），
    /// 所以这里只能取折中值；贴图都做成低频噪声，拉伸了也看不出来。
    /// </summary>
    static void ApplyDetailTexture(Material m, string key)
    {
        string file = null;
        var tile = Vector2.one;
        switch (key)
        {
            case "M_Wall": file = "T_WallPlaster"; tile = new Vector2(6f, 3f); break;
            case "M_Interior": file = "T_Interior"; tile = new Vector2(5f, 2.5f); break;
            case "M_Concrete": file = "T_Concrete"; tile = new Vector2(3f, 3f); break;
            case "M_Paving_A": file = "T_Paving"; tile = new Vector2(7f, 7f); break;   // 28m 广场 → 4m/循环 → 1m 石板
            case "M_Lawn": file = "T_Grass"; tile = new Vector2(4f, 4f); break;
            case "M_Wood": file = "T_Wood"; tile = new Vector2(2f, 1f); break;
            case "M_Sakura": file = "T_Sakura"; tile = Vector2.one; break;
            case "M_Poster": file = "T_PosterAtlas"; tile = Vector2.one; break;
            case "M_SignText": file = "T_SchoolSign"; tile = Vector2.one; break;
            case "M_NpcLine": file = "T_NpcLines"; tile = Vector2.one; break;
        }
        // 法线/粗糙度/AO 与 albedo 分开挂：砖、跑道、铺装B 没有 albedo 贴图，但一样要有表面细节
        ApplyPackedNormal(m, key);

        if (file == null) return;

        var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(TexDir + "/" + file + ".png");
        if (tex == null)
        {
            Debug.LogWarning("[Campus] 缺少贴图 " + file);
            return;
        }
        m.SetTexture("_BasecoloTex_AMeta", tex);
        m.SetTextureScale("_BasecoloTex_AMeta", tile);
        m.SetTextureOffset("_BasecoloTex_AMeta", Vector2.zero);

        // NPC 名牌/气泡是"界面元素"，不该受场景光照摆布：
        // 同一个 quad 从不同角度看，N·L 会从亮变全黑（第一版就是黑块）。
        // 把同一张贴图接到 _Emission，等于给字打了个内打光，任何角度都一致。
        if (key == "M_NpcLine")
        {
            m.SetTexture("_Emission", tex);
            m.SetTextureScale("_Emission", tile);
            m.SetTextureOffset("_Emission", Vector2.zero);
        }
    }

    /// <summary>
    /// 挂打包法线图。平铺值必须和 albedo 一致 —— 法线和颜色错位，观感就是"贴图在表面滑动"。
    /// 没有 albedo 的材质（砖）单独给平铺值。
    ///
    /// _Smoothness 同时改成 1：这张图 B 通道已经写了目标光滑度，
    /// 若还留着原来的 0.55 就会再乘一次，整体变成一片哑光。
    /// </summary>
    static void ApplyPackedNormal(Material m, string key)
    {
        string file = null;
        var tile = Vector2.one;
        float scale = 0.6f;
        switch (key)
        {
            case "M_Wall":     file = "T_N_Wall";     tile = new Vector2(6f, 3f);   scale = 0.55f; break;
            case "M_Interior": file = "T_N_Interior"; tile = new Vector2(5f, 2.5f); scale = 0.45f; break;
            case "M_Concrete": file = "T_N_Concrete"; tile = new Vector2(3f, 3f);   scale = 0.50f; break;
            case "M_Paving_A": file = "T_N_Paving";   tile = new Vector2(7f, 7f);   scale = 1.00f; break;
            case "M_Lawn":     file = "T_N_Grass";    tile = new Vector2(4f, 4f);   scale = 0.65f; break;
            case "M_Sakura":   file = "T_N_Sakura";   tile = new Vector2(1f, 1f);   scale = 0.40f; break;
            case "M_Wood":     file = "T_N_Wood";     tile = new Vector2(2f, 1f);   scale = 0.60f; break;
            case "M_Brick":    file = "T_N_Brick";    tile = new Vector2(2f, 2f);   scale = 0.85f; break;
        }
        if (file == null) return;

        var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(TexDir + "/" + file + ".png");
        if (tex == null)
        {
            Debug.LogWarning("[Campus] 缺少法线图 " + file + "（先跑 刷新材质）");
            return;
        }
        m.SetTexture("_RGNormalBSmoothAAO", tex);
        m.SetTextureScale("_RGNormalBSmoothAAO", tile);
        m.SetTextureOffset("_RGNormalBSmoothAAO", Vector2.zero);
        m.SetFloat("_NormalScale", scale);
        m.SetFloat("_Smoothness", 1f);
    }

    static void EnsureFolders()
    {
        foreach (var d in new[] { "Assets/Campus", "Assets/Campus/Materials", "Assets/Campus/Meshes", "Assets/Campus/Textures", "Assets/Scenes" })
        {
            if (!AssetDatabase.IsValidFolder(d))
            {
                var parent = Path.GetDirectoryName(d).Replace('\\', '/');
                var name = Path.GetFileName(d);
                if (!AssetDatabase.IsValidFolder(parent)) AssetDatabase.CreateFolder("Assets", Path.GetFileName(parent));
                AssetDatabase.CreateFolder(parent, name);
            }
        }
    }

    // ---------------------------------------------------------------- 几何辅助

    const int LayerCameraNoCollision = 9; // SDK 在 TagManager 第 9 层定义为 CameraNoCollision

    static Vector3 Polar(float r, float deg)
    {
        float rad = deg * Mathf.Deg2Rad;
        return new Vector3(Mathf.Cos(rad) * r, 0, Mathf.Sin(rad) * r);
    }

    static GameObject Box(string name, Transform parent, Vector3 pos, Vector3 size, string mat)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = name;
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.transform.localScale = size;
        go.GetComponent<Renderer>().sharedMaterial = _mats[mat];
        go.isStatic = true;
        return go;
    }

    static GameObject Cyl(string name, Transform parent, float radius, float height, Vector3 pos, string mat)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        go.name = name;
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.transform.localScale = new Vector3(radius * 2f, height / 2f, radius * 2f);
        go.GetComponent<Renderer>().sharedMaterial = _mats[mat];
        go.isStatic = true;
        return go;
    }

    static GameObject Sphere(string name, Transform parent, Vector3 pos, float radius, string mat)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        go.name = name;
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.transform.localScale = Vector3.one * radius * 2f;
        go.GetComponent<Renderer>().sharedMaterial = _mats[mat];
        UnityEngine.Object.DestroyImmediate(go.GetComponent<Collider>());
        go.isStatic = true;
        return go;
    }

    static GameObject MeshDisc(string name, Transform parent, float r, int seg, Vector3 pos, string mat)
    {
        var mesh = GetMesh("Disc_" + r + "_" + seg, () => BuildDisc(r, seg));
        return PlaceMesh(name, parent, mesh, pos, mat);
    }

    static GameObject MeshRing(string name, Transform parent, float rIn, float rOut, int seg, Vector3 pos, string mat)
    {
        var mesh = GetMesh("Ring_" + rIn + "_" + rOut + "_" + seg, () => BuildRing(rIn, rIn, rOut, rOut, seg));
        return PlaceMesh(name, parent, mesh, pos, mat);
    }

    static void MeshEllipseRing(string name, Transform parent, Vector3 pos, float rxIn, float ryIn, float rxOut, float ryOut, int seg, string mat)
    {
        var mesh = GetMesh("EllipseRing_" + rxIn + "_" + ryIn + "_" + rxOut + "_" + ryOut,
            () => BuildRing(rxIn, ryIn, rxOut, ryOut, seg));
        PlaceMesh(name, parent, mesh, pos, mat);
    }

    static void MeshEllipseDisc(string name, Transform parent, Vector3 pos, float rx, float ry, int seg, string mat)
    {
        var mesh = GetMesh("EllipseDisc_" + rx + "_" + ry, () => BuildDisc(1f, seg, rx, ry));
        PlaceMesh(name, parent, mesh, pos, mat);
    }

    static GameObject PlaceMesh(string name, Transform parent, Mesh mesh, Vector3 pos, string mat)
    {
        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.AddComponent<MeshFilter>().sharedMesh = mesh;
        go.AddComponent<MeshRenderer>().sharedMaterial = _mats[mat];
        go.AddComponent<MeshCollider>().sharedMesh = mesh;
        go.isStatic = true;
        return go;
    }

    // ---------------------------------------------------------------- 低面球 / 树冠

    /// <summary>
    /// 低面数球（icosphere）。Unity 内置球是 515 面，树冠要堆一堆团块时根本用不起：
    /// 26 棵树 × 十几个团块就是十几万面。subdiv=1 只有 80 面，面分布还均匀，
    /// 堆出来的轮廓是碎块而不是光滑曲面 —— 这正是叶团想要的样子。
    /// </summary>
    static Mesh BuildIcoSphere(int subdiv)
    {
        float t = (1f + Mathf.Sqrt(5f)) * 0.5f;
        var verts = new List<Vector3>
        {
            new Vector3(-1,  t, 0), new Vector3( 1,  t, 0), new Vector3(-1, -t, 0), new Vector3( 1, -t, 0),
            new Vector3( 0, -1,  t), new Vector3( 0,  1, t), new Vector3( 0, -1, -t), new Vector3( 0,  1, -t),
            new Vector3( t,  0, -1), new Vector3( t,  0, 1), new Vector3(-t,  0, -1), new Vector3(-t,  0, 1),
        };
        for (int i = 0; i < verts.Count; i++) verts[i] = verts[i].normalized;

        var tris = new List<int>
        {
             0,11, 5,  0, 5, 1,  0, 1, 7,  0, 7,10,  0,10,11,
             1, 5, 9,  5,11, 4, 11,10, 2, 10, 7, 6,  7, 1, 8,
             3, 9, 4,  3, 4, 2,  3, 2, 6,  3, 6, 8,  3, 8, 9,
             4, 9, 5,  2, 4,11,  6, 2,10,  8, 6, 7,  9, 8, 1,
        };

        for (int s = 0; s < subdiv; s++)
        {
            var cache = new Dictionary<long, int>();
            var next = new List<int>(tris.Count * 4);
            for (int i = 0; i < tris.Count; i += 3)
            {
                int a = tris[i], b = tris[i + 1], c = tris[i + 2];
                int ab = IcoMid(verts, cache, a, b);
                int bc = IcoMid(verts, cache, b, c);
                int ca = IcoMid(verts, cache, c, a);
                next.AddRange(new[] { a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca });
            }
            tris = next;
        }

        var mesh = new Mesh();
        mesh.SetVertices(verts);
        mesh.SetTriangles(tris, 0);

        // 球面投影 UV：接缝落在背面一条线上，树冠上看不出来
        var uvs = new Vector2[verts.Count];
        for (int i = 0; i < verts.Count; i++)
        {
            var v = verts[i];
            uvs[i] = new Vector2(Mathf.Atan2(v.z, v.x) / (2f * Mathf.PI) + 0.5f, v.y * 0.5f + 0.5f);
        }
        mesh.uv = uvs;
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();
        return mesh;
    }

    static int IcoMid(List<Vector3> verts, Dictionary<long, int> cache, int a, int b)
    {
        long key = a < b ? ((long)a << 32) + b : ((long)b << 32) + a;
        if (cache.TryGetValue(key, out int idx)) return idx;
        verts.Add((verts[a] + verts[b]).normalized);
        idx = verts.Count - 1;
        cache[key] = idx;
        return idx;
    }

    /// <summary>
    /// 樱花树冠：若干低面球按黄金角螺旋铺开，再合并成**单个网格**。
    /// 合并而不是挂一堆子物体，是为了不把 Renderer 数量翻几倍（SDK 对场景对象数敏感）：
    /// 一棵树 1 个 Renderer、约 640 面，比原来 3 个内置球（1545 面）还省。
    /// </summary>
    static Mesh BuildCherryCrown(int seed, int blobs)
    {
        var ico = GetMesh("Ico_1", () => BuildIcoSphere(1));
        var rnd = new System.Random(seed);
        var parts = new List<CombineInstance>(blobs);
        const float ga = 2.399963f;   // 黄金角（弧度）

        for (int i = 0; i < blobs; i++)
        {
            float yy = 1f - (i + 0.5f) * 2f / blobs;
            float ring = Mathf.Sqrt(Mathf.Max(0f, 1f - yy * yy));
            float th = ga * i;
            var dir = new Vector3(Mathf.Cos(th) * ring, yy, Mathf.Sin(th) * ring);

            // 团块中心铺在一个扁椭球里（半轴约 0.80 / 0.30 / 0.75），加半径后
            // 外轮廓 ≈ 1.38 / 0.88 / 1.33 —— 和原来 3 球叠出来的 1.28 / 0.75 / 1.20 基本一致，只是蓬松了些
            var center = new Vector3(dir.x * 0.80f, dir.y * 0.30f, dir.z * 0.75f);
            float rad = 0.40f + (float)rnd.NextDouble() * 0.18f;
            var rot = Quaternion.Euler((float)rnd.NextDouble() * 360f, (float)rnd.NextDouble() * 360f,
                                       (float)rnd.NextDouble() * 180f);
            var scl = new Vector3(rad * (1f + (float)rnd.NextDouble() * 0.30f), rad * 0.90f, rad);

            parts.Add(new CombineInstance { mesh = ico, transform = Matrix4x4.TRS(center, rot, scl) });
        }

        var mesh = new Mesh();
        mesh.CombineMeshes(parts.ToArray(), true, true);
        // 刻意不 RecalculateNormals：合并后顶点不焊接，保留各球自己的球面法线，否则会出硬边
        mesh.RecalculateBounds();
        return mesh;
    }

    // ---------------------------------------------------------------- 路灯
    //
    // 广场原来只有"细杆 + 一颗发光球"，远看就是六个白点，谈不上氛围。
    // 现在做成复古庭院灯：底板 → 基座 → 收颈 → 灯杆 → 柱环 → 灯箱 → 四坡顶 → 顶珠。
    // 12 个金属部件合成 1 个网格，一盏灯只要 4 个 Renderer：
    // 灯体 / 灯罩 / 光晕（两片正交方片已合并）/ 地面光池。

    static Mesh PrimMesh(PrimitiveType t)
    {
        var go = GameObject.CreatePrimitive(t);
        var mesh = go.GetComponent<MeshFilter>().sharedMesh;
        UnityEngine.Object.DestroyImmediate(go);
        return mesh;
    }

    static Mesh BuildLampMetal()
    {
        var cyl = PrimMesh(PrimitiveType.Cylinder);   // 内置：半径 0.5、高 2
        var cube = PrimMesh(PrimitiveType.Cube);
        var sph = PrimMesh(PrimitiveType.Sphere);     // 内置：直径 1
        var cap = GetMesh("Lamp_Cap", () => BuildCone(0.30f, 0.26f, 4));
        var parts = new List<CombineInstance>();

        void Tube(float r, float y0, float y1)
        {
            float h = y1 - y0;
            parts.Add(new CombineInstance
            {
                mesh = cyl,
                transform = Matrix4x4.TRS(new Vector3(0f, (y0 + y1) * 0.5f, 0f), Quaternion.identity,
                    new Vector3(r * 2f, h * 0.5f, r * 2f))
            });
        }
        void Bar(float sx, float sy, float sz, float x, float y, float z)
        {
            parts.Add(new CombineInstance
            {
                mesh = cube,
                transform = Matrix4x4.TRS(new Vector3(x, y, z), Quaternion.identity, new Vector3(sx, sy, sz))
            });
        }

        Tube(0.240f, 0.00f, 0.09f);    // 底板
        Tube(0.185f, 0.09f, 0.17f);    // 基座
        Tube(0.135f, 0.17f, 0.30f);    // 基座收颈
        Tube(0.075f, 0.30f, 0.38f);    // 柱脚
        Tube(0.062f, 0.38f, 3.02f);    // 灯杆
        Tube(0.092f, 3.02f, 3.09f);    // 柱环
        Bar(0.300f, 0.045f, 0.300f, 0f, 3.115f, 0f);   // 灯箱底托

        // 四根立框围出 0.276 见方的灯箱（灯罩玻璃塞在里面）
        const float bx = 0.138f;
        Bar(0.026f, 0.44f, 0.026f, bx, 3.36f, bx);
        Bar(0.026f, 0.44f, 0.026f, -bx, 3.36f, bx);
        Bar(0.026f, 0.44f, 0.026f, bx, 3.36f, -bx);
        Bar(0.026f, 0.44f, 0.026f, -bx, 3.36f, -bx);
        Bar(0.310f, 0.030f, 0.310f, 0f, 3.59f, 0f);    // 上沿压条

        // 四坡顶：BuildCone 的底面在 y=0，绕 Y 转 45° 让四个坡面对齐灯箱四边
        parts.Add(new CombineInstance
        {
            mesh = cap,
            transform = Matrix4x4.TRS(new Vector3(0f, 3.60f, 0f), Quaternion.Euler(0f, 45f, 0f), Vector3.one)
        });
        // 顶珠
        parts.Add(new CombineInstance
        {
            mesh = sph,
            transform = Matrix4x4.TRS(new Vector3(0f, 3.90f, 0f), Quaternion.identity, Vector3.one * 0.085f)
        });

        var mesh = new Mesh();
        mesh.CombineMeshes(parts.ToArray(), true, true);
        mesh.RecalculateBounds();
        return mesh;
    }

    /// <summary>
    /// 全校园的路灯摆点。广场、校道、操场周边、教学楼两侧各成一组，密度按"走路时视线里总有 1~2 盏"控。
    /// </summary>
    static void BuildStreetLamps(Transform parent)
    {
        // 广场外圈 6 盏：避开 90°/270° 轴线，不挡教学楼与主干道视线
        for (int i = 0; i < 6; i++)
        {
            float a = i * 60f;
            var p = Polar(16.5f, a);
            StreetLamp("Lamp_Plaza_" + i, parent, new Vector3(p.x, 0f, p.z), 0.06f);
        }

        // 校道两侧各 3 盏：灯在路缘（x=±4.7），樱花树在灯外一排（x=±7.4），
        // 光池压在路面上、树只剩剪影 —— 黄昏的层次就是靠这个"内亮外暗"拉出来的
        for (int i = 0; i < 3; i++)
        {
            float z = -25.5f + i * 6f;
            StreetLamp("Lamp_AveL_" + i, parent, new Vector3(-4.7f, 0f, z), 0.06f);
            StreetLamp("Lamp_AveR_" + i, parent, new Vector3(4.7f, 0f, z), 0.06f);
        }

        // 广场 ↔ 操场 的支路口：从广场拐向操场时这一段原来全黑
        StreetLamp("Lamp_ToField_0", parent, new Vector3(-19.8f, 0f, -7.5f), 0.06f);
        StreetLamp("Lamp_ToField_1", parent, new Vector3(-19.8f, 0f, 3.5f), 0.06f);

        // 操场南侧：夹在樱花树之间（树在 x=-31/-38/-45，灯取中点），
        // 灯杆 3.9m，正好从树冠下方穿出来，不会打架
        StreetLamp("Lamp_FieldS_0", parent, new Vector3(-34.5f, 0f, -15.8f), 0.06f);
        StreetLamp("Lamp_FieldS_1", parent, new Vector3(-41.5f, 0f, -15.8f), 0.06f);

        // 看台前两盏：把看台和跑道之间那条走道照亮，也让从广场望过去有个远景亮点
        StreetLamp("Lamp_FieldN_0", parent, new Vector3(-47f, 0f, 10.4f), 0.06f);
        StreetLamp("Lamp_FieldN_1", parent, new Vector3(-29f, 0f, 10.4f), 0.06f);

        // 校门内沿墙两盏：门洞两侧的围墙内表面完全是黑的，进门时看不出校园边界在哪。
        // 注意不是"校道缺灯"——校道第二、三对灯（z=-19.5 / -13.5）本来就在门内。
        StreetLamp("Lamp_GateInL", parent, new Vector3(-11f, 0f, -20.6f), 0.06f);
        StreetLamp("Lamp_GateInR", parent, new Vector3(11f, 0f, -20.6f), 0.06f);

        // 操场西侧两盏：立在樱花树列外侧（树在 x≈-56.5），从场地望过去是把树打成剪影
        StreetLamp("Lamp_FieldW_0", parent, new Vector3(-60.5f, 0f, -6.5f), 0.06f);
        StreetLamp("Lamp_FieldW_1", parent, new Vector3(-60.5f, 0f, 3.5f), 0.06f);

        // 教学楼东西两侧各 2 盏：楼侧是长年背光面，靠这两盏把建筑"托"起来。
        // 侧翼占 x=±18..26 / z=22..32（`Bldg_WingL/R`），所以第二盏必须挪到侧翼外侧的 x=±27，
        // 一站 z=30 就会插进翼楼里 —— 这是构建时的站位自检扫出来的，截图看不出来。
        StreetLamp("Lamp_BldgE_0", parent, new Vector3(20.5f, 0f, 21f), 0.06f);
        StreetLamp("Lamp_BldgE_1", parent, new Vector3(27f, 0f, 26f), 0.06f);
        StreetLamp("Lamp_BldgW_0", parent, new Vector3(-20.5f, 0f, 21f), 0.06f);
        StreetLamp("Lamp_BldgW_1", parent, new Vector3(-27f, 0f, 26f), 0.06f);
    }

    static void StreetLamp(string name, Transform parent, Vector3 pos, float poolY)
    {
        // 站位自检：灯座半径 0.24，用 0.55 的球扫一圈，撞上已有碰撞体就报出来。
        // 摆点表是手写的坐标，很容易正好落在花坛/看台/侧墙上，光看截图不一定发现。
        Physics.SyncTransforms();
        foreach (var h in Physics.OverlapSphere(pos + Vector3.up * 0.75f, 0.55f, ~0, QueryTriggerInteraction.Ignore))
            Debug.LogWarning("[Campus] 路灯 " + name + " 与 " + h.name + " 位置冲突 @" + pos);

        var root = new GameObject(name).transform;
        root.SetParent(parent, false);
        root.localPosition = pos;

        // 灯体带 MeshCollider：灯杆是实体，玩家不该穿过去
        PlaceMesh(name + "_Body", root, GetMesh("StreetLamp_Metal", BuildLampMetal), Vector3.zero, "M_Metal");

        // 灯罩：整块暖光灯面。做成实心盒而不是四片玻璃 —— 四片之间有缝，反而露出黑暗的灯箱内部
        var glass = Box(name + "_Glass", root, new Vector3(0f, 3.36f, 0f),
            new Vector3(0.268f, 0.44f, 0.268f), "M_Emissive");
        UnityEngine.Object.DestroyImmediate(glass.GetComponent<Collider>());
        glass.layer = LayerCameraNoCollision;

        var halo = new GameObject(name + "_Halo");
        halo.transform.SetParent(root, false);
        halo.transform.localPosition = new Vector3(0f, 3.36f, 0f);
        halo.AddComponent<MeshFilter>().sharedMesh = GetMesh("Glow_Ball", () => BuildGlowBall(0.62f));
        halo.AddComponent<MeshRenderer>().sharedMaterial = _mats["M_Glow"];
        halo.layer = LayerCameraNoCollision;
        halo.isStatic = true;

        var pool = new GameObject(name + "_Pool");
        pool.transform.SetParent(root, false);
        pool.transform.localPosition = new Vector3(0f, poolY, 0f);
        pool.AddComponent<MeshFilter>().sharedMesh = GetMesh("Glow_Disc_1p9", () => BuildGlowDisc(1.9f, 40));
        pool.AddComponent<MeshRenderer>().sharedMaterial = _mats["M_Glow"];
        pool.layer = LayerCameraNoCollision;
        pool.isStatic = true;
    }

    // ---------------------------------------------------------------- 组合网格（桌椅 / 书本）
    //
    // 教室里 87 套桌椅如果按"桌面 + 2 条腿 + 凳子"各建一个 Cube，就是 348 个 Renderer。
    // 这里把每套桌椅合成 3 个网格（木件 / 铁件 / 桌上书本），Renderer 降到 261，
    // 同时还能顺手加靠背和书 —— 单个书本如果独立成物体，光阅览角就上百个 DrawCall。

    struct BoxPart
    {
        public Vector3 c, s;
        public BoxPart(float x, float y, float z, float sx, float sy, float sz)
        { c = new Vector3(x, y, z); s = new Vector3(sx, sy, sz); }
    }

    static Mesh BuildBoxCluster(BoxPart[] parts)
    {
        var v = new List<Vector3>(parts.Length * 24);
        var n = new List<Vector3>(parts.Length * 24);
        var uv = new List<Vector2>(parts.Length * 24);
        var tri = new List<int>(parts.Length * 36);
        var axes = new[] { Vector3.right, Vector3.left, Vector3.up, Vector3.down, Vector3.forward, Vector3.back };

        foreach (var p in parts)
        {
            var h = p.s * 0.5f;
            foreach (var nrm in axes)
            {
                bool yFace = Mathf.Abs(nrm.y) > 0.5f;
                bool xFace = Mathf.Abs(nrm.x) > 0.5f;
                Vector3 u = yFace ? Vector3.right * h.x : Vector3.up * h.y;
                Vector3 w = yFace ? Vector3.forward * h.z : (xFace ? Vector3.forward * h.z : Vector3.right * h.x);
                Vector3 c0 = p.c + new Vector3(nrm.x * h.x, nrm.y * h.y, nrm.z * h.z);
                int b = v.Count;
                v.Add(c0 - u - w); v.Add(c0 + u - w); v.Add(c0 + u + w); v.Add(c0 - u + w);
                for (int k = 0; k < 4; k++) n.Add(nrm);
                uv.Add(new Vector2(0f, 0f)); uv.Add(new Vector2(1f, 0f));
                uv.Add(new Vector2(1f, 1f)); uv.Add(new Vector2(0f, 1f));
                // Unity 的正面 = Cross(v1-v0, v2-v0) 与面法线同向；不同向就翻绕序
                var geo = Vector3.Cross(v[b + 1] - v[b], v[b + 2] - v[b]);
                if (Vector3.Dot(geo, nrm) >= 0f)
                { tri.Add(b); tri.Add(b + 1); tri.Add(b + 2); tri.Add(b); tri.Add(b + 2); tri.Add(b + 3); }
                else
                { tri.Add(b); tri.Add(b + 2); tri.Add(b + 1); tri.Add(b); tri.Add(b + 3); tri.Add(b + 2); }
            }
        }

        var mesh = new Mesh();
        mesh.SetVertices(v);
        mesh.SetUVs(0, uv);
        mesh.normals = n.ToArray();
        mesh.triangles = tri.ToArray();
        mesh.RecalculateBounds();
        return mesh;
    }

    static GameObject PlaceCluster(string name, Transform parent, Vector3 pos, Quaternion rot,
        Mesh mesh, string mat, bool collider)
    {
        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.transform.localRotation = rot;
        go.AddComponent<MeshFilter>().sharedMesh = mesh;
        go.AddComponent<MeshRenderer>().sharedMaterial = _mats[mat];
        if (collider) go.AddComponent<MeshCollider>().sharedMesh = mesh;
        go.isStatic = true;
        return go;
    }

    /// <summary>一排立着的书（沿局部 +x 排列，底面在 y=0）。同一网格可换材质复用，靠 seed 变化书脊高度</summary>
    /// <remarks>
    /// key 里的 V2 是给算法版本用的：GetMesh 会优先读已存在的 .asset，
    /// 改了间距/宽度却不换 key，网格不会重建（这个坑踩过两次）。
    /// </remarks>
    static Mesh BookRowMesh(int count, float width, float height, float depth, int seed)
        => GetMesh($"BookRowV2_{count}_{width:F2}_{height:F2}_{depth:F2}_{seed}", () =>
        {
            var parts = new List<BoxPart>(count);
            var rnd = new System.Random(seed);
            float gap = 0.03f;                       // 缝要看得见，否则一排书糊成一块板
            float unit = (width - gap * (count - 1)) / count;
            float x = 0f;
            for (int i = 0; i < count; i++)
            {
                float w = unit * (float)(0.62 + rnd.NextDouble() * 0.30);
                float h = height * (float)(0.62 + rnd.NextDouble() * 0.38);
                float d = depth * (float)(0.76 + rnd.NextDouble() * 0.24);
                parts.Add(new BoxPart(x + w * 0.5f, h * 0.5f, 0f, w, h, d));
                x += unit;
            }
            return BuildBoxCluster(parts.ToArray());
        });


    static Mesh GetMesh(string key, Func<Mesh> build)
    {
        if (_meshes.TryGetValue(key, out var m)) return m;
        var path = MeshDir + "/" + key + ".asset";
        var existing = AssetDatabase.LoadAssetAtPath<Mesh>(path);
        if (existing != null) { _meshes[key] = existing; return existing; }
        var mesh = build();
        mesh.name = key;
        AssetDatabase.CreateAsset(mesh, path);
        _meshes[key] = mesh;
        return mesh;
    }

    static Mesh BuildDisc(float r, int seg, float sx = 1f, float sz = 1f)
    {
        var v = new List<Vector3> { Vector3.zero };
        var uv = new List<Vector2> { new Vector2(0.5f, 0.5f) };
        var tri = new List<int>();
        for (int i = 0; i <= seg; i++)
        {
            float a = i * Mathf.PI * 2f / seg;
            v.Add(new Vector3(Mathf.Cos(a) * r * sx, 0, Mathf.Sin(a) * r * sz));
            uv.Add(new Vector2(0.5f + Mathf.Cos(a) * 0.5f, 0.5f + Mathf.Sin(a) * 0.5f));
        }
        for (int i = 1; i <= seg; i++) { tri.Add(0); tri.Add(i + 1); tri.Add(i); }
        return Finish(v, uv, tri, true);
    }

    static Mesh BuildRing(float rxIn, float ryIn, float rxOut, float ryOut, int seg)
    {
        var v = new List<Vector3>();
        var uv = new List<Vector2>();
        var tri = new List<int>();
        for (int i = 0; i <= seg; i++)
        {
            float a = i * Mathf.PI * 2f / seg;
            float c = Mathf.Cos(a), s = Mathf.Sin(a);
            v.Add(new Vector3(c * rxIn, 0, s * ryIn));
            uv.Add(new Vector2(c * rxIn * 0.05f, s * ryIn * 0.05f));
            v.Add(new Vector3(c * rxOut, 0, s * ryOut));
            uv.Add(new Vector2(c * rxOut * 0.05f, s * ryOut * 0.05f));
        }
        for (int i = 0; i < seg; i++)
        {
            int b = i * 2;
            tri.Add(b); tri.Add(b + 1); tri.Add(b + 2);
            tri.Add(b + 2); tri.Add(b + 1); tri.Add(b + 3);
        }
        return Finish(v, uv, tri, true);
    }

    static Mesh BuildCone(float r, float h, int seg)
    {
        // 保留备用：当前树冠改用球体，此方法未参与搭建
        var v = new List<Vector3>();
        var uv = new List<Vector2>();
        var tri = new List<int>();
        v.Add(Vector3.zero); uv.Add(new Vector2(0.5f, 0.5f));
        for (int i = 0; i <= seg; i++)
        {
            float a = i * Mathf.PI * 2f / seg;
            float c = Mathf.Cos(a), s = Mathf.Sin(a);
            v.Add(new Vector3(c * r, 0, s * r));
            uv.Add(new Vector2(c * 0.5f + 0.5f, s * 0.5f + 0.5f));
        }
        v.Add(new Vector3(0, h, 0)); uv.Add(new Vector2(0.5f, 1f));
        int apex = v.Count - 1;
        for (int i = 1; i <= seg; i++) { tri.Add(0); tri.Add(i); tri.Add(i + 1); }
        for (int i = 1; i <= seg; i++) { tri.Add(apex); tri.Add(i + 1); tri.Add(i); }
        return Finish(v, uv, tri, false);
    }

    static Mesh Finish(List<Vector3> v, List<Vector2> uv, List<int> tri, bool upNormals)
    {
        var mesh = new Mesh();
        mesh.SetVertices(v);
        mesh.SetUVs(0, uv);
        mesh.triangles = tri.ToArray();

        if (upNormals)
        {
            // Unity 前向面为顺时针（左手系）。若首三角的几何法线朝下，说明绕序反了，整体翻转。
            var vs = mesh.vertices;
            var ts = mesh.triangles;
            var geo = Vector3.Cross(vs[ts[1]] - vs[ts[0]], vs[ts[2]] - vs[ts[0]]);
            if (geo.y < 0f)
            {
                for (int i = 0; i < ts.Length; i += 3)
                {
                    int tmp = ts[i + 1];
                    ts[i + 1] = ts[i + 2];
                    ts[i + 2] = tmp;
                }
                mesh.triangles = ts;
            }
            var n = new Vector3[vs.Length];
            for (int i = 0; i < n.Length; i++) n[i] = Vector3.up;
            mesh.normals = n;
        }
        else
        {
            mesh.RecalculateNormals();
        }
        mesh.RecalculateBounds();
        return mesh;
    }

    // ---------------------------------------------------------------- 路灯氛围光
    //
    // 黄昏里"灯亮了"这件事，靠的不是灯罩自发光，而是三件事叠在一起：
    //   ① 灯罩本身是暖光面（M_Emissive）
    //   ② 灯头周围一圈加法光晕
    //   ③ 地面上的一滩光池
    // ②③ 必须是加法混合。用不透明自发光去做，会在暗处糊成一块贴纸：
    // 没有 alpha 就没有"光往外渗"的过渡，边缘永远是硬边。
    // 材质额度 20/20，这一格是从 M_Lamp 腾出来的（见 Palette 注释）。

    static void CreateGlowTexture()
    {
        const int N = 256;
        var t = new Texture2D(N, N, TextureFormat.RGBA32, true);
        // 径向衰减：中心白、边缘黑。加法只看 RGB，alpha 恒给 1。
        // 用 2.6 次幂而不是线性 —— 线性衰减在铺装缝上会拖出一圈灰边，幂次高才收得干净。
        Fill(t, (u, v) =>
        {
            float dx = (u - 0.5f) * 2f, dy = (v - 0.5f) * 2f;
            float k = Mathf.Clamp01(1f - Mathf.Sqrt(dx * dx + dy * dy));
            // 1.3 次幂 + 0.85 上限：光池要"一片"，不是"一个白点"。
            // 幂次给大（2.6）中心会过曝成白块，给 1 又太平均、像贴了张灰纸
            k = 0.85f * Mathf.Pow(k, 1.3f);
            return new Color(k, k, k, 1f);
        });
        SaveTex(t, TexDir + "/T_Glow.png", false, 256);
    }

    static void CreateGlowMaterial()
    {
        const string path = MatDir + "/M_Glow.mat";
        var sh = Shader.Find(GlowShader);
        if (sh == null)
        {
            Debug.LogWarning("[Campus] 找不到着色器 " + GlowShader + "，路灯氛围光会缺失");
            return;
        }
        var m = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (m == null)
        {
            m = new Material(sh);
            AssetDatabase.CreateAsset(m, path);
        }
        m.shader = sh;
        var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(TexDir + "/T_Glow.png");
        if (tex != null) m.SetTexture("_BaseTex", tex);
        m.SetVector("_BaseTexTilling", new Vector4(1f, 1f, 0f, 0f));
        m.SetVector("_BaseTexSpeed", Vector4.zero);
        // HDR 暖白（比灯罩略橙一点，光晕才不像"白雾"）。实际亮度还会被 shader 里的
        // clampResult62 乘 0.8 上限压一次，所以这里给 1.6 才够亮。
        m.SetColor("_Color", new Color(2.40f, 1.82f, 0.99f, 1f));
        m.SetFloat("_AlphaFix", 1f);
        // 视角衰减指数：pow(saturate(N·V), w)。这个值直接决定光晕"是团雾还是一块圆饼"——
        // 给 1.2 时球面从中心到轮廓只衰减到 0.37，整块几乎是均匀的，边界一眼就看得出来
        //（近距离看就是一块半透明圆饼）；给 2.2 以上边缘是干净了，但光球缩成一个小点，
        // 广场全景里路灯全变成小黄方块。1.8 是两头的折中。
        // 代价是贴地的光池在低角度会暗（N·V≈0.47），所以 _Color 从 1.55 提到 2.4 补回来。
        m.SetFloat("_FresnelWidth", 1.8f);
        // 相机贴身淡出距离（米）。默认 5 会把 5m 内的光池整片压暗，这里收到 1m
        m.SetFloat("_DisappearDistance", 1f);
        // 深度淡化距离：光池离地只有几厘米，这个值必须极小，
        // 否则 abs(场景深度-自身深度)/该值 恒小于 1，整片光池被按比例压黑
        m.SetFloat("_DepthFadeDistance", 0.002f);
        // 只画正面：光球只留朝向相机的那半球，dot<0 的背面本来就该是 0，
        // 画出来还会在中心叠两层、叠出一圈硬边
        m.SetFloat("_CullMode", 2f);
        EditorUtility.SetDirty(m);
        _mats["M_Glow"] = m;
    }

    static Mesh BuildGlowDisc(float r, int seg)
    {
        var v = new List<Vector3> { Vector3.zero };
        var uv = new List<Vector2> { new Vector2(0.5f, 0.5f) };
        var tri = new List<int>();
        for (int i = 0; i <= seg; i++)
        {
            float a = i * Mathf.PI * 2f / seg;
            v.Add(new Vector3(Mathf.Cos(a) * r, 0f, Mathf.Sin(a) * r));
            uv.Add(new Vector2(0.5f + Mathf.Cos(a) * 0.5f, 0.5f + Mathf.Sin(a) * 0.5f));
        }
        for (int i = 1; i <= seg; i++) { tri.Add(0); tri.Add(i + 1); tri.Add(i); }
        return FinishGlow(v, uv, tri);
    }

    /// <summary>灯头周围的光球：低面球 + UV 全部钉在贴图中心。</summary>
    /// <remarks>
    /// 一开始用的是"两片正交方片"。贴着看像星芒，侧着看是一条横光斑 —— 因为 VFX_Add01 的
    /// 亮度乘了 pow(N·V, w)，方片的法线是固定的，转到侧面就被压成一条线。
    /// 改用球体：法线朝外，任何角度看都是中间亮、边缘自然归零的一团柔光，不需要 billboard。
    /// UV 全钉在 (0.5,0.5) 是为了让贴图恒为径向衰减的中心值 —— 球面 UV 是经纬展开的，
    /// 直接用会缠出一条条纬线。
    /// </remarks>
    static Mesh BuildGlowBall(float r, float uvU = 0.75f)
    {
        var src = GetMesh("Ico_1", () => BuildIcoSphere(1));
        var sv = src.vertices;
        var v = new List<Vector3>(sv.Length);
        var n = new List<Vector3>(sv.Length);
        var uv = new List<Vector2>(sv.Length);
        for (int i = 0; i < sv.Length; i++)
        {
            v.Add(sv[i] * r);
            // 法线必须重新取"归一化位置"，不能用网格自带的。icosphere 是非索引的逐面法线
            //（树冠那边正需要这种硬朗的面感），拿来做光球就变成 80 个平切面 ——
            // 每面亮度恒定、轮廓是个多边形，近看就是一块边缘生硬的半透明圆盘。
            // 用球面法线 dot(N,V) 才会连续变化，光晕才收得干净。
            n.Add(sv[i].normalized);
            // 不取贴图正中心（值 0.85），取半径 0.5 处（约 0.35）：光球要比光池暗一档，
            // 否则叠在已经接近纯白的灯罩上会糊成一个白球，灯型直接消失。
            // 一个材质同时伺候光球和光池，靠的就是这处 UV 偏移来分配亮度。
            // 烟花火星要反过来 —— 它就该是最亮的，所以调用时传 uvU=0.5。
            uv.Add(new Vector2(uvU, 0.5f));
        }
        return FinishGlow(v, uv, new List<int>(src.triangles), n);
    }

    /// <summary>加法光效专用网格：必须带白顶点色。</summary>
    /// <remarks>
    /// VFX_Add01 的最终颜色乘了 IN.ase_color（含 alpha）。没有 color 通道的网格在部分平台
    /// 拿到的是 (0,0,0,0)，整片光效会静默变成全黑 —— 这个坑只有上机才看得出来。
    /// </remarks>
    static Mesh FinishGlow(List<Vector3> v, List<Vector2> uv, List<int> tri, List<Vector3> n = null)
    {
        var m = new Mesh();
        m.SetVertices(v);
        m.SetUVs(0, uv);
        m.SetTriangles(tri, 0);
        if (n != null) m.SetNormals(n);
        else m.RecalculateNormals();
        var c = new List<Color>(v.Count);
        for (int i = 0; i < v.Count; i++) c.Add(Color.white);
        m.SetColors(c);
        m.RecalculateBounds();
        return m;
    }

    // ---------------------------------------------------------------- 预览截图

    /// <summary>批处理入口：搭建 + 截图一次完成。</summary>
    public static void RunAll()
    {
        Build();
        CaptureAll();
        DiagnosePath();          // 顺带跑通路/海报朝向诊断，省一次完整构建
        PersistRenderSettings(); // 天空盒/雾要再存一次才会留在场景里
    }

    // ---------------------------------------------------------------- 自由视角相机
    //
    // 相机对象只在 Play 模式里创建：退出播放时场景回滚，它就自动消失，
    // 绝不会被保存进 Campus.unity（否则会被打进抖音世界）。
    // 跨越域重载用 SessionState 传标记，静态字段在进入 Play 时会被重置。

    const string FreeCamName = "Preview_FreeCam";
    const string FreeCamPendingKey = "Campus_FreeCamPending";

    [InitializeOnLoadMethod]
    static void HookFreeCam()
    {
        EditorApplication.playModeStateChanged -= OnPlayModeChanged;
        EditorApplication.playModeStateChanged += OnPlayModeChanged;
    }

    static void OnPlayModeChanged(PlayModeStateChange state)
    {
        if (state == PlayModeStateChange.EnteredPlayMode && SessionState.GetBool(FreeCamPendingKey, false))
        {
            SessionState.SetBool(FreeCamPendingKey, false);
            SpawnFreeCam();
        }
    }

    [MenuItem("抖音虚拟创作SDK/校园：开启自由视角（Play 模式）")]
    public static void OpenFreeCam()
    {
        if (EditorApplication.isPlaying)
        {
            SpawnFreeCam();
            return;
        }
        if (EditorSceneManager.GetActiveScene().path != ScenePath)
            EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        SessionState.SetBool(FreeCamPendingKey, true);
        EditorApplication.isPlaying = true;
    }

    [MenuItem("抖音虚拟创作SDK/校园：移除自由视角相机")]
    public static void RemoveFreeCam()
    {
        var go = GameObject.Find(FreeCamName);
        if (go != null) UnityEngine.Object.DestroyImmediate(go);
        Debug.Log("[Campus] 自由视角相机已移除");
    }

    /// <summary>
    /// 天空方位探针：朝 8 个方位各渲一张，用来确认"等距柱状贴图的 u 对应世界哪个方位"。
    /// 换天空盒时必须先跑这个 —— 否则太阳会出现在背光的一侧。
    /// 输出 _preview_skyprobe_&lt;序号&gt;_az&lt;角度&gt;.png，az 从 +Z 起算（az=0 看向 +Z）。
    /// </summary>
    [MenuItem("抖音虚拟创作SDK/校园：天空方位探针")]
    public static void SkyProbe()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        DynamicGI.UpdateEnvironment();
        var eye = new Vector3(0f, 26f, 0f);
        for (int i = 0; i < 8; i++)
        {
            float az = i * 45f;
            var dir = Quaternion.Euler(0f, az, 0f) * Vector3.forward;
            Capture("skyprobe_" + i + "_az" + az.ToString("000"), eye, eye + dir * 60f, 40f);
        }
        Debug.Log("[Campus] 天空方位探针完成（az 以 +Z 为 0）");
    }

    /// <summary>查 RenderSettings（天空盒/雾）到底能不能存进场景</summary>
    public static void TestPersist()
    {
        var sb = new StringBuilder();
        var sc = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        sb.AppendLine("load: sky=" + (RenderSettings.skybox != null ? RenderSettings.skybox.name : "null") + " fog=" + RenderSettings.fog);
        var sky = AssetDatabase.LoadAssetAtPath<Material>(DuskSkybox);
        RenderSettings.skybox = sky;
        RenderSettings.fog = true;
        RenderSettings.fogMode = FogMode.Linear;
        EditorSceneManager.MarkSceneDirty(sc);
        EditorSceneManager.SaveScene(sc, ScenePath);
        sb.AppendLine("after save: sky=" + (RenderSettings.skybox != null ? RenderSettings.skybox.name : "null") + " fog=" + RenderSettings.fog);
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        sb.AppendLine("reopen: sky=" + (RenderSettings.skybox != null ? RenderSettings.skybox.name : "null") + " fog=" + RenderSettings.fog);
        System.IO.File.WriteAllText("D:/DouyinWorld2021/_persist_diag.txt", sb.ToString(), new UTF8Encoding(false));
    }

    /// <summary>批处理里验证自由相机的生成逻辑（不进 Play 模式，只看组件是否齐全）</summary>
    public static void VerifyFreeCam()
    {
        SpawnFreeCam();
        var go = GameObject.Find(FreeCamName);
        if (go == null)
        {
            System.IO.File.WriteAllText("D:/DouyinWorld2021/_freecam_diag.txt", "[FreeCam] 相机没生成", new UTF8Encoding(false));
            return;
        }
        var cam = go.GetComponent<Camera>();
        var data = go.GetComponent<UniversalAdditionalCameraData>();
        var ctl = go.GetComponent<CampusFreeCam>();
        string report = $"[FreeCam] camera={cam != null} urpData={data != null} controller={ctl != null} " +
                        $"pos={go.transform.position} fov={(cam != null ? cam.fieldOfView : 0)} " +
                        $"listener={go.GetComponent<AudioListener>() != null}";
        UnityEngine.Object.DestroyImmediate(go);
        report += "\n[FreeCam] 生成逻辑验证完成，已清理";
        System.IO.File.WriteAllText("D:/DouyinWorld2021/_freecam_diag.txt", report, new UTF8Encoding(false));
    }

    static void SpawnFreeCam()    {
        var old = GameObject.Find(FreeCamName);
        if (old != null) UnityEngine.Object.DestroyImmediate(old);

        var go = new GameObject(FreeCamName);
        // 出生点：广场东侧，斜看向教学楼入口，和 01_plaza 机位接近
        go.transform.position = new Vector3(12f, 3.4f, 8f);
        go.transform.LookAt(new Vector3(-2f, 2.2f, 17f));

        var cam = go.AddComponent<Camera>();
        cam.fieldOfView = 62f;
        cam.nearClipPlane = 0.05f;
        cam.farClipPlane = 600f;
        cam.allowHDR = true;
        if (go.GetComponent<UniversalAdditionalCameraData>() == null)
            go.AddComponent<UniversalAdditionalCameraData>();
        if (UnityEngine.Object.FindObjectOfType<AudioListener>() == null)
            go.AddComponent<AudioListener>();

        go.AddComponent<CampusFreeCam>();
        Debug.Log("[Campus] 自由视角已就绪：右键拖动转视角 / WASD 移动 / QE 升降 / Shift 加速 / 滚轮调速 / R 复位");
    }

    /// <summary>
    /// 楼梯连通性诊断：沿"一层 → 一跑 → 休息平台 → 二跑 → 二层楼板"这条真实走法逐点向下打射线。
    /// 判据只有两条：任何一点打不到碰撞体 = 踩空；相邻采样高差 &gt; 0.32 = 台阶错位（会卡住或弹一下）。
    /// </summary>
    [MenuItem("抖音虚拟创作SDK/校园：诊断楼梯连通性")]
    public static void DiagnoseStairs()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        var sb = new StringBuilder();
        sb.AppendLine("## 楼梯连通性（一跑 A → 平台 L → 二跑 B → 二层 F2）");
        sb.AppendLine("采样规则：沿走路方向每 0.15m 一点；从\"该处应有的高度 +0.7\"往下打射线，");
        sb.AppendLine("这样不会被屋顶/上层楼板截住。delta = 实际落点 - 应有高度。");

        const float stepH = 0.1654f, stepD = 0.25f;
        float mid0 = F1 + 13f * stepH;      // 一跑顶 / 平台 = 3.350

        var pts = new List<Vector3>();
        var exp = new List<float>();
        var tags = new List<string>();

        const float zStart = 25.4f;                 // 一跑起步 = 二跑落点 = 楼板洞口南沿
        const float zTop = zStart + 13f * stepD;    // 28.65 平台南沿

        // 一跑：z 25.3 → 28.7，第 i 级顶面 = F1 + (i+1)*stepH
        for (float z = zStart - 0.1f; z <= zTop + 0.05f; z += 0.15f)
        {
            int i = Mathf.Clamp(Mathf.FloorToInt((z - zStart) / stepD), 0, 12);
            pts.Add(new Vector3(14.65f, 0, z)); exp.Add(F1 + (i + 1) * stepH); tags.Add("A ");
        }
        // 休息平台：整宽走一遍，高度 = mid0
        for (float x = 13.85f; x <= 17.35f; x += 0.15f)
        { pts.Add(new Vector3(x, 0, zTop + 0.85f)); exp.Add(mid0); tags.Add("L "); }
        // 二跑：z 28.7 → 25.3，第 i 级顶面 = mid0 + (i+1)*stepH
        for (float z = zTop + 0.05f; z >= zStart - 0.1f; z -= 0.15f)
        {
            int i = Mathf.Clamp(Mathf.FloorToInt((zTop - z) / stepD), 0, 12);
            pts.Add(new Vector3(16.62f, 0, z)); exp.Add(mid0 + (i + 1) * stepH); tags.Add("B ");
        }
        // 二层楼板（落地后往里走）
        for (float x = 16.4f; x >= 13.6f; x -= 0.15f)
        { pts.Add(new Vector3(x, 0, 24.6f)); exp.Add(F2); tags.Add("F2"); }

        float prev = float.NaN;
        int gaps = 0, jumps = 0, bad = 0;
        for (int i = 0; i < pts.Count; i++)
        {
            var p = pts[i];
            var from = new Vector3(p.x, exp[i] + 0.7f, p.z);
            string who = "（脚下 2.5m 内没有碰撞体）";
            float top = float.NaN;
            if (Physics.Raycast(from, Vector3.down, out var h, 2.5f, ~0, QueryTriggerInteraction.Ignore))
            {
                top = h.point.y;
                who = h.collider.name;
            }

            string mark = "";
            // 净空：从脚下 5cm 往上打 1.9m，打不到东西才算能站人（转弯平台头顶就是二跑，最容易被堵）
            string head = "";
            if (!float.IsNaN(top))
            {
                bool hitUp = Physics.Raycast(new Vector3(p.x, top + 0.05f, p.z), Vector3.up, out var hu, 1.9f,
                    ~0, QueryTriggerInteraction.Ignore);
                if (hitUp) { head = $"   <<< 净空不足 {hu.distance + 0.05f:F2}m（{hu.collider.name}）"; bad++; }
            }

            if (float.IsNaN(top)) { mark = "   <<< 踩空"; gaps++; }
            else
            {
                float d = top - exp[i];
                if (d < -0.30f) { mark = $"   <<< 脚下低了 {d:0.00}（踩空/掉下去）"; bad++; }
                else if (d > 0.30f) { mark = $"   <<< 脚下高了 {d:+0.00}（有东西挡/台阶错位）"; bad++; }
                if (!float.IsNaN(prev) && Mathf.Abs(top - prev) > 0.25f)
                { mark += $"  [突变 {top - prev:+0.00;-0.00}]"; jumps++; }
            }

            sb.AppendLine($"  [{tags[i]}] x={p.x,6:F2} z={p.z,6:F2}  应有={exp[i]:F3}  实际={(float.IsNaN(top) ? " ----" : top.ToString("F3"))}  {who}{mark}{head}");
            if (!float.IsNaN(top)) prev = top;
        }
        sb.AppendLine($"合计：采样 {pts.Count} 点，踩空 {gaps} 点，高低错位 {bad} 点，相邻突变 {jumps} 点");

        // 两处接头的竖向命中清单：第一个命中就是玩家踩的面
        sb.AppendLine("--- 竖向命中链（从上往下，第一个 = 踩到的面）---");
        float zMid = 25.4f + 13f * stepD;
        foreach (var probe in new[] { ("一跑顶端  ", 14.65f, zMid - 0.05f, mid0),
                                      ("平台西侧  ", 14.20f, zMid + 0.85f, mid0),
                                      ("平台东侧  ", 17.20f, zMid + 0.85f, mid0),
                                      ("二跑底端  ", 16.62f, zMid - 0.05f, mid0 + stepH),
                                      ("二跑顶端  ", 16.62f, 25.45f, mid0 + 13f * stepH),
                                      ("二层楼板  ", 16.62f, 25.10f, F2) })
        {
            var o = new Vector3(probe.Item2, probe.Item4 + 0.7f, probe.Item3);
            var line = $"  {probe.Item1} ";
            bool any = false;
            for (int k = 0; k < 6; k++)
            {
                if (!Physics.Raycast(o, Vector3.down, out var h, 20f, ~0, QueryTriggerInteraction.Ignore)) break;
                line += $"{h.collider.name}@{h.point.y:F2} ";
                any = true;
                o = h.point + Vector3.down * 0.02f;
            }
            sb.AppendLine(line + (any ? "" : "（空）"));
        }

        File.WriteAllText("D:/DouyinWorld2021/_stairs_diag.txt", sb.ToString(), new UTF8Encoding(false));
        Debug.Log(sb.ToString());
    }

    /// <summary>验收用：校名牌特写 + 操场平视 + 樱花道</summary>
    [MenuItem("抖音虚拟创作SDK/校园：预览校名与操场")]
    public static void PreviewSakura()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        Capture("40_gate_sign", new Vector3(0f, 4.1f, -31.5f), new Vector3(0f, 5.3f, -23f), 42f);
        Capture("41_field_walk", new Vector3(-19.5f, 1.85f, -9.5f), new Vector3(-38f, 2.4f, -1f), 62f);
        Capture("42_cherry_avenue", new Vector3(1.5f, 2.1f, -29f), new Vector3(-8f, 3.4f, -10f), 58f);
        Capture("43_plaza_cherry", new Vector3(16f, 3.4f, -18f), new Vector3(-6f, 3.2f, 4f), 62f);
    }

    /// <summary>诊断：NPC 的名牌/气泡 quad 是否真的有网格、材质、正确的 UV 与朝向</summary>
    [MenuItem("抖音虚拟创作SDK/校园：诊断 NPC")]
    public static void DiagnoseNpc()
    {
        var sb = new StringBuilder();
        var sc = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

        var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(TexDir + "/T_NpcLines.png");
        sb.AppendLine("图集 T_NpcLines = " + (tex == null ? "<缺失>" : tex.width + "x" + tex.height));
        var mat = AssetDatabase.LoadAssetAtPath<Material>(MatDir + "/M_NpcLine.mat");
        sb.AppendLine("材质 M_NpcLine  = " + (mat == null ? "<缺失>" :
            "tex=" + (mat.GetTexture("_BasecoloTex_AMeta") == null ? "无" : mat.GetTexture("_BasecoloTex_AMeta").name) +
            " shader=" + mat.shader.name));

        for (int i = 1; i <= NpcSpecs.Length; i++)
        {
            string id = "NPC_" + i.ToString("00");
            var go = GameObject.Find(id);
            if (go == null) { sb.AppendLine(id + " = <缺失>"); continue; }

            var label = go.transform.Find("Label");
            var nameQ = go.transform.Find("Label/NameQuad");
            var bubble = go.transform.Find("Label/Bubble");
            int lineCount = bubble == null ? 0 : bubble.childCount;

            sb.AppendLine("--- " + id + " (" + NpcSpecs[i - 1].Name + ")");
            sb.AppendLine("  pos=" + go.transform.position.ToString("F2") +
                " scale=" + go.transform.lossyScale.ToString("F2") +
                " label=" + (label == null ? "缺" : label.rotation.eulerAngles.ToString("F0")));
            sb.AppendLine("  名字quad " + (nameQ == null ? "缺失" :
                "mesh=" + nameQ.GetComponent<MeshFilter>().sharedMesh.name +
                " uv0=" + nameQ.GetComponent<MeshFilter>().sharedMesh.uv[0].ToString("F3") +
                " 世界尺寸=" + (nameQ.GetComponent<MeshRenderer>().bounds.size.ToString("F2"))));
            sb.AppendLine("  气泡 " + (bubble == null ? "缺失" : "lineCount=" + lineCount + " active=" + bubble.gameObject.activeSelf));

            if (bubble != null && lineCount > 0)
            {
                var l0 = bubble.GetChild(0);
                var mf = l0.GetComponent<MeshFilter>();
                sb.AppendLine("    Line_01 mesh=" + (mf == null || mf.sharedMesh == null ? "缺" : mf.sharedMesh.name) +
                    " uv0=" + (mf == null || mf.sharedMesh == null ? "-" : mf.sharedMesh.uv[0].ToString("F3")) +
                    " 世界尺寸=" + l0.GetComponent<MeshRenderer>().bounds.size.ToString("F2"));
            }
        }

        File.WriteAllText("D:/DouyinWorld2021/_npc_diag.txt", sb.ToString(), new UTF8Encoding(false));
    }

    /// <summary>材质审计：每个材质被多少个渲染器引用，以及玻璃球到底挂在谁身上</summary>
    public static void MaterialAudit()
    {
        var sb = new StringBuilder();
        var scene = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

        var byMat = new Dictionary<string, int>();
        var byMatOwner = new Dictionary<string, List<string>>();
        foreach (var r in UnityEngine.Object.FindObjectsOfType<MeshRenderer>(true))
        {
            foreach (var m in r.sharedMaterials)
            {
                if (m == null) continue;
                byMat[m.name] = byMat.TryGetValue(m.name, out var c) ? c + 1 : 1;
                if (!byMatOwner.ContainsKey(m.name)) byMatOwner[m.name] = new List<string>();
                if (byMatOwner[m.name].Count < 6) byMatOwner[m.name].Add(r.transform.root.name + "/" + r.name);
            }
        }

        sb.AppendLine("场景 MeshRenderer 材质计数：");
        foreach (var kv in byMat.OrderByDescending(k => k.Value))
            sb.AppendLine(string.Format("  {0,-14} {1,4}  {2}", kv.Key, kv.Value,
                string.Join(" | ", byMatOwner[kv.Key])));

        sb.AppendLine();
        sb.AppendLine("玻璃矩阵（父链 + prefab 归属）：");
        foreach (var r in UnityEngine.Object.FindObjectsOfType<MeshRenderer>(true))
        {
            if (r.sharedMaterial == null || !r.sharedMaterial.name.StartsWith("Glass_mat")) continue;
            var path = r.name;
            var t = r.transform;
            while (t.parent != null) { path = t.parent.name + "/" + path; t = t.parent; }
            string prefabRoot = PrefabUtility.GetOutermostPrefabInstanceRoot(r.gameObject) != null
                ? PrefabUtility.GetOutermostPrefabInstanceRoot(r.gameObject).name : "-";
            string prefabType = PrefabUtility.GetPrefabInstanceStatus(r.gameObject).ToString();
            sb.AppendLine("  " + path + "  mat=" + r.sharedMaterial.name + "  外层prefab=" + prefabRoot + "  状态=" + prefabType);
        }

        File.WriteAllText("D:/DouyinWorld2021/_mat_audit.txt", sb.ToString(), new UTF8Encoding(false));
        Debug.Log("[Campus] material audit -> _mat_audit.txt");
    }

    /// <summary>让女主角转向某个机位（模拟她迎上来后面对玩家的样子）</summary>
    static void FaceStar(Vector3 camPos)
    {
        var go = GameObject.Find("NPC_08");
        if (go == null) return;
        go.transform.LookAt(new Vector3(camPos.x, go.transform.position.y, camPos.z));
    }

    /// <summary>把她的四肢摆成行走中的某一帧（静态截图看不出"她真的会走"）</summary>
    static void PoseStarWalk(float swing)
    {
        var go = GameObject.Find("NPC_08");
        if (go == null) return;
        var model = go.transform.Find("Model");
        if (model == null) return;

        foreach (var (name, ang) in new[] { ("LegL", swing), ("LegR", -swing),
                                            ("ArmL", -swing * 0.95f), ("ArmR", swing * 0.95f) })
        {
            var t = model.Find(name);
            if (t != null) t.localRotation = Quaternion.Euler(ang, 0f, 0f);
        }
        model.localPosition = new Vector3(0f, 0.03f, 0f);
        model.localRotation = Quaternion.identity;
    }

    /// <summary>验收用：黄思诚的造型、站姿、名牌与台词</summary>
    [MenuItem("抖音虚拟创作SDK/校园：预览女主角（黄思诚）")]
    public static void PreviewStar()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

        // 全身，正面对她（她迎上来的第一眼）
        var cam60 = new Vector3(1.5f, 1.5f, -10.2f);
        FaceStar(cam60);
        ForceSpeak(8, 0);
        AimNpcLabels(cam60, new Vector3(1.5f, 1.1f, -5.8f));
        Capture("60_star_full", cam60, new Vector3(1.5f, 1.02f, -5.8f), 42f);

        // 上半身特写：短上衣 / 露腰 / choker / 挑染 / 头顶墨镜
        var cam61 = new Vector3(1.5f, 1.62f, -8.1f);
        FaceStar(cam61);
        ForceSpeak(8, 2);
        AimNpcLabels(cam61, new Vector3(1.5f, 1.5f, -5.8f));
        Capture("61_star_closeup", cam61, new Vector3(1.5f, 1.46f, -5.8f), 36f);

        // 侧后方 45°：看发型走向、腰线高度、阔腿裤的轮廓
        var cam62 = new Vector3(-1.0f, 1.56f, -8.7f);   // 西南侧：夕阳在这一侧，能看清轮廓
        FaceStar(cam62);
        ForceSpeak(8, 4);
        AimNpcLabels(cam62, new Vector3(1.5f, 1.15f, -5.8f));
        Capture("62_star_side", cam62, new Vector3(1.5f, 1.10f, -5.8f), 44f);

        // 行走帧：她跟着你走的时候是什么样
        var cam63 = new Vector3(2.2f, 1.52f, -10.6f);
        FaceStar(cam63);
        PoseStarWalk(24f);
        ForceSpeak(8, 3);
        AimNpcLabels(cam63, new Vector3(1.5f, 1.1f, -5.8f));
        Capture("63_star_walk", cam63, new Vector3(1.5f, 1.05f, -5.8f), 42f);
    }

    /// <summary>让所有 NPC 的名牌转向指定机位（模拟 Lua 每帧的 billboard）</summary>
    static void AimNpcLabels(Vector3 camPos, Vector3 look)
    {
        for (int i = 1; i <= NpcSpecs.Length + 1; i++)   // +1：女主角 NPC_08
        {
            var go = GameObject.Find("NPC_" + i.ToString("00"));
            if (go == null) continue;
            var lb = go.transform.Find("Label");
            if (lb != null) lb.LookAt(camPos);   // quad 正面朝 +Z，LookAt 正好把 +Z 转向相机
        }
    }

    /// <summary>把第 i 个 NPC 摆成"正在说话"的样子（气泡打开 + 填一句台词）</summary>
    static void ForceSpeak(int index, int lineIndex = 0)
    {
        var go = GameObject.Find("NPC_" + index.ToString("00"));
        if (go == null) return;
        var bubble = go.transform.Find("Label/Bubble");
        if (bubble == null) return;
        bubble.gameObject.SetActive(true);
        for (int k = 0; k < bubble.childCount; k++)
            bubble.GetChild(k).gameObject.SetActive(k == lineIndex);
    }

    /// <summary>验收用：七个 NPC 的外观、比例、名牌与气泡</summary>
    [MenuItem("抖音虚拟创作SDK/校园：预览 NPC")]
    public static void PreviewNpc()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

        // 樱花道：两个 NPC 对向走，让其中一个正在说话
        ForceSpeak(1, 0);
        ForceSpeak(2, 0);
        AimNpcLabels(new Vector3(0.6f, 1.75f, -26.5f), new Vector3(0f, 1.4f, -16f));
        Capture("50_npc_avenue", new Vector3(0.6f, 1.75f, -26.5f), new Vector3(0f, 1.35f, -16f), 58f);

        // 单个 NPC 的中近距离特写：看人形比例 / 关节 / 发型
        ForceSpeak(1, 0);
        var cam51 = new Vector3(4.35f, 1.62f, -17.9f);
        var npc01 = GameObject.Find("NPC_01");
        if (npc01 != null) npc01.transform.LookAt(new Vector3(cam51.x, npc01.transform.position.y, cam51.z));
        AimNpcLabels(cam51, new Vector3(1.9f, 1.30f, -21.5f));
        Capture("51_npc_closeup", cam51, new Vector3(1.9f, 1.26f, -21.5f), 44f);

        // 广场绕圈的苏晚
        ForceSpeak(3, 2);
        AimNpcLabels(new Vector3(6.6f, 1.9f, 4.6f), new Vector3(12f, 1.35f, 0f));
        Capture("52_npc_plaza", new Vector3(6.6f, 1.9f, 4.6f), new Vector3(12f, 1.30f, 0f), 52f);

        // 操场跑道的陈野
        ForceSpeak(4, 1);
        AimNpcLabels(new Vector3(-18.5f, 1.85f, -5.5f), new Vector3(-22.8f, 1.35f, -2f));
        Capture("53_npc_field", new Vector3(-18.5f, 1.85f, -5.5f), new Vector3(-22.8f, 1.30f, -2f), 55f);

        // 教学楼台阶前的何老师
        ForceSpeak(5, 0);
        AimNpcLabels(new Vector3(2.4f, 1.8f, 9.4f), new Vector3(7f, 1.35f, 15.5f));
        Capture("54_npc_teacher", new Vector3(2.4f, 1.8f, 9.4f), new Vector3(7f, 1.30f, 15.5f), 55f);

        // 一层走廊的阿澄
        ForceSpeak(6, 0);
        AimNpcLabels(new Vector3(2.0f, F1 + 1.62f, 21.4f), new Vector3(11f, F1 + 1.2f, 21.4f));
        Capture("55_npc_corridor", new Vector3(2.0f, F1 + 1.62f, 21.4f), new Vector3(11f, F1 + 1.15f, 21.4f), 58f);

        // 校门内的门卫
        ForceSpeak(7, 0);
        AimNpcLabels(new Vector3(0.4f, 1.7f, -16.4f), new Vector3(4.2f, 1.35f, -21f));
        Capture("56_npc_guard", new Vector3(0.4f, 1.7f, -16.4f), new Vector3(4.2f, 1.30f, -21f), 52f);
    }

    /// <summary>验收用：楼梯接头四个机位（一跑顶仰视 / 平台上平视 / 一层平台下方 / 二层落地口）</summary>
    [MenuItem("抖音虚拟创作SDK/校园：预览楼梯接头")]
    public static void PreviewStairs()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        Capture("30_stair_up", new Vector3(15.0f, 2.55f, 23.9f), new Vector3(14.9f, 3.6f, 28.6f), 68f);
        Capture("31_stair_landing", new Vector3(15.7f, 4.95f, 30.1f), new Vector3(15.4f, 3.2f, 27.4f), 72f);
        Capture("32_stair_under", new Vector3(16.1f, 2.2f, 26.2f), new Vector3(15.4f, 3.6f, 29.8f), 72f);
        Capture("33_stair_top2f", new Vector3(11.2f, 7.05f, 24.2f), new Vector3(15.9f, 5.4f, 28.6f), 66f);
        Capture("34_stair_arrive", new Vector3(15.6f, 7.0f, 21.3f), new Vector3(16.35f, 4.9f, 26.9f), 62f);
        Capture("35_stair_seam", new Vector3(16.55f, 6.15f, 24.4f), new Vector3(16.55f, 5.5f, 26.2f), 62f);
    }

    /// <summary>
    /// 交付区可达性诊断：玩家必须能站在 CollectStation 的触发盒里，否则收集逻辑永远不会触发。
    /// 1) 列出触发盒内部所有碰撞体（实体碰撞体会把玩家挡在外面）
    /// 2) 从架前 4m 一路朝 +z 打射线，看每一列被什么先撞到
    /// </summary>
    [MenuItem("抖音虚拟创作SDK/校园：诊断交付区可达性")]
    public static void DiagnoseDelivery()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        var sb = new StringBuilder();
        sb.AppendLine("## 交付区可达性 DiagnosticDelivery");

        var station = GameObject.Find("CollectStation");
        var shelf = GameObject.Find("CollectShelf");
        if (station == null) { sb.AppendLine("CollectStation 缺失"); Debug.Log(sb.ToString()); return; }

        var box = station.GetComponent<BoxCollider>();
        var c = station.transform.TransformPoint(box.center);
        var size = Vector3.Scale(box.size, station.transform.lossyScale);
        sb.AppendLine($"触发盒 world center={c} size={size}");

        var hits = Physics.OverlapBox(c, size * 0.5f, station.transform.rotation, ~0, QueryTriggerInteraction.Collide);
        var groups = hits.GroupBy(h => h.transform.root == null ? h.name : h.name)
            .Select(g => g.Key + "×" + g.Count()).OrderBy(s => s);
        sb.AppendLine("盒内碰撞体 = " + string.Join(", ", groups));

        var solid = hits.Where(h => !h.isTrigger && h.transform != station.transform)
            .Select(h => h.name + " @" + h.bounds.center.ToString("F2") + " size " + h.bounds.size.ToString("F2"))
            .Distinct();
        sb.AppendLine("盒内实体碰撞（会挡玩家）= " + (solid.Any() ? string.Join(" | ", solid) : "无"));

        sb.AppendLine("--- 从走廊朝 -z 进门的射线（起点 z=22.0, y=1.6）---");
        for (float x = -5.6f; x <= -2.1f; x += 0.5f)
        {
            var o = new Vector3(x, 1.6f, 22.0f);
            var line = $"  x={x,6:F1} ";
            bool any = false;
            var origin = o;
            for (int k = 0; k < 6; k++)
            {
                if (!Physics.Raycast(origin, Vector3.back, out var h, 12f, ~0, QueryTriggerInteraction.Collide)) break;
                line += $"{h.collider.name}({h.distance:F2}m){(h.collider.isTrigger ? "[T]" : "")} ";
                any = true;
                origin = h.point + Vector3.back * 0.02f;
            }
            if (!any) line += "（空）";
            sb.AppendLine(line);
        }

        // 玩家胶囊（r=0.3, 高 1.8）能否站在格子点上；[ ] 标出触发盒范围
        sb.AppendLine("--- 站立可行性图（r=0.3 胶囊，●可站 ×被挡，[ ]=触发盒内）---");
        float minX = c.x - size.x * 0.5f, maxX = c.x + size.x * 0.5f;
        float minZ = c.z - size.z * 0.5f, maxZ = c.z + size.z * 0.5f;
        int standableInTrigger = 0;
        sb.AppendLine($"   触发盒 x[{minX:F2},{maxX:F2}] z[{minZ:F2},{maxZ:F2}]");
        for (float z = 19.9f; z >= 17.6f; z -= 0.3f)
        {
            var row = new StringBuilder($"  z={z,6:F2} ");
            for (float x = -5.7f; x <= -1.4f; x += 0.3f)
            {
                var p0 = new Vector3(x, F1 + 0.37f, z);
                var p1 = new Vector3(x, F1 + 1.45f, z);
                bool free = !Physics.CheckCapsule(p0, p1, 0.3f, ~0, QueryTriggerInteraction.Ignore);
                bool inTrig = x >= minX && x <= maxX && z >= minZ && z <= maxZ;
                if (free && inTrig) standableInTrigger++;
                row.Append(free ? (inTrig ? "[●]" : " ● ") : (inTrig ? "[×]" : " × "));
            }
            sb.AppendLine(row.ToString());
        }
        sb.AppendLine("可站立且位于触发盒内的格子数 = " + standableInTrigger +
                      (standableInTrigger > 0 ? "  → 玩家进得去" : "  → 玩家进不去，触发永远不会发生"));

        var pos = shelf == null ? "" : " shelf=" + shelf.transform.position.ToString("F2");
        sb.AppendLine("CollectShelf" + pos);
        Debug.Log(sb.ToString());
        File.WriteAllText("D:/DouyinWorld2021/_delivery_diag.txt", sb.ToString());
    }

    /// <summary>
    /// 验收用：把 3 枚校徽摆进槽位、点亮 3 格，再点亮广场奖励，各截一张。
    /// 用来确认"收集完成后"的观感 —— 槽位有没有托住徽章、光圈大小、奖励光柱高度。
    /// 只改内存里的场景，不保存，跑完退出即恢复。
    /// </summary>
    [MenuItem("抖音虚拟创作SDK/校园：预览收集完成态")]
    public static void PreviewCollectState()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        DynamicGI.UpdateEnvironment();

        var shelf = GameObject.Find("CollectShelf");
        if (shelf == null) { Debug.LogError("[Campus] 场景里没有 CollectShelf"); return; }

        for (int i = 1; i <= 3; i++)
        {
            var item = GameObject.Find("Collect_" + i.ToString("00"));
            var slot = shelf.transform.Find("Slot_" + i.ToString("00"));
            if (item == null || slot == null) continue;
            item.transform.position = slot.position;
            item.transform.rotation = slot.rotation;
            var glow = slot.Find("Glow");
            if (glow != null) glow.gameObject.SetActive(true);
        }
        Capture("27_shelf_filled", new Vector3(-1.9f, 2.5f, 19.6f), new Vector3(-3.8f, 1.45f, 17.9f), 60f);
        // 玩家眼高 ≈ 地面 1.2 + 1.55；低于台面会看不出架上的东西
        Capture("28_shelf_filled_front", new Vector3(0.4f, 2.75f, 19.3f), new Vector3(-3.55f, 1.95f, 17.85f), 58f);

        var reward = GameObject.Find("Plaza_Reward");
        if (reward == null) { Debug.LogError("[Campus] 场景里没有 Plaza_Reward"); return; }
        foreach (Transform c in reward.transform.Cast<Transform>().ToArray())
            c.gameObject.SetActive(true);
        Capture("29_reward_lit", new Vector3(16f, 7f, -18f), new Vector3(0f, 2.5f, 2f), 55f);
        Debug.Log("[Campus] 收集完成态截图已生成");
    }

    /// <summary>
    /// 未收集提示光环的近景验收。站在玩家眼高斜看 + 退远看，各拍一张 ——
    /// 加法光效在明亮场景下会不会被天空光压掉、平视角度会不会因为掠射角而变暗，
    /// 这两张图是唯一能看出来途径（动画呼吸在批处理里看不出来，只能看静态亮度）。
    /// </summary>
    public static void PreviewGlowRing()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        DynamicGI.UpdateEnvironment();
        Capture("15b_glow_ring", new Vector3(6.3f, 1.6f, 4.6f), new Vector3(3.4f, 0.92f, 2.2f), 40f);
        Capture("15c_glow_far", new Vector3(12.0f, 2.2f, 8.0f), new Vector3(3.4f, 0.92f, 2.2f), 50f);
        // 低角度：光环半径 0.55m > 基座半径 0.30m，从齐胸高看外圈是否悬空
        Capture("15d_glow_low", new Vector3(4.6f, 0.75f, 3.4f), new Vector3(3.4f, 0.92f, 2.2f), 45f);
        Debug.Log("[Campus] 光环近景截图已生成");
    }

    [MenuItem("抖音虚拟创作SDK/校园：生成预览截图")]
    public static void CaptureAllFromMenu() => CaptureAll();

    /// <summary>
    /// 进门路径的碰撞诊断：从走廊沿轴线朝门外打射线，列出所有挡路的碰撞体。
    /// 用于确认"能不能从广场走进门厅、再走进走廊"，以及排查异常物体。
    /// </summary>
    public static void DiagnosePath()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        Physics.SyncTransforms();

        var sb = new System.Text.StringBuilder();
        var rays = new[]
        {
            ("进门", new Vector3(0f, 2.85f, 21.4f), new Vector3(0f, 2.1f, 14f)),
            ("进厅往北", new Vector3(0f, 2.85f, 18.0f), new Vector3(0f, 2.6f, 26f)),
            ("走廊向东", new Vector3(-16.5f, 2.85f, 21.6f), new Vector3(16.5f, 2.6f, 21.6f)),
            ("进教室", new Vector3(-13.2f, 2.85f, 22.8f), new Vector3(-13.2f, 2.6f, 29f)),
            ("入口正对面", new Vector3(0f, 2.3f, 10.5f), new Vector3(0f, 3.2f, 23f)),
            ("入口偏低", new Vector3(0f, 2.3f, 10.5f), new Vector3(0f, 2.6f, 23f)),
            ("穿过楼梯口", new Vector3(15.5f, 2.85f, 22.5f), new Vector3(15.5f, 2.85f, 24.5f)),
            ("一跑上方", new Vector3(14.6f, 2.85f, 24.2f), new Vector3(14.6f, 6.5f, 28.0f)),
            ("井口向下", new Vector3(15.6f, 7.5f, 28.0f), new Vector3(15.6f, 5.0f, 28.0f)),
            ("二层走廊", new Vector3(-16.5f, 7.15f, 21.6f), new Vector3(16.5f, 7.0f, 21.6f)),
            ("三层走廊", new Vector3(-16.5f, 11.4f, 21.6f), new Vector3(16.5f, 11.2f, 21.6f)),
            ("上三层梯段", new Vector3(14.65f, 7.2f, 24.4f), new Vector3(14.65f, 10.4f, 27.0f)),
            ("井口通到三层", new Vector3(16.2f, 7.2f, 27.6f), new Vector3(16.2f, 11.0f, 27.6f)),
            ("进阅览角", new Vector3(11.1f, 11.3f, 24.6f), new Vector3(11.1f, 10.6f, 29.6f)),
        };
        foreach (var (tag, p, t) in rays)
        {
            Vector3 dir = (t - p).normalized;
            float max = Vector3.Distance(p, t) + 2f;
            var hits = Physics.RaycastAll(p, dir, max);
            System.Array.Sort(hits, (a, b) => a.distance.CompareTo(b.distance));
            sb.AppendLine("=== " + tag + "  from " + p + " ===");
            foreach (var h in hits)
                sb.AppendLine(string.Format("  d={0:F2}  {1}  (layer {2})",
                    h.distance, h.collider.name, h.collider.gameObject.layer));
            if (hits.Length == 0) sb.AppendLine("  <无阻挡>");
        }
        // ---- 海报朝向：法线应朝可行走侧（前方 1.1m 内为空），背面 0.5m 内应有墙 ----
        // 海报没有 collider，所以射线不会命中自己；这里查的是"前面是不是被墙挡了"。
        sb.AppendLine();
        sb.AppendLine("=== poster facing ===");
        var posters = UnityEngine.Object.FindObjectsOfType<Transform>(true)
            .Where(t => t.name.StartsWith("Poster_")).OrderBy(t => t.name).ToArray();
        foreach (var tr in posters)
        {
            var fwd = tr.forward;
            RaycastHit hf;
            bool frontBlocked = Physics.Raycast(tr.position, fwd, out hf, 1.1f, ~0, QueryTriggerInteraction.Ignore);
            bool hasWall = Physics.Raycast(tr.position, -fwd, 0.5f, ~0, QueryTriggerInteraction.Ignore);
            sb.AppendLine(string.Format("  {0,-16} yaw={1,4}  front={2}  wall={3}",
                tr.name, Mathf.RoundToInt(tr.eulerAngles.y),
                frontBlocked ? ("BLOCKED by " + hf.collider.name + " d=" + hf.distance.ToString("F2")) : "clear",
                hasWall ? "yes" : "NO") + "   pos=" + tr.position);
        }

        System.IO.File.WriteAllText("D:/DouyinWorld2021/_diag.txt", sb.ToString(), System.Text.Encoding.UTF8);
        Debug.Log("[Campus] diag written");
    }

    public static void CaptureAll()
    {
        EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
        // 批处理离屏渲染不会自动重算天空盒环境光探针，室内背光面会被渲染成纯黑（场景本身没问题，
        // 编辑器里是正常的）。这里显式刷新一次，让截图代表实际观感。
        DynamicGI.UpdateEnvironment();
        Capture("01_plaza", new Vector3(20f, 8.5f, -24f), new Vector3(0f, 3f, 6f), 55f);
        Capture("02_building", new Vector3(0f, 5.5f, -8f), new Vector3(0f, 7f, 19f), 60f);
        Capture("03_field", new Vector3(-14f, 7f, -14f), new Vector3(-28f, 2f, -2f), 60f);
        Capture("04_gate", new Vector3(0f, 3.2f, -40f), new Vector3(0f, 4f, -22f), 55f);
        Capture("05_plaza_close", new Vector3(0f, 2.6f, -17f), new Vector3(0f, 1.2f, 3f), 52f);
        // 室内
        Capture("06_entrance", new Vector3(0f, 2.3f, 10.5f), new Vector3(0f, 3.1f, 18f), 55f);
        Capture("07_lobby", new Vector3(0f, 2.95f, 22.4f), new Vector3(0f, 3.4f, 10f), 62f);
        Capture("08_corridor", new Vector3(-16.8f, 2.9f, 21.6f), new Vector3(12f, 2.5f, 21.6f), 66f);
        Capture("09_classroom", new Vector3(-13.2f, 2.9f, 24.2f), new Vector3(-13.2f, 2.5f, 31.6f), 62f);
        Capture("10_corridor_window", new Vector3(-9.5f, 2.85f, 21.7f), new Vector3(-14.5f, 3.5f, 20.1f), 68f);
        Capture("11_classroom_east", new Vector3(-13.2f, 2.9f, 27.9f), new Vector3(-8.8f, 2.9f, 27.9f), 70f);
        // 楼梯与二层
        Capture("12_stairs", new Vector3(15.45f, 2.95f, 22.9f), new Vector3(15.0f, 4.6f, 27.6f), 72f);
        Capture("13_floor2_corridor", new Vector3(-16.7f, 7.15f, 20.7f), new Vector3(10f, 6.9f, 21.6f), 66f);
        Capture("14_stair_hall2", new Vector3(10.9f, 7.05f, 27.4f), new Vector3(15.6f, 5.6f, 28.6f), 70f);
        Capture("15_pickup", new Vector3(-9.2f, 1.95f, 22.5f), new Vector3(-9.2f, 1.3f, 21.2f), 46f);
        // 未收集提示光环的近景：站在玩家眼高（1.6m）斜看基座，验证明亮场景下加法光环到底显不显
        Capture("15b_glow_ring", new Vector3(6.3f, 1.6f, 4.6f), new Vector3(3.4f, 0.92f, 2.2f), 40f);
        Capture("15c_glow_far", new Vector3(12.0f, 2.2f, 8.0f), new Vector3(3.4f, 0.92f, 2.2f), 50f);
        // 低角度：光环半径 0.55m > 基座半径 0.30m，从齐胸高看外圈是否悬空
        Capture("15d_glow_low", new Vector3(4.6f, 0.75f, 3.4f), new Vector3(3.4f, 0.92f, 2.2f), 45f);
        Capture("16_classroom_small", new Vector3(11.1f, 2.9f, 24.3f), new Vector3(11.1f, 2.5f, 31.6f), 62f);
        // 三层与校徽收集
        Capture("17_shelf", new Vector3(-1.0f, 2.75f, 19.85f), new Vector3(-3.55f, 1.4f, 18.05f), 60f);
        Capture("18_floor3_corridor", new Vector3(-16.6f, 11.4f, 21.6f), new Vector3(9f, 11.2f, 21.6f), 66f);
        Capture("19_reading", new Vector3(9.2f, 11.3f, 26.4f), new Vector3(11.2f, 11.0f, 30.6f), 66f);
        Capture("20_stairs23", new Vector3(11.2f, 7.35f, 24.5f), new Vector3(15.6f, 8.7f, 28.4f), 72f);
        Capture("21_collect_point", new Vector3(-4.4f, 1.85f, -19.4f), new Vector3(-4.4f, 0.95f, -21.6f), 50f);
        // 细节层
        Capture("22_poster", new Vector3(0f, 2.75f, 20.5f), new Vector3(0f, 3.15f, 23.4f), 52f);
        Capture("23_greenery", new Vector3(11f, 3.4f, 6.5f), new Vector3(-1f, 1.2f, 17.5f), 58f);
        Capture("24_lobby_plants", new Vector3(0.9f, 2.8f, 16.8f), new Vector3(-4.6f, 1.45f, 18.5f), 60f);
        // 验收两张横图（contain 模式）：06 在二层走廊中段，14 在一层教室隔墙
        Capture("25_poster_wide", new Vector3(8.8f, 6.75f, 20.3f), new Vector3(8.8f, 6.55f, 23.4f), 56f);
        Capture("26_poster_wide2", new Vector3(-10.9f, 2.8f, 27.3f), new Vector3(-8.98f, 2.5f, 28.6f), 58f);
        // 操场南侧树列：专门看路灯和樱花冠有没有打架（站位自检只能扫到地面碰撞体）
        Capture("44_field_south", new Vector3(-38f, 2.6f, 4f), new Vector3(-38f, 2.0f, -16f), 62f);
        // 校门内侧（回望门洞）与操场西端：这两处新加的灯只有这两个角度看得见
        Capture("45_gate_inside", new Vector3(0f, 2.4f, -12.5f), new Vector3(0f, 2.2f, -22f), 58f);
        Capture("46_field_west", new Vector3(-44f, 3.2f, -2f), new Vector3(-60f, 2.2f, -2f), 62f);
        Debug.Log("[Campus] preview captured");
    }

    static void Capture(string name, Vector3 pos, Vector3 look, float fov)
    {
        const int W = 1600, H = 900;
        var go = new GameObject("PreviewCam");
        var cam = go.AddComponent<Camera>();
        cam.fieldOfView = fov;
        cam.nearClipPlane = 0.1f;
        cam.farClipPlane = 500f;
        cam.allowMSAA = true;
        go.transform.position = pos;
        go.transform.LookAt(look);

        var rt = new RenderTexture(W, H, 24, RenderTextureFormat.ARGB32);
        rt.Create();
        cam.targetTexture = rt;

        try
        {
            // URP 12.1.8 的签名是 (ScriptableRenderContext, Camera)
            UniversalRenderPipeline.RenderSingleCamera(new ScriptableRenderContext(), cam);
        }
        catch (Exception e)
        {
            Debug.LogWarning("[Campus] URP 单相机渲染失败，退回 Camera.Render: " + e.Message);
            cam.Render();
        }

        var prev = RenderTexture.active;
        RenderTexture.active = rt;
        var tex = new Texture2D(W, H, TextureFormat.RGB24, false);
        tex.ReadPixels(new Rect(0, 0, W, H), 0, 0);
        tex.Apply();
        RenderTexture.active = prev;

        File.WriteAllBytes("D:/DouyinWorld2021/_preview_" + name + ".png", tex.EncodeToPNG());

        UnityEngine.Object.DestroyImmediate(tex);
        UnityEngine.Object.DestroyImmediate(go);
        rt.Release();
        UnityEngine.Object.DestroyImmediate(rt);
    }

    // ---------------------------------------------------------------- SerializedProperty 辅助

    /// <summary>
    /// 按简单类名解析 SDK 类型。SDK 的分析器禁止字符串版 GetComponent，必须传 Type；
    /// 这里绕开编译期引用，避免 Editor 程序集对 com.douyin.world 的强依赖。
    /// </summary>
    static Type FindType(string simpleName)
    {
        var t = Type.GetType(simpleName + ", com.douyin.world");
        if (t != null) return t;
        foreach (var a in AppDomain.CurrentDomain.GetAssemblies())
        {
            var x = a.GetType(simpleName);
            if (x != null) return x;
        }
        throw new Exception("找不到 SDK 类型: " + simpleName);
    }

    static void SetProp(SerializedObject so, string name, UnityEngine.Object value)
    {
        var p = so.FindProperty(name);
        if (p != null) p.objectReferenceValue = value;
        else Debug.LogWarning("[Campus] 字段不存在: " + name);
    }

    static void SetObj(SerializedObject so, string name, UnityEngine.Object value) => SetProp(so, name, value);

    static void SetFloat(SerializedObject so, string name, float value)
    {
        var p = so.FindProperty(name);
        if (p != null) p.floatValue = value;
        else Debug.LogWarning("[Campus] 字段不存在: " + name);
    }

    static void SetBool(SerializedObject so, string name, bool value)
    {
        var p = so.FindProperty(name);
        if (p != null) p.boolValue = value;
    }

    /// <summary>
    /// 改 DouyinScript 绑定表（ParaLuaBindingData）里的一个布尔 ---@var。
    /// 这张表是 SerializeReference，FindPropertyRelative 取不到内部字段，
    /// 只能 managedReferenceValue 拿对象、反射改字段、再写回触发序列化。
    /// </summary>
    static bool SetLuaBool(GameObject go, string varName, bool value)
    {
        var script = go.GetComponent(FindType("DouyinScript"));
        if (script == null)
        {
            Debug.LogWarning("[Campus] " + go.name + " 缺少 DouyinScript");
            return false;
        }
        var so = new SerializedObject(script);
        var arr = so.FindProperty("ParaLuaBindingData");
        if (arr == null) return false;
        const BindingFlags F = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
        for (int i = 0; i < arr.arraySize; i++)
        {
            var el = arr.GetArrayElementAtIndex(i);
            var obj = el.managedReferenceValue;
            if (obj == null) continue;
            var t = obj.GetType();
            var fName = t.GetField("varName", F);
            if (fName == null || !(fName.GetValue(obj) is string n) || n != varName) continue;
            var fData = t.GetField("Data", F);
            if (fData == null || fData.FieldType != typeof(bool)) return false;
            fData.SetValue(obj, value);
            el.managedReferenceValue = obj;
            so.ApplyModifiedPropertiesWithoutUndo();
            EditorUtility.SetDirty(script);
            return true;
        }
        return false;
    }

    /// <summary>读回绑定表里的布尔值，用来验证改动真的落盘了</summary>
    static bool? GetLuaBool(GameObject go, string varName)
    {
        var script = go.GetComponent(FindType("DouyinScript"));
        if (script == null) return null;
        var so = new SerializedObject(script);
        var arr = so.FindProperty("ParaLuaBindingData");
        if (arr == null) return null;
        const BindingFlags F = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance;
        for (int i = 0; i < arr.arraySize; i++)
        {
            var obj = arr.GetArrayElementAtIndex(i).managedReferenceValue;
            if (obj == null) continue;
            var t = obj.GetType();
            var fName = t.GetField("varName", F);
            if (fName == null || !(fName.GetValue(obj) is string n) || n != varName) continue;
            var fData = t.GetField("Data", F);
            if (fData == null) return null;
            return fData.GetValue(obj) as bool?;
        }
        return null;
    }

    // ================================================================ 细节层（贴图 / 绿植 / 海报）
    //
    // 着色器约定（World_Lit.shader 313 / 317 行）：
    //   Albedo   = BaseTex.rgb * ColorCoverTex * _BaseColor
    //   Metallic = BaseTex.a   * _Metallic
    // 所以细节贴图一律做成"接近白的灰度"，颜色继续由 _BaseColor 控制，
    // 这样一张贴图能服务同一材质下所有用色，也不会额外占材质额度。

    // 源图目录。优先 "Posters~" —— Unity 会忽略以 ~ 结尾的目录，源图不会被打进 AssetBundle
    // （图集已经把内容包进去了，源图再打包一次纯属浪费，而 SDK 对贴图总量有 60MB 上限）。
    const string PosterDir = "Assets/Campus/Textures/Posters";
    const string PosterDirIgnored = "Assets/Campus/Textures/Posters~";
    static readonly string[] PosterDirs = { PosterDirIgnored, PosterDir };
    static readonly Color[] PosterTints =
    {
        new Color(0.16f, 0.42f, 0.62f), new Color(0.72f, 0.36f, 0.22f),
        new Color(0.22f, 0.50f, 0.36f), new Color(0.55f, 0.48f, 0.62f),
        new Color(0.62f, 0.20f, 0.24f), new Color(0.20f, 0.32f, 0.58f),
        new Color(0.58f, 0.44f, 0.18f), new Color(0.26f, 0.26f, 0.30f),
    };

    // 海报图集的实际布局，由 ScanPosters() 按 Posters/ 目录里的文件数决定：
    // 1~4 张 → 2×2；5~8 张 → 4×2。没图时按 2×2 全占位。
    // 之所以自适应，是因为 4 张真图配 4 张占位混着贴在墙上会很难看。
    static int _posterCols = 2, _posterRows = 2, _posterSlots = 4, _posterFound = 0;
    // 墙面实际循环使用几种图。有真图时 = 真图张数，这样不会出现"5 张真图 + 3 张占位"混着贴
    static int _posterVariants = 4;

    /// <summary>按序号找海报源图，两个候选目录都查（Posters~ 优先）</summary>
    static string FindPosterFile(int index)
    {
        foreach (var dir in PosterDirs)
        {
            if (!Directory.Exists(dir)) continue;
            foreach (var ext in new[] { "png", "jpg", "jpeg" })
            {
                // 必须补两位：直接用 "0" + index，index=10 会拼成 "010.png"，10 号之后的图全部找不到
                var p = dir + "/" + index.ToString("00") + "." + ext;
                if (File.Exists(p)) return p;
            }
        }
        return null;
    }

    static void ScanPosters()
    {
        int n = 0;
        for (int i = 1; i <= 16; i++)
            if (FindPosterFile(i) != null) n = i;
        _posterFound = n;
        if (n <= 4) { _posterCols = 2; _posterRows = 2; _posterSlots = 4; }
        else if (n <= 8) { _posterCols = 4; _posterRows = 2; _posterSlots = 8; }
        else { _posterCols = 4; _posterRows = 4; _posterSlots = 16; }
        _posterVariants = n > 0 ? n : 4;
        Debug.Log("[Campus] Posters scanned = " + n + "  layout = " + _posterCols + "x" + _posterRows);
    }

    // ---------------------------------------------------------------- 噪声

    static float[,] Lattice(int cells, int seed)
    {
        var r = new System.Random(seed);
        var a = new float[cells, cells];
        for (int y = 0; y < cells; y++)
            for (int x = 0; x < cells; x++)
                a[x, y] = (float)r.NextDouble();
        return a;
    }

    /// <summary>双线性 + 平滑插值的格点噪声，格子取模，因此 u/v 在 0..1 上回绕即无缝</summary>
    static float SampleTiled(float[,] a, int cells, float u, float v)
    {
        float fx = u * cells, fy = v * cells;
        int x0 = Mathf.FloorToInt(fx), y0 = Mathf.FloorToInt(fy);
        float tx = fx - x0, ty = fy - y0;
        tx = tx * tx * (3f - 2f * tx);
        ty = ty * ty * (3f - 2f * ty);
        int xa = ((x0 % cells) + cells) % cells, ya = ((y0 % cells) + cells) % cells;
        int xb = (xa + 1) % cells, yb = (ya + 1) % cells;
        return Mathf.Lerp(Mathf.Lerp(a[xa, ya], a[xb, ya], tx),
                          Mathf.Lerp(a[xa, yb], a[xb, yb], tx), ty);
    }

    static float Noise3(float[,] a, float[,] b, float[,] c, float u, float v)
        => SampleTiled(a, 8, u, v) * 0.55f + SampleTiled(b, 32, u, v) * 0.30f + SampleTiled(c, 96, u, v) * 0.15f;

    /// <summary>可平铺的随机点阵（细胞噪声用），每格一个点</summary>
    static Vector2[] CellPoints(int cells, int seed)
    {
        var r = new System.Random(seed);
        var pts = new Vector2[cells * cells];
        for (int i = 0; i < pts.Length; i++)
            pts[i] = new Vector2((float)r.NextDouble(), (float)r.NextDouble());
        return pts;
    }

    /// <summary>
    /// 到最近点的归一化距离（0 = 落在点上，约 0.7 = 离得最远）。点阵按格取模，u/v 回绕即无缝。
    /// 樱花的花团就是靠它画出来的 —— 值噪声只能做絮状，做不出一颗一颗的花簇。
    /// </summary>
    static float Worley(Vector2[] pts, int cells, float u, float v)
    {
        float fu = u * cells, fv = v * cells;
        int cu = Mathf.FloorToInt(fu), cv = Mathf.FloorToInt(fv);
        float best = 9f;
        for (int dy = -1; dy <= 1; dy++)
        {
            for (int dx = -1; dx <= 1; dx++)
            {
                int gx = cu + dx, gy = cv + dy;
                int wx = ((gx % cells) + cells) % cells;
                int wy = ((gy % cells) + cells) % cells;
                var p = pts[wy * cells + wx];
                float px = (gx + p.x) / cells - u;
                float py = (gy + p.y) / cells - v;
                float d = px * px + py * py;
                if (d < best) best = d;
            }
        }
        return Mathf.Sqrt(best) * cells;
    }

    static void Fill(Texture2D t, Func<float, float, Color> f)
    {
        int n = t.width;
        var px = new Color[n * n];
        for (int y = 0; y < n; y++)
            for (int x = 0; x < n; x++)
                px[y * n + x] = f((x + 0.5f) / n, (y + 0.5f) / n);
        t.SetPixels(px);
        t.Apply(true);
    }

    /// <summary>NPC 台词图集是 Python 画好的，这里只负责把它按贴图正确导入</summary>
    static void EnsureNpcLinesTexture()
    {
        const string path = TexDir + "/T_NpcLines.png";
        if (!File.Exists(path))
        {
            Debug.LogWarning("[Campus] 缺少 NPC 台词图集，先跑 python _tools/make_npc_lines.py");
            return;
        }
        AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
        var imp = (TextureImporter)AssetImporter.GetAtPath(path);
        imp.textureType = TextureImporterType.Default;
        imp.sRGBTexture = true;
        imp.mipmapEnabled = false;
        imp.wrapMode = TextureWrapMode.Clamp;
        imp.filterMode = FilterMode.Bilinear;
        imp.maxTextureSize = 2048;
        imp.textureCompression = TextureImporterCompression.Uncompressed;
        imp.SaveAndReimport();
    }

    static void SaveTex(Texture2D t, string path, bool repeat, int maxSize = 512)
    {
        File.WriteAllBytes(path, t.EncodeToPNG());
        UnityEngine.Object.DestroyImmediate(t);
        AssetDatabase.ImportAsset(path);
        var imp = (TextureImporter)AssetImporter.GetAtPath(path);
        imp.textureType = TextureImporterType.Default;
        imp.sRGBTexture = true;
        imp.mipmapEnabled = true;
        imp.wrapMode = repeat ? TextureWrapMode.Repeat : TextureWrapMode.Clamp;
        imp.filterMode = FilterMode.Bilinear;
        imp.anisoLevel = 4;
        imp.textureCompression = TextureImporterCompression.Uncompressed;
        imp.maxTextureSize = maxSize;
        imp.SaveAndReimport();
    }

    // ---------------------------------------------------------------- 贴图生成

    static void CreateDetailTextures()
    {
        if (!AssetDatabase.IsValidFolder(PosterDir))
            AssetDatabase.CreateFolder("Assets/Campus/Textures", "Posters");

        // 外墙面抹灰：大尺度色斑 + 竖向雨痕 + 细砂
        // 原来只有 ±7% 的均匀噪声，整面墙像一块刷了漆的塑料板 —— 建筑最缺的不是分辨率，
        // 是"这堵墙淋过雨、砌了几年"的证据。
        {
            var a = Lattice(8, 101); var b = Lattice(32, 102); var c = Lattice(96, 103);
            var t = new Texture2D(512, 512, TextureFormat.RGBA32, true);
            Fill(t, (u, v) =>
            {
                float n = Noise3(a, b, c, u, v);

                // 大尺度色斑（±4%）：不同批次涂料 / 日照差异，远看是墙面的"呼吸感"
                float big = SampleTiled(a, 8, u * 0.6f, v * 0.6f);

                // 竖向雨痕：u 方向细、v 方向极低频 → 从上往下的长条。
                // 频率很关键：u*0.45 时整面墙成了瓦楞纸，实际每 1~2m 一条才像雨痕
                float streakRaw = SampleTiled(b, 32, u * 0.12f, v * 0.05f);
                float streak = Step01(0.62f, 0.97f, streakRaw);

                float k = 0.91f + (n - 0.5f) * 0.11f + (big - 0.5f) * 0.08f - streak * 0.085f;
                k = Mathf.Clamp(k, 0.68f, 1f);
                // 雨痕处偏冷一点（水渍会积灰），比单纯压暗更像真的
                return new Color(k, k * 0.994f - streak * 0.012f, k * 0.980f - streak * 0.018f, 1f);
            });
            SaveTex(t, TexDir + "/T_WallPlaster.png", true);
        }

        // 混凝土：斑驳 + 细砂点
        {
            var a = Lattice(8, 201); var b = Lattice(32, 202); var c = Lattice(96, 203);
            var t = new Texture2D(512, 512, TextureFormat.RGBA32, true);
            Fill(t, (u, v) =>
            {
                // 8 格那层摊到地面上是 40cm 见方的大斑块，教室里光线本来就暗，
                // 暗部对 6% 的亮度差很敏感，看起来像污渍；压到 35%、让 32 格主导会干净很多
                float n = SampleTiled(a, 8, u, v) * 0.35f + SampleTiled(b, 32, u, v) * 0.65f;
                float grit = SampleTiled(c, 96, u, v);
                // 对比别给大：这张图也铺整间教室的地面（3 倍平铺），22% 的起伏在暖光下
                // 会变成一片片深色污渍。13% 足够读出水泥的斑驳。
                float k = 0.86f + (n - 0.5f) * 0.13f + (grit > 0.74f ? -0.04f : 0.015f);
                k = Mathf.Clamp(k, 0.72f, 1f);
                return new Color(k, k, k * 1.005f, 1f);
            });
            SaveTex(t, TexDir + "/T_Concrete.png", true);
        }

        // 铺装：4×4 石板 + 缝隙，每块深浅略有差异
        {
            var a = Lattice(8, 301); var b = Lattice(32, 302); var c = Lattice(96, 303);
            var rnd = new System.Random(304);
            const int cells = 4;
            var shade = new float[cells, cells];
            for (int y = 0; y < cells; y++)
                for (int x = 0; x < cells; x++)
                    shade[x, y] = 0.86f + (float)rnd.NextDouble() * 0.16f;
            var t = new Texture2D(512, 512, TextureFormat.RGBA32, true);
            Fill(t, (u, v) =>
            {
                float n = Noise3(a, b, c, u, v);
                float gu = u * cells, gv = v * cells;
                int cu = Mathf.Clamp(Mathf.FloorToInt(gu), 0, cells - 1);
                int cv = Mathf.Clamp(Mathf.FloorToInt(gv), 0, cells - 1);
                float fu = gu - Mathf.Floor(gu), fv = gv - Mathf.Floor(gv);
                bool joint = fu < 0.018f || fv < 0.018f;
                float k = joint ? 0.46f : shade[cu, cv] + (n - 0.5f) * 0.10f;
                return new Color(k, k * 0.99f, k * 0.975f, 1f);
            });
            SaveTex(t, TexDir + "/T_Paving.png", true);
        }

        // 草地：细密斑驳 + 零星草叶
        {
            var a = Lattice(8, 401); var b = Lattice(32, 402); var c = Lattice(96, 403);
            var t = new Texture2D(512, 512, TextureFormat.RGBA32, true);
            Fill(t, (u, v) =>
            {
                float n = Noise3(a, b, c, u, v);
                float blade = SampleTiled(c, 96, u * 1.7f, v * 0.45f);
                float k = 0.80f + (n - 0.5f) * 0.30f + (blade > 0.70f ? 0.08f : 0f);
                k = Mathf.Clamp(k, 0.60f, 1f);
                return new Color(k * 0.98f, k, k * 0.92f, 1f);
            });
            SaveTex(t, TexDir + "/T_Grass.png", true);
        }

        // 木纹：沿 U 向的顺纹 + 细线
        {
            var a = Lattice(8, 501); var b = Lattice(32, 502); var c = Lattice(96, 503);
            var t = new Texture2D(512, 512, TextureFormat.RGBA32, true);
            Fill(t, (u, v) =>
            {
                float warp = SampleTiled(a, 8, u, v * 1f) * 0.16f;
                float n = SampleTiled(b, 32, u * 0.55f, v + warp);
                // 两道木纹叠加：粗的走向 + 细的纤维。只有一道时看着像"条纹布"，两道才有木料感
                float grainA = Mathf.Abs(Mathf.Sin((v * 14f + n * 2.6f) * Mathf.PI));
                float grainB = Mathf.Abs(Mathf.Sin((v * 37f + n * 5.0f) * Mathf.PI));
                float fiber = grainA * 0.62f + grainB * 0.38f;
                // 稀疏节疤：只出现在极少数高峰值处，多了整块木头就显脏
                float knot = Step01(0.88f, 0.97f, SampleTiled(b, 32, u * 0.8f, v * 0.8f));
                float k = 0.86f + n * 0.09f + (1f - fiber) * 0.11f - knot * 0.10f;
                k = Mathf.Clamp(k, 0.62f, 1f);
                return new Color(k, k * 0.97f, k * 0.93f, 1f);
            });
            SaveTex(t, TexDir + "/T_Wood.png", true);
        }

        // 室内饰面：比外墙更干净的浅灰
        {
            var a = Lattice(8, 601); var b = Lattice(32, 602); var c = Lattice(96, 603);
            var t = new Texture2D(512, 512, TextureFormat.RGBA32, true);
            Fill(t, (u, v) =>
            {
                float n = Noise3(a, b, c, u, v);
                float k = Mathf.Clamp(0.94f + (n - 0.5f) * 0.08f, 0.88f, 1f);
                return new Color(k, k, k * 0.99f, 1f);
            });
            SaveTex(t, TexDir + "/T_Interior.png", true);
        }

        // 樱花树冠：一颗颗花团，深粉 → 浅粉 → 近白。
        // 之前树冠只有 M_Sakura 的纯色 + 椭球形状，看着就是一团光滑的粉色棉花糖。
        // 花团用细胞噪声画：值噪声只能做絮状，做不出一颗一颗的花簇。
        {
            var p1 = CellPoints(14, 901);
            var p2 = CellPoints(30, 902);
            var nz = Lattice(24, 903);
            var t = new Texture2D(512, 512, TextureFormat.RGBA32, true);
            Fill(t, (u, v) =>
            {
                float bloom = 1f - Step01(0f, 0.95f, Worley(p1, 14, u, v));   // 大花团
                float petal = 1f - Step01(0f, 0.80f, Worley(p2, 30, u, v));   // 小花簇
                float fine = SampleTiled(nz, 24, u, v) - 0.5f;

                // 基准压到 0.20 而不是 0.34：多数像素落在花团之间的暗部，
                // 给高了整棵树会白成一片棉花球（夕阳主光还有 4.0 的强度，会再提亮一次）
                float k = Mathf.Clamp01(0.20f + bloom * 0.42f + petal * 0.20f + fine * 0.10f);
                var deep = new Color(0.52f, 0.20f, 0.32f);
                var mid = new Color(0.82f, 0.44f, 0.54f);
                var light = new Color(0.98f, 0.72f, 0.80f);
                // 分界放到 0.60：让大部分像素停在 mid 一侧，只有花团正中才提亮到近白，
                // 否则整棵树会被夕阳主光（强度 4.0）再推一档，白成棉花球
                var c = k < 0.60f ? Color.Lerp(deep, mid, k / 0.6f) : Color.Lerp(mid, light, (k - 0.6f) / 0.4f);
                return new Color(c.r, c.g, c.b, 1f);
            });
            SaveTex(t, TexDir + "/T_Sakura.png", true);
        }

        CreatePosterAtlas();
    }

    // ---------------------------------------------------------------- 法线 / 粗糙度 / AO 打包图
    //
    // World_Lit 的取样约定（shader 第 299~325 行）：
    //   float2 n = float2(tex.r, tex.g) * 2 - 1;   法线 Z 恒取 1 再归一化
    //   Smoothness = tex.b * _Smoothness;  Occlusion = tex.a
    // 所以一张图同时管三件事：RG=切线法线XY、B=光滑度、A=遮蔽。
    //
    // ⚠️ 导入设置和"常规法线图"不一样，别照搬 Texture Type = Normal map / BC5：
    //   · Normal map 类型会让 Unity 重排通道（桌面 DXT5nm 把 X 搬进 A、B 位写常量），
    //     这张图的 B/A 装的是光滑度和 AO，一重排就全废 → 必须保持 Type = Default。
    //   · BC5 只存两通道，同样会吃掉 B/A → 用 BC7（CompressedHQ），四通道都在。
    //   · 真正必须保证的是 sRGB = false（线性数据），否则法线强度会被 gamma 掰歪。

    static float Wrap01(float x) => x - Mathf.Floor(x);

    static void PackedNormal(string file, Func<float, float, float> h,
                             Func<float, float, float> smooth, Func<float, float, float> ao)
    {
        const int N = 512;
        // 高度场 → 法线的统一缩放。噪声按格点采样，相邻像素落差天然很大，
        // 这个值给大了整张图 R/G 会铺满 0..1（法线几乎水平），远处就是一片噪点闪烁。
        // 实测 std(R) 落在 0.03~0.06 之间观感最稳，最终强度再靠材质 _NormalScale 微调。
        const float slope = 0.055f;
        const float e = 1f / N;
        var t = new Texture2D(N, N, TextureFormat.RGBA32, true);
        Fill(t, (u, v) =>
        {
            // 中心差分求梯度；u/v 越界回绕，保证贴图四边无缝（和 albedo 一样要能平铺）
            float hl = h(Wrap01(u - e), v), hr = h(Wrap01(u + e), v);
            float hd = h(u, Wrap01(v - e)), hu = h(u, Wrap01(v + e));
            float dx = (hr - hl) / (2f * e) * slope;
            float dy = (hu - hd) / (2f * e) * slope;
            var n = new Vector3(-dx, -dy, 1f).normalized;
            return new Color(n.x * 0.5f + 0.5f, n.y * 0.5f + 0.5f,
                             Mathf.Clamp01(smooth(u, v)), Mathf.Clamp01(ao(u, v)));
        });
        SaveNormalTex(t, TexDir + "/" + file + ".png");
    }

    /// <summary>
    /// 法线类贴图的导入：Default + 线性 + mipmap + BC7。
    /// 和 SaveTex 的区别只有 sRGB 与压缩方式 —— 但这两项错了，法线方向会直接歪掉。
    /// </summary>
    static void SaveNormalTex(Texture2D t, string path)
    {
        File.WriteAllBytes(path, t.EncodeToPNG());
        UnityEngine.Object.DestroyImmediate(t);
        AssetDatabase.ImportAsset(path);
        var imp = (TextureImporter)AssetImporter.GetAtPath(path);
        imp.textureType = TextureImporterType.Default;   // 不是 NormalMap，见上方注释
        imp.sRGBTexture = false;                         // 线性
        imp.mipmapEnabled = true;
        imp.wrapMode = TextureWrapMode.Repeat;
        imp.filterMode = FilterMode.Bilinear;
        imp.anisoLevel = 4;
        imp.textureCompression = TextureImporterCompression.CompressedHQ;  // 桌面 → BC7
        imp.maxTextureSize = 512;
        imp.SaveAndReimport();
    }

    /// <summary>
    /// 法线高度场专用的低频噪声。
    /// 注意：贴图在物体上要平铺 3~7 倍，固有频率会被一起放大 ——
    /// Noise3 里那层 96 格成分乘上 tile 就是每像素一个周期，算出来的法线是纯噪点，
    /// 近看像砂纸、远看靠 mipmap 糊成一片灰。所以高度场只取 8 / 24 两档。
    /// </summary>
    static float SoftNoise(float[,] a, float[,] b, float u, float v)
        => SampleTiled(a, 8, u, v) * 0.65f + SampleTiled(b, 24, u, v) * 0.35f;

    /// <summary>
    /// 软阶跃：x 从 a 过渡到 b 时输出 0→1。
    /// ⚠️ 别用 Mathf.SmoothStep(a, b, x) 代替 —— 那个是"插值到 b"，
    /// b=0.085 时输出上限只有 0.085，缝深会缩水十几倍，法线几乎看不出来（踩过）。
    /// </summary>
    static float Step01(float a, float b, float x)
    {
        float t = Mathf.Clamp01((x - a) / (b - a));
        return t * t * (3f - 2f * t);
    }

    static void CreatePackedNormalTextures()
    {
        // 混凝土 / 道路：细碎起伏 + 稀疏砂粒。
        // 8 格那层（大尺度）给得越重，铺到教室地面上越像一片片污渍 —— 黄昏是掠射光，
        // 法线偏个二十度就能把明暗拉开一倍。所以重心放到 24 格。
        {
            var a = Lattice(8, 801); var b = Lattice(24, 802);
            Func<float, float, float> fine = (u, v) =>
                SampleTiled(a, 8, u, v) * 0.35f + SampleTiled(b, 24, u, v) * 0.65f;
            PackedNormal("T_N_Concrete",
                (u, v) => fine(u, v) * 0.30f
                          + Step01(0.54f, 0.92f, SampleTiled(b, 24, u * 2.3f, v * 2.3f)) * 0.10f,
                (u, v) => 0.36f + (fine(u, v) - 0.5f) * 0.14f,
                (u, v) => 0.95f + (fine(u, v) - 0.5f) * 0.12f);
        }

        // 外墙抹灰：很缓的起伏 + 竖向雨痕的轻微凹槽
        {
            var a = Lattice(8, 811); var b = Lattice(24, 812);
            PackedNormal("T_N_Wall",
                (u, v) =>
                {
                    // 抹刀痕：8 格主导的大片缓波浪，像抹子一遍遍走过留下的起伏。
                    // 原来只有 0.28 幅度，法线 p90 才 7.5° —— 侧面看几乎是块平板。
                    float trowel = SampleTiled(a, 8, u, v) * 0.60f + SampleTiled(b, 24, u, v) * 0.40f;
                    // 雨痕位置轻微内凹（水把灰浆冲薄一层），和 albedo 上的竖条对得上
                    float streak = Step01(0.62f, 0.97f, SampleTiled(b, 24, u * 0.12f, v * 0.05f));
                    return trowel * 0.42f - streak * 0.03f;
                },
                (u, v) => 0.26f + (SoftNoise(a, b, u, v) - 0.5f) * 0.10f,
                (u, v) => 0.96f + (SoftNoise(a, b, u, v) - 0.5f) * 0.08f);
        }

        // 室内饰面：几乎平整，只留极缓的涂装起伏
        {
            var a = Lattice(8, 821); var b = Lattice(24, 822);
            PackedNormal("T_N_Interior",
                (u, v) => SoftNoise(a, b, u, v) * 0.08f,
                (u, v) => 0.30f + (SoftNoise(a, b, u, v) - 0.5f) * 0.08f,
                (u, v) => 0.98f);
        }

        // 广场铺装：4×4 石板，缝口倒角 + 缝里压暗，这块最能看出法线的作用
        {
            var a = Lattice(8, 831); var b = Lattice(24, 832);
            const int cells = 4;
            Func<float, float, float> edge = (u, v) =>
            {
                float gu = u * cells, gv = v * cells;
                float fu = gu - Mathf.Floor(gu), fv = gv - Mathf.Floor(gv);
                return Mathf.Min(Mathf.Min(fu, 1f - fu), Mathf.Min(fv, 1f - fv));   // 0=缝中心 0.5=石面中心
            };
            PackedNormal("T_N_Paving",
                (u, v) => Step01(0f, 0.040f, edge(u, v)) * 0.145f
                          + (SoftNoise(a, b, u, v) - 0.5f) * 0.09f,
                (u, v) => edge(u, v) < 0.045f ? 0.12f : 0.55f,
                (u, v) => edge(u, v) < 0.048f ? 0.52f : 0.97f);
        }

        // 木：沿 U 的顺纹。
        // ⚠️ 板缝只能做很浅的一点：M_Wood 是全场景用得最多的材质（桌椅/门框/书架/踢脚），
        //    椅子这类小件用的是 Cube 原始 UV，一道深板缝会在椅背上横成"搓板"。
        {
            var a = Lattice(8, 841); var b = Lattice(24, 842);
            Func<float, float, float> plank = (u, v) =>
            {
                float pv = v * 2f;
                float fp = pv - Mathf.Floor(pv);
                return Step01(0f, 0.045f, Mathf.Min(fp, 1f - fp));
            };
            PackedNormal("T_N_Wood",
                (u, v) =>
                {
                    float warp = SampleTiled(a, 8, u, v) * 0.22f;
                    float grain = Mathf.Abs(Mathf.Sin((v * 7f + warp * 2.4f) * Mathf.PI));
                    return (1f - grain) * 0.10f + plank(u, v) * 0.10f
                           + (SampleTiled(b, 24, u, v) - 0.5f) * 0.07f;
                },
                (u, v) => 0.44f + (SampleTiled(b, 24, u, v) - 0.5f) * 0.16f,
                (u, v) => 0.90f + plank(u, v) * 0.07f);
        }

        // 砖：错缝排列，砖面微凸、灰缝凹下去
        {
            var a = Lattice(8, 851); var b = Lattice(24, 852);
            const float rows = 8f, cols = 4f;
            Func<float, float, float> face = (u, v) =>
            {
                float gv = v * rows;
                int row = Mathf.FloorToInt(gv);
                float fv = gv - row;
                float gu = u * cols + (row % 2) * 0.5f;
                float fu = gu - Mathf.Floor(gu);
                return Mathf.Min(Mathf.Min(fu, 1f - fu), Mathf.Min(fv, 1f - fv));
            };
            PackedNormal("T_N_Brick",
                (u, v) => Step01(0f, 0.055f, face(u, v)) * 0.135f
                          + (SampleTiled(b, 24, u, v) - 0.5f) * 0.10f,
                (u, v) => face(u, v) < 0.045f ? 0.14f : 0.34f,
                (u, v) => face(u, v) < 0.050f ? 0.58f : 0.96f);
        }

        // 草地：细密草叶，法线要碎但不能太陡，否则远处会闪
        {
            var a = Lattice(16, 861); var b = Lattice(32, 862);
            PackedNormal("T_N_Grass",
                (u, v) =>
                {
                    float blade = SampleTiled(b, 32, u * 1.7f, v * 0.45f);
                    float n = SampleTiled(a, 16, u, v);
                    return blade * 0.12f + n * 0.09f;
                },
                (u, v) => 0.10f + (SampleTiled(a, 16, u, v) - 0.5f) * 0.06f,
                (u, v) => 0.88f + (SampleTiled(a, 16, u, v) - 0.5f) * 0.16f);
        }

        // 樱花树冠：每团花有体积。树冠是"低面球堆 + 花团贴图"，法线负责把团块之间的缝压出来
        {
            var p1 = CellPoints(14, 911);
            var p2 = CellPoints(30, 912);
            var nz = Lattice(24, 913);
            PackedNormal("T_N_Sakura",
                (u, v) =>
                {
                    float bloom = 1f - Step01(0f, 0.95f, Worley(p1, 14, u, v));
                    float petal = 1f - Step01(0f, 0.78f, Worley(p2, 30, u, v));
                    return bloom * 0.55f + petal * 0.20f
                           + (SampleTiled(nz, 24, u, v) - 0.5f) * 0.10f;
                },
                (u, v) => 0.10f + (SampleTiled(nz, 24, u, v) - 0.5f) * 0.06f,
                (u, v) => 0.92f + (SampleTiled(nz, 24, u, v) - 0.5f) * 0.10f);
        }
    }

    /// <summary>
    /// 海报图集：2×2 = 4 张。若 Posters/ 目录下有 01.png…04.png（或 jpg），
    /// 就直接用真实图片合成；没有才用程序化占位图。换图只需换文件再跑一次搭建。
    /// </summary>
    static void CreatePosterAtlas()
    {
        AssetDatabase.Refresh();
        // 格子取 3:4（384×512），与海报面片的 0.95×1.3 / 1.2×1.6 比例一致。
        // 原来用正方形格子，铺到竖版面片上会被纵向拉长 33%，人像和字都会变形。
        ScanPosters();
        const int cw = 384, ch = 512;
        int cols = _posterCols, rows = _posterRows, slots = _posterSlots;
        var atlas = new Texture2D(cw * cols, ch * rows, TextureFormat.RGBA32, true);
        var px = new Color[atlas.width * atlas.height];
        var rnd = new System.Random(701);
        string usedLog = "";

        for (int i = 0; i < slots; i++)
        {
            int ox = (i % cols) * cw, oy = (i / cols) * ch;
            var src = LoadPosterImage(i);

            if (src != null)
            {
                float targetAR = (float)cw / ch;
                float srcAR = (float)src.width / src.height;
                // 横图（或极窄竖图）用 cover 会裁掉太多主体：一张 16:10 的图只留中间 47%，
                // 构图直接毁掉。这类图改成 contain —— 完整显示，四周用该图自己的平均色填边，
                // 观感像"带出血的海报"，比裁掉半个画面好得多。
                bool tooWide = srcAR > 1.0f || srcAR < 0.48f;

                if (!tooWide)
                {
                    float u0 = 0f, v0 = 0f, du = 1f, dv = 1f;
                    if (srcAR > targetAR) { du = targetAR / srcAR; u0 = (1f - du) * 0.5f; }
                    else { dv = srcAR / targetAR; v0 = (1f - dv) * 0.5f; }

                    for (int y = 0; y < ch; y++)
                    {
                        float fy = (y + 0.5f) / ch;
                        for (int x = 0; x < cw; x++)
                        {
                            float fx = (x + 0.5f) / cw;
                            var c = src.GetPixelBilinear(u0 + fx * du, v0 + fy * dv);
                            if (c.a < 0.999f) c = Color.Lerp(new Color(0.12f, 0.12f, 0.13f), c, c.a);
                            px[(oy + y) * atlas.width + ox + x] = c;
                        }
                    }
                    usedLog += "0" + (i + 1) + "=cover  ";
                }
                else
                {
                    var avg = AverageColor(src);
                    float k = Mathf.Min((float)cw / src.width, (float)ch / src.height);
                    int dw = Mathf.RoundToInt(src.width * k), dh = Mathf.RoundToInt(src.height * k);
                    int dx = (cw - dw) / 2, dy = (ch - dh) / 2;

                    // 留白直接用它自己的平均色，压暗 10% 当"边框"。
                    // 试过三种延展方式，只有这个不会出错：
                    //  - 整图 cover 延展 → 标题文字又在留白里露一遍（重影）
                    //  - 最外一行像素纵向拉长 → 树影/天空区拉出硬竖条纹
                    //  - 最外 12 行平均后按列延展 → 竖条纹只是变淡，横向色差大的图依然明显
                    // 平均色虽然"平"，但海报在场景里只有 1m 宽，远看就是干净的留白边。
                    var padColor = avg * 0.9f;
                    padColor.a = 1f;

                    for (int y = 0; y < ch; y++)
                    {
                        for (int x = 0; x < cw; x++)
                        {
                            int sx = x - dx, sy = y - dy;
                            Color c;
                            if (sx >= 0 && sx < dw && sy >= 0 && sy < dh)
                            {
                                c = src.GetPixelBilinear((sx + 0.5f) / dw, (sy + 0.5f) / dh);
                                if (c.a < 0.999f) c = Color.Lerp(avg, c, c.a);
                            }
                            else c = padColor;
                            px[(oy + y) * atlas.width + ox + x] = c;
                        }
                    }
                    usedLog += "0" + (i + 1) + "=contain(" + src.width + "x" + src.height + ")  ";
                }
                UnityEngine.Object.DestroyImmediate(src);
            }
            else
            {
                DrawPlaceholderPoster(px, atlas.width, ox, oy, cw, ch,
                    PosterTints[i % PosterTints.Length], rnd, i);
                usedLog += "0" + (i + 1) + "=占位  ";
            }
        }

        atlas.SetPixels(px);
        atlas.Apply(true);
        // maxSize 要 >= 图集长边，否则 Unity 导入时会把 1536 降成 768
        int maxSide = Mathf.NextPowerOfTwo(Mathf.Max(cw * cols, ch * rows));
        int aw = cw * cols, ah = ch * rows;
        SaveTex(atlas, TexDir + "/T_PosterAtlas.png", false, maxSide);
        Debug.Log("[Campus] atlas = " + aw + "x" + ah + "  " + usedLog);
    }

    /// <summary>取一张图的平均色，给 contain 模式的留白用（抽样 32×32 就够）</summary>
    static Color AverageColor(Texture2D t)
    {
        var sum = new Color(0f, 0f, 0f, 0f);
        int n = 0;
        int sx = Mathf.Max(1, t.width / 32), sy = Mathf.Max(1, t.height / 32);
        for (int y = 0; y < t.height; y += sy)
        {
            for (int x = 0; x < t.width; x += sx)
            {
                sum += t.GetPixel(x, y);
                n++;
            }
        }
        if (n == 0) return new Color(0.10f, 0.10f, 0.11f);
        var c = sum / n;
        c.a = 1f;
        return c;
    }

    static Texture2D LoadPosterImage(int index)
    {
        var path = FindPosterFile(index + 1);
        if (path == null) return null;
        var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
        var bytes = File.ReadAllBytes(path);
        if (tex.LoadImage(bytes)) return tex;
        Debug.LogWarning("[Campus] poster decode FAILED: " + path + " (" + bytes.Length + " bytes)");
        UnityEngine.Object.DestroyImmediate(tex);
        return null;
    }

    /// <summary>程序化占位海报：底色 + 标题条 + 图形块，确保"能看出是海报"</summary>
    static void DrawPlaceholderPoster(Color[] px, int w, int ox, int oy, int cw, int chh, Color tint, System.Random rnd, int variant)
    {
        for (int y = 0; y < chh; y++)
        {
            for (int x = 0; x < cw; x++)
            {
                float u = (float)x / cw, v = (float)y / chh;
                // 边框
                bool border = u < 0.035f || u > 0.965f || v < 0.035f || v > 0.965f;
                Color c;
                if (border) c = new Color(0.93f, 0.91f, 0.86f);
                else
                {
                    c = Color.Lerp(tint, Color.white, 0.30f);           // 纸底：保留颜色，别冲成白纸
                    // 顶部标题条
                    if (v > 0.80f && v < 0.90f && u > 0.12f && u < 0.78f) c = tint;
                    // 中部图形
                    if (v > 0.36f && v < 0.70f && u > 0.14f && u < 0.86f)
                    {
                        float k = Mathf.Sin((u * 6f + variant * 1.7f) * Mathf.PI) * 0.5f + 0.5f;
                        if (v < 0.40f || k > 0.35f) c = Color.Lerp(tint, Color.black, 0.12f);
                    }
                    // 底部几行"文字"
                    for (int line = 0; line < 3; line++)
                    {
                        float ly = 0.26f - line * 0.07f;
                        if (Mathf.Abs(v - ly) < 0.018f && u > 0.14f && u < 0.62f + line * 0.06f)
                            c = Color.Lerp(tint, Color.black, 0.25f);
                    }
                }
                // 轻微纸张纹理
                float grain = 0.97f + (float)rnd.NextDouble() * 0.05f;
                px[(oy + y) * w + ox + x] = new Color(c.r * grain, c.g * grain, c.b * grain, 1f);
            }
        }
    }

    // ---------------------------------------------------------------- 平面 / 海报网格

    static Mesh BuildPlaneUV(float w, float d, float tile)
    {
        var m = new Mesh();
        float hx = w * 0.5f, hz = d * 0.5f;
        m.vertices = new[]
        {
            new Vector3(-hx, 0, -hz), new Vector3(hx, 0, -hz),
            new Vector3(-hx, 0, hz), new Vector3(hx, 0, hz),
        };
        m.uv = new[]
        {
            new Vector2(0, 0), new Vector2(w / tile, 0),
            new Vector2(0, d / tile), new Vector2(w / tile, d / tile),
        };
        m.normals = new[] { Vector3.up, Vector3.up, Vector3.up, Vector3.up };
        m.triangles = new[] { 0, 2, 1, 1, 2, 3 };
        m.RecalculateBounds();
        return m;
    }

    /// <summary>竖直四边形，法线朝 +Z，UV 取图集里的某一格</summary>
    /// <summary>
    /// 校名牌：复用海报的 quad 生成（正面朝 -Z，靠 yaw 转向），UV 取整张 T_SchoolSign，
    /// 材质 M_SignText 自带弱自发光，朝北的牌匾在黄昏才不会变成一块黑板。
    /// </summary>
    static void AddSignQuad(string name, Transform parent, Vector3 pos, float w, float h, float yaw)
    {
        var r = new Rect(0.004f, 0.004f, 0.992f, 0.992f);
        var mesh = GetMesh("SignQuad_" + w.ToString("F2") + "_" + h.ToString("F2"),
            () => BuildPosterQuad(w, h, r));

        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        go.transform.localPosition = pos;
        go.transform.localRotation = Quaternion.Euler(0, yaw, 0);
        go.AddComponent<MeshFilter>().sharedMesh = mesh;
        var mr = go.AddComponent<MeshRenderer>();
        mr.sharedMaterial = _mats["M_SignText"];
        mr.shadowCastingMode = ShadowCastingMode.Off;
        mr.receiveShadows = false;
        go.layer = LayerCameraNoCollision;
    }

    static Mesh BuildPosterQuad(float w, float h, Rect r)
    {
        var m = new Mesh();
        m.vertices = new[]
        {
            new Vector3(-w * 0.5f, 0, 0), new Vector3(w * 0.5f, 0, 0),
            new Vector3(-w * 0.5f, h, 0), new Vector3(w * 0.5f, h, 0),
        };
        // U 方向必须与顶点左右相反。这个 quad 的三角面绕序使它的正面朝 -Z，
        // 而相机朝 +Z 时屏幕右 = 世界 +X，局部 +X 恰好对应屏幕左 ——
        // 直接用 xMin→左、xMax→右 会得到左右镜像的图（占位图是抽象色块所以一直没暴露，
        // 换成带文字的照片会整片反字）。
        m.uv = new[]
        {
            new Vector2(r.xMax, r.yMin), new Vector2(r.xMin, r.yMin),
            new Vector2(r.xMax, r.yMax), new Vector2(r.xMin, r.yMax),
        };
        m.normals = new[] { Vector3.forward, Vector3.forward, Vector3.forward, Vector3.forward };
        m.triangles = new[] { 0, 1, 3, 0, 3, 2 };
        m.RecalculateBounds();
        return m;
    }

    static void AddPoster(string name, Transform parent, Vector3 bottomCenter, float w, float h, int variant, float yaw)
    {
        int i = variant % _posterVariants;
        const float pad = 0.002f;
        float uw = 1f / _posterCols, vh = 1f / _posterRows;
        var r = new Rect((i % _posterCols) * uw + pad, (i / _posterCols) * vh + pad,
                         uw - pad * 2f, vh - pad * 2f);
        // key 必须包含图集布局：只写 "Poster_" + i 的话，图集从 2x2 变成 4x4 时会复用旧网格，
        // 于是一块海报上同时显示 4 张图（UV 区域是旧的 0.5x0.5）。这个坑踩了两次。
        var mesh = GetMesh("PosterV3_" + _posterCols + "x" + _posterRows + "_" + i + "_" + w + "_" + h,
            () => BuildPosterQuad(w, h, r));

        var go = new GameObject(name);
        go.transform.SetParent(parent, false);
        go.transform.localPosition = bottomCenter;
        go.transform.localRotation = Quaternion.Euler(0, yaw, 0);
        go.AddComponent<MeshFilter>().sharedMesh = mesh;
        var mr = go.AddComponent<MeshRenderer>();
        mr.sharedMaterial = _mats["M_Poster"];
        mr.shadowCastingMode = ShadowCastingMode.Off;
        mr.receiveShadows = false;
        go.layer = LayerCameraNoCollision;
    }

    // ---------------------------------------------------------------- 绿植

    /// <summary>
    /// 灌木：低面球团簇，合并成单个网格。
    /// 原来是 3 个 Unity 内置球（各 515 面）叠在一起 —— 一丛就 1545 面，48 丛吃掉 7 万面，
    /// 而且每个球是一个独立 Renderer。合并后 400 面、1 个 Renderer，轮廓还更碎。
    /// </summary>
    static Mesh BuildBushMesh(int seed)
    {
        var ico = GetMesh("Ico_1", () => BuildIcoSphere(1));
        var rnd = new System.Random(seed);
        var parts = new List<CombineInstance>(5);

        // 主球：扁一点的鼓包（icosphere 顶点是单位球，scale 直接就是半径）
        parts.Add(new CombineInstance
        {
            mesh = ico,
            transform = Matrix4x4.TRS(new Vector3(0, 0.42f, 0),
                Quaternion.Euler(0, (float)rnd.NextDouble() * 360f, 0),
                new Vector3(0.65f, 0.44f, 0.65f)),
        });

        // 四周再挂四个小团，让轮廓不是完美的椭球
        for (int i = 0; i < 4; i++)
        {
            float a = Mathf.PI * 2f * i / 4f + (float)rnd.NextDouble() * 0.7f;
            float d = 0.30f + (float)rnd.NextDouble() * 0.14f;
            float r = 0.30f + (float)rnd.NextDouble() * 0.12f;
            var c = new Vector3(Mathf.Cos(a) * d, 0.30f + (float)rnd.NextDouble() * 0.14f, Mathf.Sin(a) * d);
            parts.Add(new CombineInstance
            {
                mesh = ico,
                transform = Matrix4x4.TRS(c, Quaternion.Euler((float)rnd.NextDouble() * 360f,
                    (float)rnd.NextDouble() * 360f, 0), new Vector3(r, r * 0.82f, r)),
            });
        }

        var mesh = new Mesh();
        mesh.CombineMeshes(parts.ToArray(), true, true);
        mesh.RecalculateBounds();
        return mesh;
    }

    /// <summary>低面球（80 面）。用在"只要一个鼓包"的地方（绿篱顶、树冠零件），比内置球省 6 倍面</summary>
    static GameObject LowSphere(string name, Transform parent, Vector3 pos, float radius, string mat)
    {
        var ico = GetMesh("Ico_1", () => BuildIcoSphere(1));
        var go = PlaceMesh(name, parent, ico, pos, mat);
        UnityEngine.Object.DestroyImmediate(go.GetComponent<MeshCollider>());
        go.transform.localScale = Vector3.one * radius * 2f;
        return go;
    }

    static void Bush(string name, Transform parent, Vector3 pos, float scale)
    {
        var root = new GameObject(name).transform;
        root.SetParent(parent, false);
        root.localPosition = pos;
        root.localScale = Vector3.one * scale;
        root.gameObject.layer = LayerCameraNoCollision;

        int v = Mathf.Abs(name.GetHashCode()) % 4;
        var mesh = GetMesh("Bush_" + v, () => BuildBushMesh(8100 + v * 13));
        var go = PlaceMesh("BushBody", root, mesh, Vector3.zero, "M_Lawn");
        UnityEngine.Object.DestroyImmediate(go.GetComponent<MeshCollider>());
        go.layer = LayerCameraNoCollision;
    }

    /// <summary>绿篱：一段矮箱体 + 顶部压扁球，看起来不像水泥墩</summary>
    static void Hedge(string name, Transform parent, Vector3 pos, Vector3 size)
    {
        var body = Box(name + "_Body", parent, pos + new Vector3(0, size.y * 0.5f, 0), size, "M_Lawn");
        body.layer = LayerCameraNoCollision;
        int n = Mathf.Max(1, Mathf.RoundToInt(Mathf.Max(size.x, size.z) / 1.1f));
        bool alongX = size.x >= size.z;
        for (int i = 0; i < n; i++)
        {
            float t = (i + 0.5f) / n - 0.5f;
            var p = pos + new Vector3(alongX ? t * size.x : 0, size.y, alongX ? 0 : t * size.z);
            var s = LowSphere(name + "_Top" + i, parent, p, 0.42f, "M_Lawn");
            s.transform.localScale = alongX
                ? new Vector3(size.x / n * 1.15f, 0.55f, size.z * 1.05f)
                : new Vector3(size.x * 1.05f, 0.55f, size.z / n * 1.15f);
            s.layer = LayerCameraNoCollision;
        }
    }

    static void TreePit(string name, Transform parent, Vector3 pos, float r)
    {
        MeshRing(name + "_Ring", parent, r, r + 0.16f, 20, pos + new Vector3(0, 0.03f, 0), "M_Concrete");
        MeshDisc(name + "_Soil", parent, r, 20, pos + new Vector3(0, 0.02f, 0), "M_Brick");
    }

    /// <summary>室内盆栽：陶盆 + 三团叶子；放在地上，别用 collider 挡路</summary>
    static void PottedPlant(string name, Transform parent, Vector3 pos, float scale)
    {
        var root = new GameObject(name).transform;
        root.SetParent(parent, false);
        root.localPosition = pos;
        root.localScale = Vector3.one * scale;
        root.gameObject.layer = LayerCameraNoCollision;

        var pot = Cyl("Pot", root, 0.20f, 0.34f, new Vector3(0, 0.17f, 0), "M_Brick");
        UnityEngine.Object.DestroyImmediate(pot.GetComponent<Collider>());
        Cyl("PotRim", root, 0.22f, 0.05f, new Vector3(0, 0.35f, 0), "M_Brick");

        var l1 = Sphere("LeafA", root, new Vector3(0, 0.66f, 0), 0.30f, "M_Lawn");
        l1.transform.localScale = new Vector3(1.15f, 0.95f, 1.15f);
        var l2 = Sphere("LeafB", root, new Vector3(0.17f, 0.56f, 0.10f), 0.20f, "M_Lawn");
        var l3 = Sphere("LeafC", root, new Vector3(-0.14f, 0.58f, -0.12f), 0.18f, "M_Lawn");
        foreach (var s in new[] { l1, l2, l3 })
        {
            s.layer = LayerCameraNoCollision;
            UnityEngine.Object.DestroyImmediate(s.GetComponent<Collider>());
        }
    }

    // ---------------------------------------------------------------- 细节总装

    static void BuildDetails(Transform outdoor, Transform indoor)
    {
        // ---- 室外：树池 ----
        for (int i = 0; i < 8; i++)
        {
            float a = i * 45f;
            var p = Polar(20.5f, a);
            if (p.z < -6f && Mathf.Abs(p.x) < 9f) continue;   // 让开主干道（与 BuildProps 同规则）
            TreePit("TreePit_" + i, outdoor, new Vector3(p.x, 0, p.z), 0.62f);
        }

        // ---- 室外：主干道两侧绿篱 ----
        Hedge("Hedge_W1", outdoor, new Vector3(-4.6f, 0, -16.0f), new Vector3(0.9f, 0.55f, 7.0f));
        Hedge("Hedge_E1", outdoor, new Vector3(4.6f, 0, -16.0f), new Vector3(0.9f, 0.55f, 7.0f));
        Hedge("Hedge_W2", outdoor, new Vector3(-4.6f, 0, -6.0f), new Vector3(0.9f, 0.55f, 6.0f));
        Hedge("Hedge_E2", outdoor, new Vector3(4.6f, 0, -6.0f), new Vector3(0.9f, 0.55f, 6.0f));

        // ---- 室外：楼前与广场边缘灌木 ----
        float[] frontX = { -16.5f, -13.6f, -10.7f, 10.7f, 13.6f, 16.5f };
        for (int i = 0; i < frontX.Length; i++)
            Bush("Bush_Front" + i, outdoor, new Vector3(frontX[i], 0, 17.4f), 1.0f + (i % 3) * 0.12f);

        for (int i = 0; i < 10; i++)
        {
            float a = i * 36f + 18f;
            var p = Polar(16.4f, a);
            if (Mathf.Abs(p.x) < 5.5f && p.z < 0) continue;    // 让开主干道
            Bush("Bush_Plaza" + i, outdoor, new Vector3(p.x, 0, p.z), 0.85f + (i % 4) * 0.1f);
        }

        // 校门两侧
        Bush("Bush_GateL", outdoor, new Vector3(-8.2f, 0, -21.4f), 1.15f);
        Bush("Bush_GateR", outdoor, new Vector3(8.2f, 0, -21.4f), 1.15f);

        // 操场边
        for (int i = 0; i < 5; i++)
            Bush("Bush_Field" + i, outdoor, new Vector3(-28f + (i - 2) * 7.5f, 0, 8.4f), 0.9f + (i % 2) * 0.15f);

        // ---- 室内：盆栽 ----
        var pots = new[]
        {
            new Vector3(-5.05f, F1, 19.45f), new Vector3(5.05f, F1, 19.45f),      // 门厅北侧两角
            new Vector3(-16.7f, F1, 22.9f), new Vector3(16.7f, F1, 22.9f),         // 一层走廊两端
            new Vector3(-16.7f, F2, 22.9f), new Vector3(16.7f, F2, 22.9f),         // 二层
            new Vector3(-16.7f, F3, 22.9f), new Vector3(16.7f, F3, 22.9f),         // 三层
            new Vector3(9.2f, F2, 31.6f), new Vector3(13.05f, F3, 26.2f),          // 楼梯厅 / 阅览角（让开书架）
            new Vector3(-17.1f, F1, 31.5f), new Vector3(-17.1f, F3, 31.5f),        // 教室西北角（东角已让给书柜）
        };
        for (int i = 0; i < pots.Length; i++)
            PottedPlant("Plant_" + i, indoor, pots[i], 1.0f + (i % 3) * 0.12f);

        // ---- 海报 ----
        // 走廊北墙朝南（墙内表面 Z = 23.4），门之间是整段墙 —— 最自然的张贴位置
        float[] corridorX = { -8.8f, 0f, 8.8f };
        for (int i = 0; i < corridorX.Length; i++)
        {
            // 每层 3 张各用一张不同的图：15 处海报正好铺满 01–15
            AddPoster("Poster_1F_" + i, indoor, new Vector3(corridorX[i], F1 + 1.15f, 23.38f),
                1.05f, 1.45f, i, 180f);
            AddPoster("Poster_2F_" + i, indoor, new Vector3(corridorX[i], F2 + 1.15f, 23.38f),
                1.05f, 1.45f, i + 3, 180f);
            AddPoster("Poster_3F_" + i, indoor, new Vector3(corridorX[i], F3 + 1.15f, 23.38f),
                1.05f, 1.45f, i + 6, 180f);
        }
        // 门斗两侧墙
        // 门斗侧壁有 0.1 厚的 In_PorchLining（内表面 x=±5.41），海报必须贴在这个内表面上，
        // 贴到 ±5.57 会被内衬板整个挡住（射线实测距离 0.06，等于埋进板里）
        AddPoster("Poster_LobbyW", indoor, new Vector3(-5.39f, F1 + 1.35f, 17.9f), 0.95f, 1.3f, 9, 90f);
        AddPoster("Poster_LobbyE", indoor, new Vector3(5.39f, F1 + 1.35f, 17.9f), 0.95f, 1.3f, 10, -90f);
        // 二层楼梯厅北墙
        AddPoster("Poster_Hall2", indoor, new Vector3(15.2f, F2 + 2.3f, 32.06f), 1.2f, 1.6f, 11, 180f);
        AddPoster("Poster_Read3", indoor, new Vector3(8.98f, F3 + 1.4f, 27.4f), 1.0f, 1.35f, 12, 90f);
        // 教室隔墙（朝西那面）
        AddPoster("Poster_R0", indoor, new Vector3(-8.98f, F1 + 1.35f, 28.6f), 0.95f, 1.3f, 13, -90f);
        AddPoster("Poster_R1", indoor, new Vector3(-0.18f, F1 + 1.35f, 28.6f), 0.95f, 1.3f, 14, -90f);
    }

}
