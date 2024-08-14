using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class KeyPressTracker : MonoBehaviour
{
    public List<KeyPressEvent> KeyPresses { get; private set; }

    private void Start()
    {
        KeyPresses = new List<KeyPressEvent>();
    }

    void FixedUpdate()
    {
        foreach (KeyCode keyCode in System.Enum.GetValues(typeof(KeyCode)))
        {
            if (Input.GetKeyDown(keyCode))
            {
                KeyPressEvent entry = new KeyPressEvent(keyCode, "DOWN", Time.timeSinceLevelLoad);

                KeyPresses.Add(entry);
            }
            if (Input.GetKeyUp(keyCode))
            {
                KeyPressEvent entry = new KeyPressEvent(keyCode, "UP", Time.timeSinceLevelLoad);

                KeyPresses.Add(entry);
            }
        }
    }

    public void SyncPulse(float label)
    {
        KeyPressEvent entry = new KeyPressEvent(KeyCode.None, label.ToString(), Time.timeSinceLevelLoad);

        KeyPresses.Add(entry);
    }
}