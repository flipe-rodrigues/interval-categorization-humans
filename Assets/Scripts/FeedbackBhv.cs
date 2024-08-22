using UnityEngine;
using System.Collections;

public class FeedbackBhv : MonoBehaviour {

    private Color EmissionColor
    {
        get { return _renderer.material.GetColor("_EmissionColor"); }
        set { _renderer.material.SetColor("_EmissionColor", value); }
    }
    private Texture EmissionMap
    {
        get { return _renderer.material.GetTexture("_EmissionMap"); }
        set { _renderer.material.SetTexture("_EmissionMap", value); }
    }

    [Range(1, 100)]
    public float changeSpeed = 25f;
    public Texture positiveFeedbackTexture;
    public Texture negativeFeedbackTexture;
    public Texture abortFeedbackTexture;
    public Texture unknownFeedbackTexture;

    private Renderer _renderer;
    private Light _light;

    private Color _targetColor;
    private byte _targetIntensity;

    void Awake()
    {
        _renderer = this.GetComponent<Renderer>();
        _light = this.GetComponentInChildren<Light>();
    }

    void Update()
    {
        float lerpSpeed = changeSpeed * Time.deltaTime;
        this.EmissionColor = Color.Lerp(this.EmissionColor, _targetColor, lerpSpeed);
        _light.intensity = Mathf.Lerp(_light.intensity, _targetIntensity, lerpSpeed);
        _light.color = this.EmissionColor;
    }

    public void Positive()
    {
        this.EmissionMap = TaskManager.Instance.Phase == Phase.Test ? unknownFeedbackTexture : positiveFeedbackTexture;
        _targetColor = TaskManager.Instance.Phase == Phase.Test ? Color.white : Color.green;
        _targetIntensity = 1;
    }

    public void Abort()
    {
        this.EmissionMap = abortFeedbackTexture;
        _targetColor = Color.yellow;
        _targetIntensity = 1;
    }

    public void Negative()
    {
        this.EmissionMap = TaskManager.Instance.Phase == Phase.Test ? unknownFeedbackTexture : negativeFeedbackTexture;
        _targetColor = TaskManager.Instance.Phase == Phase.Test ? Color.white : Color.red;
        _targetIntensity = 1;
    }

    public void Neutral()
    {
        _targetColor = Color.clear;
        _targetIntensity = 0;
    }
}
