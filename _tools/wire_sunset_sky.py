"""
把生成的夕阳天空接成 Unity 资产：
  1) 天空贴图 .meta（latlong cubemap 导入设置）
  2) 天空盒材质 .mat（复用 SDK 的 World_Skybox 着色器）
  3) 环境配置 .pbjson（复制 Dusk01，改光/雾/天空盒引用）

只生成文件，真正的赋值在 DouyinCampusBuilder 里。
"""
import json
import pathlib
import shutil
import uuid

ROOT = pathlib.Path(__file__).resolve().parent.parent
SDK_ENV = ROOT / "Assets/DouyinVCreateSDK/World/Examples/DouyinSceneEnvironment"

TEX_PNG = ROOT / "Assets/Campus/Textures/Sky/Skybox_CampusSunset.png"
TEX_META_SRC = SDK_ENV / "Tex/Skybox/Skybox_Dusk01.tga.meta"
MAT_SRC = SDK_ENV / "Mat/Skybox_Dusk01_mat.mat"
MAT_META_SRC = SDK_ENV / "Mat/Skybox_Dusk01_mat.mat.meta"
PROFILE_SRC = SDK_ENV / "EnvConfig/DouyinSceneEnvProfile_Dusk01.pbjson"
PROFILE_META_SRC = SDK_ENV / "EnvConfig/DouyinSceneEnvProfile_Dusk01.pbjson.meta"

MAT_OUT = ROOT / "Assets/Campus/Environment/Skybox_CampusSunset_mat.mat"
PROFILE_OUT = ROOT / "Assets/Campus/Environment/DouyinSceneEnvProfile_Sunset01.pbjson"

SUN_AZ = 285.0          # 太阳方位（与贴图一致）
SUN_EL = 14.0           # 太阳高度
LIGHT_YAW = SUN_AZ - 180.0   # 光从太阳方向射过来，所以朝向相反


def new_guid():
    return uuid.uuid4().hex


def main():
    tex_guid = new_guid()
    mat_guid = new_guid()
    prof_guid = new_guid()

    # 1) 贴图 meta：沿用 SDK 的 latlong cubemap 设置，只换 guid
    meta = TEX_META_SRC.read_text(encoding="utf-8")
    meta = meta.replace("guid: 600539c5513235e4a9743073d339c744", f"guid: {tex_guid}")
    TEX_PNG.with_suffix(".png.meta").write_text(meta, encoding="utf-8")

    # 2) 材质：复制 Dusk，替换名字与 _Tex 引用
    mat = MAT_SRC.read_text(encoding="utf-8")
    mat = mat.replace("m_Name: Skybox_Dusk01_mat", "m_Name: Skybox_CampusSunset_mat")
    mat = mat.replace("m_Texture: {fileID: 8900000, guid: 600539c5513235e4a9743073d339c744, type: 3}",
                      f"m_Texture: {{fileID: 8900000, guid: {tex_guid}, type: 3}}")
    mat = mat.replace("  - _Exposure: 1\n", "  - _Exposure: 1.05\n")
    MAT_OUT.parent.mkdir(parents=True, exist_ok=True)
    MAT_OUT.write_text(mat, encoding="utf-8")

    mat_meta = MAT_META_SRC.read_text(encoding="utf-8")
    mat_meta = mat_meta.replace("guid: d7f3c003bcc88a745a1192b43e1d0e5b", f"guid: {mat_guid}")
    MAT_OUT.with_suffix(".mat.meta").write_text(mat_meta, encoding="utf-8")

    # 3) 环境配置
    prof = json.loads(PROFILE_SRC.read_text(encoding="utf-8"))
    prof["mainLightColor"] = {"r": 1.0, "g": 0.62, "b": 0.40, "a": 1.0}
    prof["mainLightStrength"] = 3.6
    prof["mainLightDir"] = {"x": SUN_EL, "y": LIGHT_YAW % 360.0, "z": 0.0}
    prof["fogColor"] = {"r": 0.74, "g": 0.46, "b": 0.325, "a": 1.0}
    prof["startFog"] = 30.0
    prof["endFog"] = 320.0
    prof["skyMaterial"] = {"instanceID": 0}
    prof["skyMaterialGUID"] = mat_guid
    prof["flareEnable"] = False          # 原光晕位置是按旧太阳摆的，先关掉避免错位
    prof["havelenFlareObj"] = False
    PROFILE_OUT.write_text(json.dumps(prof, ensure_ascii=False), encoding="utf-8")

    prof_meta = PROFILE_META_SRC.read_text(encoding="utf-8")
    prof_meta = prof_meta.replace("guid: 5e4887a2eb8de974aa6aa8383bfb00f9", f"guid: {prof_guid}")
    PROFILE_OUT.with_suffix(".pbjson.meta").write_text(prof_meta, encoding="utf-8")

    print("tex_guid  =", tex_guid)
    print("mat_guid  =", mat_guid)
    print("prof_guid =", prof_guid)


if __name__ == "__main__":
    main()
