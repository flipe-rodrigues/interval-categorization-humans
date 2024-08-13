using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class TaskManager : Singleton<TaskManager>
{
    // Public property accessors
    public bool AwaitingChoice { get; private set; }
    public int TrialCounter { get; private set; }
    public int ValidTrialCounter { get; private set; }
    public Phase Phase => stimulusPanel.CurrentStimulus.Phase;

    // Public fields
    public float categoryBoundary = 1f;
    public float interTrialInterval = 3f;
    public float timePenalty = 1f;
    public bool isInitiationRequired = true;
    public bool isFixationRequired = false;
    public ButtonBhv initiationButton;
    public ButtonBhv longButton;
    public ButtonBhv shortButton;
    public StimulusPanelBhv stimulusPanel;
    public FeedbackBhv feedbackPanel;
    public TrajectoryTracker trajectoryTracker;
    public enum InputMode
    {
        Mouse,
        Keyboard
    }
    public InputMode inputMode;

    // Private fieldss
    private WriteData2CSV _fileHandler;
    private bool _ongoingTrial;
    private bool _abortedPreviousTrial;

    private void Start()
    {
        _fileHandler = this.GetComponent<WriteData2CSV>();

        this.HandleTaskVariantAssignment();
    }

    private void HandleTaskVariantAssignment()
    {
        if (UIManager.subjectCode == null)
        {
            return;
        }

        if (UIManager.subjectCode.Contains("I"))        // "I" for "Initiation"
        {
            isInitiationRequired = true;
        }
        else if (UIManager.subjectCode.Contains("P"))   // "P" for "Passive"
        {
            isInitiationRequired = false;
        }
        if (UIManager.subjectCode.Contains("M"))        // "M" for "Mouse"
        {
            inputMode = InputMode.Mouse;
        }
        else if (UIManager.subjectCode.Contains("K"))   // "K" for "Keyboard"
        {
            inputMode = InputMode.Keyboard;
        }
    }

    private void Update()
    {
        if (!_ongoingTrial && Time.timeSinceLevelLoad > interTrialInterval)
        {
            StartCoroutine(this.TaskCoroutine());
        }
    }

    private IEnumerator TaskCoroutine()
    {
        _ongoingTrial = true;

        stimulusPanel.DrawNextStimulus();

        trajectoryTracker.SyncPulse(new float[] { -100, -100, -100, -100, -100, Time.timeSinceLevelLoad });

        this.TrialCounter++;

        initiationButton.LightsOn();

        while (!initiationButton.IsPressed && (isInitiationRequired || this.TrialCounter == 1))
        {
            yield return null;
        }
        trajectoryTracker.SyncPulse(new float[] { -200, -200, -200, -200, -200, Time.timeSinceLevelLoad });

        stimulusPanel.LightsOn();
        initiationButton.LightsOff();

        float duration = stimulusPanel.CurrentStimulus.Duration;
        float choiceTime = Time.timeSinceLevelLoad + duration;

        while (Time.timeSinceLevelLoad < choiceTime)
        {
            if (longButton.IsPressed || shortButton.IsPressed || (!initiationButton.IsPressed && isFixationRequired))
            {
                initiationButton.LightsOff();
                longButton.LightsOff();
                shortButton.LightsOff();
                stimulusPanel.LightsOff();

                feedbackPanel.Abort();

                if (_abortedPreviousTrial)
                {
                    stimulusPanel.StimulusIndex++;
                }

                if (!_abortedPreviousTrial)
                {
                    _abortedPreviousTrial = true;
                }

                _fileHandler.WriteBhvTrial(duration, -1, -1, -1, -1, stimulusPanel.GetImgName());
                _fileHandler.WriteTrackingTrial();

                yield return new WaitForSeconds(interTrialInterval * 2 / 3);

                feedbackPanel.Neutral();

                yield return new WaitForSeconds(interTrialInterval * 1 / 3);

                _ongoingTrial = stimulusPanel.Check4Quits();

                yield break;
            }
            yield return null;
        }

        float reactionTime = Time.timeSinceLevelLoad;

        longButton.LightsOn();
        shortButton.LightsOn();
        stimulusPanel.LightsOff();

        while (initiationButton.IsTouched)
        {
            yield return null;
        }
        trajectoryTracker.SyncPulse(new float[] { -300, -300, -300, -300, -300, Time.timeSinceLevelLoad });

        reactionTime = Time.timeSinceLevelLoad - reactionTime;

        float movementTime = Time.timeSinceLevelLoad;

        while (!longButton.IsPressed && !shortButton.IsPressed)
        {
            yield return null;
        }
        trajectoryTracker.SyncPulse(new float[] { -400, -400, -400, -400, -400, Time.timeSinceLevelLoad });

        movementTime = Time.timeSinceLevelLoad - movementTime;

        int choiceLong;
        int choiceCorrect;

        if (duration == categoryBoundary)
        {
            int die = Random.Range(0, 2);
            if (die == 0)
            {
                choiceLong = longButton.IsPressed ? 1 : 0;
                choiceCorrect = 0;
                feedbackPanel.Negative();
            }
            else
            {
                choiceLong = longButton.IsPressed ? 1 : 0;
                choiceCorrect = 1;
                feedbackPanel.Positive();
            }
        }

        else if (longButton.IsPressed && duration < categoryBoundary ||
                 shortButton.IsPressed && duration > categoryBoundary)
        {
            choiceLong = longButton.IsPressed ? 1 : 0;
            choiceCorrect = 0;
            feedbackPanel.Negative();
        }

        else
        {
            choiceLong = longButton.IsPressed ? 1 : 0;
            choiceCorrect = 1;
            feedbackPanel.Positive();
        }

        initiationButton.LightsOff();
        longButton.LightsOff();
        shortButton.LightsOff();

        _fileHandler.WriteBhvTrial(duration, reactionTime, movementTime, choiceLong, choiceCorrect, stimulusPanel.GetImgName());
        _fileHandler.WriteTrackingTrial();

        this.ValidTrialCounter++;

        stimulusPanel.StimulusIndex++;

        _abortedPreviousTrial = false;

        float iti = interTrialInterval + timePenalty * choiceCorrect;

        yield return new WaitForSeconds(iti * 2 / 3);

        feedbackPanel.Neutral();

        yield return new WaitForSeconds(iti * 1 / 3);

        _ongoingTrial = stimulusPanel.Check4Quits();
    }
}
