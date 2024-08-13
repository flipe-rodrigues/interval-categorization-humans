using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System;

public class WriteData2CSV : MonoBehaviour
{
    // Public fields
    public bool saveData;
    public TrajectoryTracker trajectoryTracker;

    // Private fields
    private StreamWriter _swBhv;
    private StreamWriter _swMouseTrajectory;

    void Start()
    {
        if (!saveData)
        {
            return;
        }

        var now = System.DateTime.Now;
        
        string bhv_file = string.Concat(UIManager.subjectCode, "_", UIManager.subjectAge, "_", UIManager.subjectSex, "_", UIManager.subjectHandedness, "_TAFC_bhv_",
            now.Year, "_", now.Month, "_", now.Day, "_", now.Hour, "_", now.Minute, "_", now.Second, "_", now.Millisecond);
        _swBhv = System.IO.File.CreateText(Application.dataPath + "//Data" + "//Behavior//" + bhv_file + ".csv");

        string mouseTrajectory_file = string.Concat(UIManager.subjectCode, "_", UIManager.subjectAge, "_", UIManager.subjectSex, "_", "_TAFC_mouseTrajectories_",
            now.Year, "_", now.Month, "_", now.Day, "_", now.Hour, "_", now.Minute, "_", now.Second, "_", now.Millisecond);
        _swMouseTrajectory = System.IO.File.CreateText(Application.dataPath + "//Data" + "//Trajectories//" + mouseTrajectory_file + ".csv");

        this.WriteHeaders();
    }

    private void WriteHeaders()
    {
        if (!saveData)
        {
            return;
        }

        string bhvHdr = "interval, reactionTime, movementTime, choiceLong, choiceCorrect, image";
        _swBhv.WriteLine(bhvHdr);
        _swBhv.Flush();

        string trajectoriesHdr = "position_x, position_y, left_button, right_button, trial, time";
        _swMouseTrajectory.WriteLine(trajectoriesHdr);
        _swMouseTrajectory.Flush();
    }

    public void WriteBhvTrial(float stim, float rt, float mt, int choiceL, int choiceC, string imgName)
    {
        if (!saveData)
        {
            return;
        }

        string data = stim + "," + rt + "," + mt + "," + choiceL + "," + choiceC + "," + imgName;
        _swBhv.WriteLine(data);
        _swBhv.Flush();
    }

    public void WriteTrackingTrial()
    {
        if (!saveData)
        {
            return;
        }

        foreach (float[] p in trajectoryTracker.MouseTrajectory)
        {
            string data = string.Concat(p[0], ",", p[1], ",", p[2], ",", p[3], ",", p[4], ",", p[5]);
            _swMouseTrajectory.WriteLine(data);
        }
        _swMouseTrajectory.Flush();
        trajectoryTracker.MouseTrajectory.Clear();
    }

    void OnDisable()
    {
        if (!saveData)
        {
            return;
        }

        _swBhv.Close();
        _swMouseTrajectory.Close();
    }
}
