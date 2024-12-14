using UnityEngine;
using UnityEngine.Rendering;

public class BrushProjectorTouch : MonoBehaviour {
    [Header("Brush Settings")]
    public float brushSize = 0.5f; 
    public LayerMask paintableLayers; 

    public Shader paintMaskShader;
    private RenderTexture paintedRT;
    private CommandBuffer cmd;
    private Material paintMaterial;

    private Vector3 hitPoint;
    private Vector2 hitUV;
    public bool isPainting { get; private set; }

    public Transform gizmoObject;
    private Material gizmoObjectMaterial;

    void Start() {
        // Ініціалізація RenderTexture
        paintedRT = new RenderTexture(512, 512, 0, RenderTextureFormat.RGHalf) {
            enableRandomWrite = true
        };
        
        // Ініціалізація матеріалу
        paintMaterial = new Material(paintMaskShader);
        paintMaterial.SetTexture("_PreviousTexture", paintedRT);

        // Ініціалізація CommandBuffer
        cmd = new CommandBuffer { name = "Draw Painted Texture" };

        // Отримання матеріалу Gizmo
        gizmoObjectMaterial = gizmoObject.GetComponent<MeshRenderer>().sharedMaterial;
    }

    void Update() {
        bool paint = false;

        // Отримання позиції торкання
        Vector2 position = Vector2.zero;
        if (Input.touchCount > 0) {
            Touch touch = Input.GetTouch(0);
            position = touch.position;

            Ray ray = Camera.main.ScreenPointToRay(position);
            if (Physics.Raycast(ray, out RaycastHit hit, Mathf.Infinity, paintableLayers)) {
                hitPoint = hit.point;

                // Обчислення UV через Bounds
                Bounds planeBounds = hit.collider.GetComponent<Renderer>().bounds;

                hitUV = new Vector2(
                    Mathf.InverseLerp(planeBounds.min.x, planeBounds.max.x, hitPoint.x),
                    Mathf.InverseLerp(planeBounds.min.z, planeBounds.max.z, hitPoint.z)
                );

                paint = true;
                SetGizmoColor(Color.green);
            } else {
                SetGizmoColor(Color.red);
            }
        } else {
            SetGizmoColor(Color.red);
        }

        DrawPaintedTexture(paint);
        DrawBrushGizmo();
    }

    void OnDestroy() {
        paintedRT?.Release();
    }

    public Vector3 GetBrushPosition() {
        return hitPoint;
    }

    private void DrawBrushGizmo() {
        gizmoObject.position = GetBrushPosition();
    }

    private void SetGizmoColor(Color color) {
        gizmoObjectMaterial.color = color;
    }

    private void DrawPaintedTexture(bool paint) {
        cmd.Clear();

        paintMaterial.SetFloat("_Paint", paint ? 1.0f : 0.0f);
        paintMaterial.SetFloat("_DeltaTime", Time.deltaTime * 2);
        paintMaterial.SetVector("_BrushSettings", new Vector4(hitUV.x, hitUV.y, brushSize, 0));
        paintMaterial.SetTexture("_PreviousTexture", paintedRT);

        cmd.Blit(null, paintedRT, paintMaterial);
        cmd.SetGlobalTexture("_PaintTexture", paintedRT);

        Graphics.ExecuteCommandBuffer(cmd);
    }
}
