using UnityEngine;

[System.Serializable]
public class Stimulus
{
    public Texture2D Image { get { return _image; } }
    public float Duration { get { return _duration; } }
    public Phase Phase { get { return _phase; } }

    [SerializeField] private Texture2D _image;
    [SerializeField] private float _duration;
    [SerializeField] private Phase _phase;

    public Stimulus(Texture2D image, float duration, Phase phase)
    {
        _image = image;
        _duration = duration;
        _phase = phase;
    }
}

public enum Phase
{
    Train,
    Test
}