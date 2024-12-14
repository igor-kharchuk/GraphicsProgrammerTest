using UnityEngine;
using UnityEditor;
using System.IO;

public class GradientTextureWindow : EditorWindow
{
    private Gradient gradient = new Gradient();
    private int textureWidth = 256;
    private string savePath = "Assets/GradientTexture.png";

    [MenuItem("Tools/Gradient Texture Generator")]
    public static void ShowWindow()
    {
        GetWindow<GradientTextureWindow>("Gradient Texture Generator");
    }

    private void OnGUI()
    {
        GUILayout.Label("Gradient Texture Generator", EditorStyles.boldLabel);

        // Налаштування градієнта
        gradient = EditorGUILayout.GradientField("Gradient", gradient);

        // Введення ширини текстури
        textureWidth = EditorGUILayout.IntField("Texture Width", textureWidth);
        if (textureWidth < 1) textureWidth = 1;

        // Введення шляху збереження
        savePath = EditorGUILayout.TextField("Save Path", savePath);

        // Кнопка для генерації текстури
        if (GUILayout.Button("Generate and Save Texture"))
        {
            GenerateAndSaveGradientTexture();
        }
    }

    private void GenerateAndSaveGradientTexture()
    {
        // Створення текстури
        Texture2D texture = new Texture2D(textureWidth, 1, TextureFormat.RGBA32, false);

        // Генерація градієнта
        for (int x = 0; x < textureWidth; x++)
        {
            float t = (float)x / (textureWidth - 1); // Нормалізований відсоток позиції
            Color color = gradient.Evaluate(t); // Отримуємо колір із градієнта
            texture.SetPixel(x, 0, color);
        }

        // Застосування змін до текстури
        texture.Apply();

        // Збереження текстури у файл
        SaveTextureAsPNG(texture, savePath);

        Debug.Log($"Градієнтова текстура збережена за шляхом: {savePath}");
        AssetDatabase.Refresh(); // Оновлення вікна проекту
    }

    private void SaveTextureAsPNG(Texture2D texture, string path)
    {
        // Конвертуємо текстуру в PNG формат
        byte[] bytes = texture.EncodeToPNG();

        // Записуємо у файл
        File.WriteAllBytes(path, bytes);

        Debug.Log($"Файл успішно збережено: {path}");
    }
}

