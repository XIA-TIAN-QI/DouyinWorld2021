using UnityEngine;
using UnityEditor;
using System.IO;
using System.IO.Compression;

namespace LuaLS.Editor
{
    public class LuaLsEnvInstaller : UnityEditor.Editor
    {
        private const string ZipFilePath = "DouyinVCreateSDK/World/Plugins/LuaLS/LuaLS.bytes";
        
        public static bool InstallFromZip(string installPath)
        {
            string zipAbsPath = Path.Combine(Application.dataPath,  ZipFilePath);

            if (!File.Exists(zipAbsPath))
            {
                EditorUtility.DisplayDialog(
                    "LuaLS Environment Installer",
                    $"找不到压缩包: {zipAbsPath}",
                    "确定");
                return false;
            }

            try
            {
                CleanUpOldFiles(installPath);
                ExtractZip(zipAbsPath, installPath);

                EditorUtility.DisplayDialog(
                    "LuaLS Environment Installer",
                    $"Lua LS 环境安装成功",
                    "确定");
                return true;
            }
            catch (System.Exception e)
            {
                EditorUtility.DisplayDialog(
                    "LuaLS Environment Installer",
                    $"安装失败: {e.Message}",
                    "确定");
                return false;
            }
        }
        
        private static void CleanUpOldFiles(string projectRoot)
        {
            string vscodeDir = Path.Combine(projectRoot, ".vscode");

            string[] explicitFilesToDelete = new string[]
            {
                // Path.Combine(projectRoot, ".vscode/variable.code-snippets")
                // 暂时不需要
            };

            foreach (var file in explicitFilesToDelete)
            {
                if (File.Exists(file))
                {
                    File.Delete(file);
                }
            }
            
            ClearDirectory(Path.Combine(projectRoot, "LuaLS"));
        }
        
        private static void ClearDirectory(string path)
        {
            if (!Directory.Exists(path))
                return;

            foreach (var file in Directory.GetFiles(path))
            {
                File.Delete(file);
            }

            foreach (var dir in Directory.GetDirectories(path))
            {
                Directory.Delete(dir, true);
            }
        }

        private static void ExtractZip(string zipPath, string extractToPath)
        {
            using (FileStream fs = new FileStream(zipPath, FileMode.Open))
            {
                using (ZipArchive archive = new ZipArchive(fs, ZipArchiveMode.Read))
                {
                    foreach (ZipArchiveEntry entry in archive.Entries)
                    {
                        string destinationPath = Path.GetFullPath(Path.Combine(extractToPath, entry.FullName));

                        if (!destinationPath.StartsWith(Path.GetFullPath(extractToPath))) continue;

                        if (string.IsNullOrEmpty(entry.Name))
                        {
                            Directory.CreateDirectory(destinationPath);
                        }
                        else
                        {
                            Directory.CreateDirectory(Path.GetDirectoryName(destinationPath));
                            entry.ExtractToFile(destinationPath, overwrite: true);
                        }
                    }
                }
            }
        }
    }
}