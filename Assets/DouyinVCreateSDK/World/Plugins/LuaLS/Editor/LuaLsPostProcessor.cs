using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace LuaLS.Editor
{
    public class LuaLsPostProcessor : AssetPostprocessor
    {
        private const string LuaLsAssetPath = "Assets/DouyinVCreateSDK/World/Plugins/LuaLS/LuaLS.bytes";
        private const string LuaLsHashPath = "Assets/DouyinVCreateSDK/World/Plugins/LuaLS/LuaLS.hash";
        private const string HashCachePath = "Library/LuaLS.hash";

        static void OnPostprocessAllAssets(
            string[] importedAssets,
            string[] deletedAssets,
            string[] movedAssets,
            string[] movedFromAssetPaths)
        {
            if (!importedAssets.Contains(LuaLsAssetPath))
                return;
            EditorApplication.delayCall += Check;
        }

        private static void Check()
        {
            if (CompareHash(HashCachePath, LuaLsHashPath))
            {
                Debug.Log("[LuaLS] LuaLS 未变化");
                return;
            }
            
            Directory.CreateDirectory(Path.GetDirectoryName(HashCachePath)!);
            File.Copy(LuaLsHashPath, HashCachePath, true);

            Debug.Log("[LuaLS] 检测到 LuaLS 更新");
            Install();
        }

        private static bool CompareHash(string oldPath, string newPath)
        {
            if (!File.Exists(oldPath))
            {
                return false;
            }
            var oldHash = File.ReadAllText(oldPath);
            var newHash = File.ReadAllText(newPath);
            return oldHash == newHash;
        }

        private static void Install()
        {
            bool confirm = EditorUtility.DisplayDialog(
                "LuaLS Environment Update",
                "检测到代码补全包更新，是否安装最新版本？",
                "更新",
                "取消"
            );
            if (!confirm) return;
            LuaLsEnvInstallerWindow.Menu();
        }
    }
}
