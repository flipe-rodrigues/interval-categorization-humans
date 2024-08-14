using UnityEngine;

[System.Serializable]
public class Stimulus
{
    public Texture2D Image { get { return _image; } }
    public float Duration { get { return _duration; } }
    public float InterTrialInterval { get { return _interTrialInterval; } }
    public Phase Phase { get { return _phase; } }

    [SerializeField] private Texture2D _image;
    [SerializeField] private float _duration;
    [SerializeField] private float _interTrialInterval;
    [SerializeField] private Phase _phase;

    public Stimulus(Texture2D image, float duration, float interTrialInterval, Phase phase)
    {
        _image = image;
        _duration = duration;
        _interTrialInterval = interTrialInterval;
        _phase = phase;
    }
}

public enum Phase
{
    Train,
    Test
}