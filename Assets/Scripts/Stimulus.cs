using UnityEngine;

[System.Serializable]
public class Stimulus
{
    public Texture2D Image { get { return _image; } }
    public float Duration { get { return _duration; } }

    [SerializeField] private Texture2D _image;
    [SerializeField] private float _duration;

    public Stimulus(Texture2D image, float duration)
    {
        _image = image;
        _duration = duration;
    }
}
