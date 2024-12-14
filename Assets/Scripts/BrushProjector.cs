using UnityEngine;
using UnityEngine.Rendering;

public class BrushProjector : MonoBehaviour {
    [Header("Brush Settings")]
    public float brushSize = 0.5f; 
    public LayerMask paintableLayers; 

    RenderTexture paintedRT;
    CommandBuffer cmd;
    public Material paintMaterial;
 
    private Vector3 hitPoint;
    private Vector2 hitUV;
    public bool isPainting { get; private set; }

    public Transform gizmoObject;
    Material gizmoObjectMaterial;

    void Start() {
        if(paintedRT == null){
            paintedRT = new RenderTexture(512, 512, 0, RenderTextureFormat.RG16);
            paintedRT.enableRandomWrite = true;
        }

        if(paintMaterial == null)
            paintMaterial = new Material(Shader.Find("Hidden/PaintShader"));

        cmd = new CommandBuffer();
        cmd.name = "Draw Painted Texture";  

        gizmoObjectMaterial = gizmoObject.GetComponent<MeshRenderer>().sharedMaterial;
    }

    void Update() {

        bool paint = false;
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        if (Physics.Raycast(ray, out RaycastHit hit, Mathf.Infinity, paintableLayers)) {
            hitPoint = hit.point;
            hitUV = hit.textureCoord;
            if(Input.GetMouseButton(0)) {
                SetGizmoColor(Color.green);
                paint = true;
            } else {
                SetGizmoColor(Color.red);
                paint = false;
            }
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
        paintMaterial.SetFloat("_Paint", paint == true ? 1.0f : 0.0f);
        paintMaterial.SetFloat("_DeltaTime", Time.deltaTime * 2);
        paintMaterial.SetVector("_BrushSettings", new Vector4(hitUV.x, hitUV.y, brushSize, 0));
        paintMaterial.SetTexture("_PreviousTexture", paintedRT);
        cmd.Blit(null, paintedRT, paintMaterial);
        cmd.SetGlobalTexture("_PaintTexture", paintedRT);

        Graphics.ExecuteCommandBuffer(cmd);
    }
}
