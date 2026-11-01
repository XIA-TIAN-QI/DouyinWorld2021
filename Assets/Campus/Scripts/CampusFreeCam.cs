using UnityEngine;

/// <summary>
/// 场景预览用的自由视角相机（只在编辑器里本地看，不参与抖音世界打包）。
///
/// 用法：菜单「抖音虚拟创作SDK → 校园：开启自由视角（Play 模式）」，
/// 会在当前场景里临时生成一台相机并自动进入 Play 模式。
/// 生成的对象带 HideFlags.DontSave，保存场景也不会写进 Campus.unity。
///
/// 操作：
///   按住右键拖动 —— 转视角（左右转头 / 上下抬头）
///   W A S D      —— 前后左右平移（相对当前朝向，贴地飞行）
///   Q / E        —— 下降 / 上升
///   按住 Shift   —— 加速 3 倍
///   滚轮         —— 调整基础速度（1~40 m/s）
///   R            —— 回到出生点
/// </summary>
public class CampusFreeCam : MonoBehaviour
{
    public float baseSpeed = 6f;
    public float sprintMul = 3f;
    public float mouseSensitivity = 2.4f;

    Vector3 spawnPos;
    Quaternion spawnRot;
    float yaw, pitch;

    void Start()
    {
        spawnPos = transform.position;
        spawnRot = transform.rotation;
        var e = transform.eulerAngles;
        yaw = e.y;
        pitch = e.x > 180f ? e.x - 360f : e.x;
    }

    void Update()
    {
        if (Input.GetMouseButton(1))
        {
            yaw += Input.GetAxis("Mouse X") * mouseSensitivity;
            pitch -= Input.GetAxis("Mouse Y") * mouseSensitivity;
            pitch = Mathf.Clamp(pitch, -89f, 89f);
            transform.rotation = Quaternion.Euler(pitch, yaw, 0f);
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            transform.position = spawnPos;
            transform.rotation = spawnRot;
            var e = spawnRot.eulerAngles;
            yaw = e.y;
            pitch = e.x > 180f ? e.x - 360f : e.x;
        }

        float wheel = Input.mouseScrollDelta.y;
        if (Mathf.Abs(wheel) > 0.01f)
            baseSpeed = Mathf.Clamp(baseSpeed + wheel * 0.8f, 1f, 40f);

        var dir = Vector3.zero;
        if (Input.GetKey(KeyCode.W)) dir += transform.forward;
        if (Input.GetKey(KeyCode.S)) dir -= transform.forward;
        if (Input.GetKey(KeyCode.D)) dir += transform.right;
        if (Input.GetKey(KeyCode.A)) dir -= transform.right;
        if (Input.GetKey(KeyCode.E)) dir += Vector3.up;
        if (Input.GetKey(KeyCode.Q)) dir -= Vector3.up;

        if (dir.sqrMagnitude > 0.001f)
        {
            float sp = baseSpeed * (Input.GetKey(KeyCode.LeftShift) ? sprintMul : 1f);
            transform.position += dir.normalized * sp * Time.deltaTime;
        }
    }
}
