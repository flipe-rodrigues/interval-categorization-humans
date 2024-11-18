using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using System.IO;
using System;

public class WriteData2CSV : MonoBehaviour
{
    // Public fields
    public bool saveData;
    public TrajectoryTracker trajectoryTracker;
    public KeyPressTracker keyPressTracker;

    // Private fields
    private StreamWriter _swBhv;
    private StreamWriter _swMouseTrajectory;
    private StreamWriter _swKeyPress;

    private void Awake()
    {
        this.HomogeneizeAcrossCulturalSettings();
    }

    void Start()
    {
        if (!saveData)
        {
            return;
        }

        var now = System.DateTime.Now;

        string bhv_file = string.Concat(UIManager.subjectCode, "_", UIManager.subjectAge, "_", UIManager.subjectSex, "_", UIManager.subjectHandedness, "_TAFC_bhv_",
            now.Year, "_", now.Month, "_", now.Day, "_", now.Hour, "_", now.Minute, "_", now.Second, "_", now.Millisecond);
        this.CreateIfInexistent(Application.dataPath + "/Data" + "/Behavior");
        _swBhv = System.IO.File.CreateText(Application.dataPath + "//Data" + "//Behavior// " + bhv_file + ".csv");

        string mouseTrajectory_file = string.Concat(UIManager.subjectCode, "_", UIManager.subjectAge, "_", UIManager.subjectSex, "_TAFC_mouseTrajectories_",
            now.Year, "_", now.Month, "_", now.Day, "_", now.Hour, "_", now.Minute, "_", now.Second, "_", now.Millisecond);
        this.CreateIfInexistent(Application.dataPath + "/Data" + "/Mouse Trajectories");
        _swMouseTrajectory = System.IO.File.CreateText(Application.dataPath + "//Data" + "//Mouse Trajectories//" + mouseTrajectory_file + ".csv");

        string keyPress_file = string.Concat(UIManager.subjectCode, "_", UIManager.subjectAge, "_", UIManager.subjectSex, "_TAFC_keyPresses_",
            now.Year, "_", now.Month, "_", now.Day, "_", now.Hour, "_", now.Minute, "_", now.Second, "_", now.Millisecond);
        this.CreateIfInexistent(Application.dataPath + "/Data" + "/Key Presses");
        _swKeyPress = System.IO.File.CreateText(Application.dataPath + "//Data" + "//Key Presses//" + keyPress_file + ".csv");

        this.WriteHeaders();
    }

    private void HomogeneizeAcrossCulturalSettings()
    {
        CultureInfo customCulture = (CultureInfo)CultureInfo.InvariantCulture.Clone();
        customCulture.NumberFormat.NumberDecimalSeparator = "."; 
        customCulture.NumberFormat.NumberGroupSeparator = ",";
        CultureInfo.DefaultThreadCurrentCulture = customCulture; 
        CultureInfo.DefaultThreadCurrentUICulture = customCulture;
    }

    private void CreateIfInexistent(string folderPath)
    {
        if (!Directory.Exists(folderPath))
        {
            Directory.CreateDirectory(folderPath);
        }
    }

    private void WriteHeaders()
    {
        if (!saveData)
        {
            return;
        }

        string bhvHdr = "stimulus, reactionTime, movementTime, choiceLeft,  choiceLong, choiceCorrect, interTrialInterval, image";
        _swBhv.WriteLine(bhvHdr);
        _swBhv.Flush();

        string trajectoriesHdr = "position_x, position_y, left_button, right_button, trial, time";
        _swMouseTrajectory.WriteLine(trajectoriesHdr);
        _swMouseTrajectory.Flush();

        string keyPressesHdr = "key, state, time";
        _swKeyPress.WriteLine(keyPressesHdr);
        _swKeyPress.Flush();
    }

    public void WriteBhvTrial(float stim, float rt, float mt, int choiceLeft, int choiceLong, int choiceCorrect, float interTrialInterval, string imgName)
    {
        if (!saveData)
        {
            return;
        }

        string data = stim + "," + rt + "," + mt + "," + choiceLeft + "," + choiceLong + "," + choiceCorrect + "," + interTrialInterval + "," + imgName;
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

    public void WriteKeyPressTrial()
    {
        if (!saveData)
        {
            return;
        }

        foreach (KeyPressEvent k in keyPressTracker.KeyPresses)
        {
            string data = k.KeyCode + "," + k.KeyState + "," + k.Time;
            _swKeyPress.WriteLine(data);
        }
        _swKeyPress.Flush();
        keyPressTracker.KeyPresses.Clear();
    }

    void OnDisable()
    {
        if (!saveData)
        {
            return;
        }

        _swBhv.Close();
        _swMouseTrajectory.Close();
        _swKeyPress.Close();
    }
}
