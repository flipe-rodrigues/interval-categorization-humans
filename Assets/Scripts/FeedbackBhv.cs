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

    [Range(1, 5)]
    public float changeSpeed = 2.5f;
    public Texture positiveFeedbackTexture;
    public Texture negativeFeedbackTexture;

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
        _targetColor = Color.green;
        _targetIntensity = 1;
        this.EmissionMap = positiveFeedbackTexture;
    }

    public void Abort()
    {
        _targetColor = Color.yellow;
        _targetIntensity = 1;
        this.EmissionMap = null;
    }

    public void Negative()
    {
        _targetColor = Color.red;
        _targetIntensity = 1;
        this.EmissionMap = negativeFeedbackTexture;
    }

    public void Neutral()
    {
        _targetColor = Color.clear;
        _targetIntensity = 0;
    }
}
