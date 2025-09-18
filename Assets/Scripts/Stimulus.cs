using System.Linq;
using UnityEngine;

[System.Serializable]
public class Stimulus
{
    public Texture2D Image { get { return _image; } }
    public Texture2D ScrambledImage { get { return _scrambledImage; } }
    public float PreStimulusDelay { get { return _preStimulusDelay; } }
    public float StimulusDuration { get { return _stimulusDuration; } }
    public float InterTrialInterval { get { return _interTrialInterval; } }
    public Phase Phase { get { return _phase; } }

    [SerializeField] private Texture2D _image;
    [SerializeField] private Texture2D _scrambledImage;
    [SerializeField] private float _preStimulusDelay;
    [SerializeField] private float _stimulusDuration;
    [SerializeField] private float _interTrialInterval;
    [SerializeField] private Phase _phase;

    public Stimulus(Texture2D image, float preStimulusDelay, float stimulusDuration, float interTrialInterval, Phase phase)
    {
        _image = MakeTextureReadable(image);
        _scrambledImage = ScrambleTexture(_image);
        _preStimulusDelay = preStimulusDelay;
        _stimulusDuration = stimulusDuration;
        _interTrialInterval = interTrialInterval;
        _phase = phase;
    }

    private Texture2D MakeTextureReadable(Texture2D original)
    {
        RenderTexture tmp = RenderTexture.GetTemporary(
            original.width,
            original.height,
            0,
            RenderTextureFormat.Default,
            RenderTextureReadWrite.Linear
        );

        Graphics.Blit(original, tmp);
        RenderTexture previous = RenderTexture.active;
        RenderTexture.active = tmp;

        Texture2D readableTexture = new Texture2D(original.width, original.height);
        readableTexture.ReadPixels(new Rect(0, 0, tmp.width, tmp.height), 0, 0);
        readableTexture.Apply();

        RenderTexture.active = previous;
        RenderTexture.ReleaseTemporary(tmp);

        return readableTexture;
    }

    private System.Random rng = new System.Random(); // for scrambling

    public Texture2D ScrambleTexture(Texture2D original)
    {
        Texture2D scrambled = new Texture2D(original.width, original.height, original.format, false);

        Color[] pixels = original.GetPixels();
        int[] indices = Enumerable.Range(0, pixels.Length).ToArray();

        // Shuffle indices
        for (int i = indices.Length - 1; i > 0; i--)
        {
            int j = rng.Next(i + 1);
            int temp = indices[i];
            indices[i] = indices[j];
            indices[j] = temp;
        }

        // Reorder pixels
        Color[] scrambledPixels = new Color[pixels.Length];
        for (int i = 0; i < pixels.Length; i++)
        {
            scrambledPixels[i] = pixels[indices[i]];
        }

        scrambled.SetPixels(scrambledPixels);
        scrambled.Apply();

        return scrambled;
    }
}

public enum Phase
{
    Train,
    Test
}
