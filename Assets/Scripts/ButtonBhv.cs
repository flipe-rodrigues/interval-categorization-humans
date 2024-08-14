using UnityEngine;
using System.Collections;

public class ButtonBhv : MonoBehaviour
{
    public bool IsPressed => _pressing;
    public bool IsTouched => _contact;

    private Color MainEmissionColor
    {
        get { return _mainRenderer.material.GetColor("_EmissionColor"); }
        set { _mainRenderer.material.SetColor("_EmissionColor", value); }
    }
    private Color FrameEmissionColor
    {
        get { return frameRenderer.material.GetColor("_EmissionColor"); }
        set { frameRenderer.material.SetColor("_EmissionColor", value); }
    }
    private Color LabelEmissionColor
    {
        get { return _labelRenderer.material.GetColor("_EmissionColor"); }
        set { _labelRenderer.material.SetColor("_EmissionColor", value); }
    }

    public enum Keys
    {
        D = KeyCode.D,
        Spacebar = KeyCode.Space,
        K = KeyCode.K
    }
    public Keys assignedKey = Keys.D;
    public enum ButtonRole
    {
        Short,
        Initiation,
        Long
    }
    public ButtonRole buttonRole;
    [Range(0, 100)]
    public float relaxSpeed = 1;
    [Range(1, 5)]
    public float changeSpeed = 2f;
    [Range(0, 1)]
    public float maxLightIntensity = .25f;
    [ColorUsage(false, true)]
    public Color bulbColor = Color.white;
    public Renderer frameRenderer;
    public Renderer initiationLabelRenderer;
    public Renderer shortLabelRenderer;
    public Renderer longLabelRenderer;

    private Transform _transform;
    private Rigidbody _rigidbody;
    private Renderer _mainRenderer;
    private Renderer _labelRenderer;
    private Light _light;
    private Color _targetMainColor;
    private Color _targetFrameColor;
    private Vector3 _initialPosition;
    private float _targetIntensity;
    [SerializeField] private bool _pressing = false;
    [SerializeField] private bool _contact = false;

    void Awake()
    {
        _transform = this.GetComponent<Transform>();
        _rigidbody = this.GetComponent<Rigidbody>();
        _mainRenderer = this.GetComponent<Renderer>();
        _light = this.GetComponentInChildren<Light>();
    }

    void Start()
    {
        _initialPosition = _transform.position;
    }

    public void SetButtonRole(ButtonRole role)
    {
        buttonRole = role;

        initiationLabelRenderer.gameObject.SetActive(buttonRole == ButtonRole.Initiation ? true : false);
        shortLabelRenderer.gameObject.SetActive(buttonRole == ButtonRole.Short ? true : false);
        longLabelRenderer.gameObject.SetActive(buttonRole == ButtonRole.Long ? true : false);

        switch (buttonRole) 
        {
            case ButtonRole.Initiation:

                _labelRenderer = initiationLabelRenderer;
                break;

            case ButtonRole.Short:

                _labelRenderer = shortLabelRenderer;
                break;

            case ButtonRole.Long:

                _labelRenderer = longLabelRenderer;
                break;
        }
    }

    void Update()
    {
        float lerpSpeed = (_targetIntensity == 1 ? 1 : 5) * changeSpeed * Time.deltaTime;
        this.MainEmissionColor = Color.Lerp(this.MainEmissionColor, _targetMainColor * 3f, lerpSpeed);
        this.FrameEmissionColor = Color.Lerp(this.FrameEmissionColor, _targetFrameColor * 3f, lerpSpeed);
        this.LabelEmissionColor = this.MainEmissionColor;
        _light.intensity = Mathf.Lerp(_light.intensity, _targetIntensity, lerpSpeed);
        this.Relax();

        if (TaskManager.Instance.inputMode == TaskManager.InputMode.Keyboard)
        {
            if (Input.GetKeyDown((KeyCode)assignedKey))
            {
                _rigidbody.AddForce(Vector3.down * .75f, ForceMode.Impulse);
                _pressing = true;
            }

            if (Input.GetKeyUp((KeyCode)assignedKey))
            {

                _pressing = false;
            }
        }
    }

    public void LightsOn()
    {
        _targetMainColor = bulbColor;
        _targetIntensity = maxLightIntensity;
    }

    public void LightsOff()
    {
        _targetMainColor = Color.clear;
        _targetIntensity = 0;
    }

    public void Relax()
    {
        if (!this.IsPressed)
        {
            Vector3 force = (_initialPosition - _transform.position) * relaxSpeed;
            _rigidbody.AddForce(force, ForceMode.Impulse);
        }
    }

    public void ContactBegin()
    {
        _targetFrameColor = bulbColor;
        _contact = true;
    }

    public void ContactEnd()
    {
        _targetFrameColor = Color.clear;
        _contact = false;
    }

    private void OnMouseEnter()
    {
        if (TaskManager.Instance.inputMode != TaskManager.InputMode.Mouse)
        {
            return;
        }

        this.ContactBegin();
    }

    private void OnMouseExit()
    {
        if (TaskManager.Instance.inputMode != TaskManager.InputMode.Mouse)
        {
            return;
        }

        this.ContactEnd();
    }

    private void OnMouseDown()
    {
        if (TaskManager.Instance.inputMode != TaskManager.InputMode.Mouse)
        {
            return;
        }

        _rigidbody.AddForce(Vector3.down * .75f, ForceMode.Impulse);
        _pressing = true;
    }

    private void OnMouseUp()
    {
        if (TaskManager.Instance.inputMode != TaskManager.InputMode.Mouse)
        {
            return;
        }

        _pressing = false;
    }
}
