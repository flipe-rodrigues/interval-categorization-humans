using UnityEngine;

public class KeyPressEvent
{
    public KeyCode KeyCode { get { return _keyCode; } }
    public string KeyState { get { return _keyState; } }
    public float Time { get { return _time; } }

    private KeyCode _keyCode;
    private string _keyState;
    private float _time;

    public KeyPressEvent(KeyCode keyCode, string keyState, float time)
    {
        _keyCode = keyCode;
        _keyState = keyState;
        _time = time;
    }
}