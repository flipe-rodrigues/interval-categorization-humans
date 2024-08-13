using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class TrajectoryTracker : MonoBehaviour
{
    public List<float[]> MouseTrajectory { get; private set; }

    private void Start()
    {
        MouseTrajectory = new List<float[]>();
    }

    void FixedUpdate()
    {
        Vector2 p = Input.mousePosition;

        float leftMouseButton = Input.GetMouseButton(0) ? 1 : 0;
        float rightMouseButton = Input.GetMouseButton(1) ? 1 : 0;

        float[] entry;

        entry = new float[] { p.x, p.y, leftMouseButton, rightMouseButton, TaskManager.Instance.TrialCounter, Time.timeSinceLevelLoad };

        MouseTrajectory.Add(entry);
    }

    public void SyncPulse(float[] entry)
    {
        MouseTrajectory.Add(entry);
    }
}
