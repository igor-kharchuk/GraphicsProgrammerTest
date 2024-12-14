using UnityEngine;
using TMPro;

public class FPSDisplayTMP : MonoBehaviour {
    [Header("UI Settings")]
    public TextMeshProUGUI fpsText; // Перетягніть TextMeshProUGUI сюди
    public Color goodColor = Color.green;
    public Color averageColor = Color.yellow;
    public Color badColor = Color.red;

    private float deltaTime = 0.0f;

    void Update() {
        // Обчислення FPS
        deltaTime += (Time.deltaTime - deltaTime) * 0.1f;
        float fps = 1.0f / deltaTime;

        // Оновлення тексту
        fpsText.text = $"FPS: {Mathf.Ceil(fps)}";

        // Зміна кольору тексту залежно від FPS
        if (fps >= 60) {
            fpsText.color = goodColor;
        } else if (fps >= 30) {
            fpsText.color = averageColor;
        } else {
            fpsText.color = badColor;
        }
    }
}


