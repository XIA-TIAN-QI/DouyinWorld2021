using System;
using UnityEngine;
using UnityEditor;
using System.IO;

namespace LuaLS.Editor
{
    public class LuaLsEnvInstallerWindow : EditorWindow
    {
        private string _installPath = "";

        [MenuItem("抖音虚拟创作SDK/工具箱/代码补全环境安装")]
        public static void Menu()
        {
            Sign(ShowWindow);
        }
        
        private static void ShowWindow()
        {
            var window = GetWindow<LuaLsEnvInstallerWindow>("安装代码补全环境");
            window.minSize = new Vector2(800, 200);
            window.Show();
        }

        private static void Sign(Action action)
        {
            EditorUtil.Sign(SdkContentType.World, action);
        }        

        private void OnEnable()
        {
            if (string.IsNullOrEmpty(_installPath))
            {
                DirectoryInfo rootDir = Directory.GetParent(Application.dataPath);
                if (rootDir != null)
                {
                    _installPath = rootDir.FullName;
                }
            }
        }

        private void OnGUI()
        {
            EditorGUILayout.BeginHorizontal();
            {
                _installPath = EditorGUILayout.TextField("安装路径:", _installPath);
                if (GUILayout.Button("浏览...", GUILayout.Width(80)))
                {
                    string selectedPath = EditorUtility.OpenFolderPanel("选择安装目录", _installPath, "");
                    if (!string.IsNullOrEmpty(selectedPath))
                    {
                        _installPath = selectedPath;
                        GUI.FocusControl(null); 
                    }
                }
            }

            if (GUILayout.Button("安装", GUILayout.Width(80)))
            {
                PerformInstall();
            }
            EditorGUILayout.EndHorizontal();


            Color originalColor = GUI.color;
            GUI.color = Color.yellow;
            EditorGUILayout.HelpBox("注意：安装操作将会覆盖目标路径下的同名文件，请确保已备份重要数据。", MessageType.Warning);
            GUI.color = originalColor;
        }

        // 实际的安装逻辑
        private void PerformInstall()
        {
            if (string.IsNullOrEmpty(_installPath))
            {
                EditorUtility.DisplayDialog("错误", "路径不能为空！", "确定");
                return;
            }

            if (!Directory.Exists(_installPath))
            {
                EditorUtility.DisplayDialog("错误", "选择的路径不存在！", "确定");
                return;
            }

            var result = LuaLsEnvInstaller.InstallFromZip(_installPath);
            if (result)
            {
                Close();
            }
        }
    }
}