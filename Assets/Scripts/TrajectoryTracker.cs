using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class TrajectoryTracker : MonoBehaviour
{
    public List<float[]> MouseTrajectory => _mouseTrajectory;

    private List<float[]> _mouseTrajectory;

    private void Start()
    {
        _mouseTrajectory = new List<float[]>();
    }

    void FixedUpdate()
    {
        Vector2 p = Input.mousePosition;
        float leftMouseButton = Input.GetMouseButton(0) ? 1 : 0;
        float rightMouseButton = Input.GetMouseButton(1) ? 1 : 0;

        float[] entry;

        entry = new float[] { p.x, p.y, leftMouseButton, rightMouseButton, TaskManager.Instance.TrialCounter, Time.timeSinceLevelLoad };

        _mouseTrajectory.Add(entry);
    }

    public void SyncPulse(float[] entry)
    {
        if (_mouseTrajectory == null || _mouseTrajectory.Count == 0)
        {
            _mouseTrajectory = new List<float[]>();
        }

        _mouseTrajectory.Add(entry);
    }
}
