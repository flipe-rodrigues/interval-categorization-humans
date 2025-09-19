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
    public bool isInitiationRequired = true;
    public bool isFixationRequired = false;
    public ButtonBhv leftButton;
    public ButtonBhv centralButton;
    public ButtonBhv rightButton;
    public StimulusPanelBhv stimulusPanel;
    public FeedbackBhv feedbackPanel;
    public TrajectoryTracker trajectoryTracker;
    public KeyPressTracker keyPressTracker;
    public enum Contingency
    {
        LeftIsShortRightIsLong,
        RightIsShortLeftIsLong
    }
    public Contingency contingency;
    public enum InputMode
    {
        Mouse,
        Keyboard
    }
    public InputMode inputMode;

    // Private fieldss
    private WriteData2CSV _fileHandler;
    private ButtonBhv _initiationButton;
    private ButtonBhv _shortButton;
    private ButtonBhv _longButton;
    private float _feedbackDisplayDuration = .8f;
    private bool _ongoingTrial;
    private bool _abortedPreviousTrial;

    private void Start()
    {
        _fileHandler = this.GetComponent<WriteData2CSV>();

        this.ParseTaskVariant();

        this.HandleCursorVisibility();

        this.AssignButtonRoles();
    }

    private void ParseTaskVariant()
    {
        if (UIManager.subjectCode == null)
        {
            return;
        }

        if (UIManager.subjectCode.ToUpper().Contains("I"))        // "I" for "Initiation"
        {
            isInitiationRequired = true;
        }
        else if (UIManager.subjectCode.ToUpper().Contains("P"))   // "P" for "Passive"
        {
            isInitiationRequired = false;
        }
        if (UIManager.subjectCode.ToUpper().Contains("M"))        // "M" for "Mouse"
        {
            inputMode = InputMode.Mouse;
        }
        else if (UIManager.subjectCode.ToUpper().Contains("K"))   // "K" for "Keyboard"
        {
            inputMode = InputMode.Keyboard;
        }
        if (UIManager.subjectCode.ToUpper().Contains("SL"))       // "SL" for "Short Long", as in "Short" on the left; "Long" on the right
        {
            contingency = Contingency.LeftIsShortRightIsLong;
        }
        else if (UIManager.subjectCode.ToUpper().Contains("LS"))   // "LS" for "Long Short", as in "Short" on the right; "Long" on the left
        {
            contingency = Contingency.RightIsShortLeftIsLong;
        }
    }

    private void HandleCursorVisibility()
    {
        Cursor.visible = inputMode == InputMode.Mouse;
    }

    private void AssignButtonRoles()
    {
        _initiationButton = centralButton;
        _initiationButton.SetButtonRole(ButtonBhv.ButtonRole.Initiation);

        _shortButton = contingency == Contingency.LeftIsShortRightIsLong ? leftButton : rightButton;
        _shortButton.SetButtonRole(ButtonBhv.ButtonRole.Short);

        _longButton = contingency == Contingency.RightIsShortLeftIsLong ? leftButton : rightButton;
        _longButton.SetButtonRole(ButtonBhv.ButtonRole.Long);
    }

    private void Update()
    {
        if (!_ongoingTrial && Time.timeSinceLevelLoad > 1f)
        {
            StartCoroutine(this.TaskCoroutine());
        }
    }

    private IEnumerator TaskCoroutine()
    {
        _ongoingTrial = true;

        Debug.Log("Trial Available");

        stimulusPanel.DrawNextStimulus();

        trajectoryTracker.SyncPulse(new float[] { -100, -100, -100, -100, -100, Time.timeSinceLevelLoad });
        keyPressTracker.SyncPulse(-100);

        this.TrialCounter++;

        _initiationButton.IsActive = true;
        _shortButton.IsActive = true;
        _longButton.IsActive = true;

        //if (this.inputMode == InputMode.Keyboard)
        //{
            _initiationButton.ContactBegin();
            _shortButton.ContactBegin();
            _longButton.ContactBegin();
        //}

        while (!_initiationButton.IsPressed && (isInitiationRequired || this.TrialCounter == 1))
        {
            yield return null;
        }

        Debug.Log("Trial Initiation");

        float preStimulusDelay = stimulusPanel.CurrentStimulus.PreStimulusDelay;
        float stimulusOnsetTime = Time.timeSinceLevelLoad + preStimulusDelay;
        float stimulusDuration = stimulusPanel.CurrentStimulus.StimulusDuration;
        float stimulusOffsetTime = stimulusOnsetTime + stimulusDuration;
        float iti = stimulusPanel.CurrentStimulus.InterTrialInterval;

        trajectoryTracker.SyncPulse(new float[] { -200, -200, -200, -200, -200, Time.timeSinceLevelLoad });
        keyPressTracker.SyncPulse(-200);

        _initiationButton.IsActive = false;
        _initiationButton.ContactEnd();

        feedbackPanel.Wait();

        while (Time.timeSinceLevelLoad < stimulusOnsetTime)
        {
            if (_longButton.IsPressed || _shortButton.IsPressed || (!_initiationButton.IsPressed && isFixationRequired))
            {
                stimulusPanel.LightsOff();

                _shortButton.IsActive = false;
                _longButton.IsActive = false;
                _shortButton.ContactEnd();
                _longButton.ContactEnd();

                feedbackPanel.Abort();

                Debug.Log("Trial Aborted");

                _fileHandler.WriteBhvTrial(preStimulusDelay, stimulusDuration, -2, -2, -2, -2, -2, -2, stimulusPanel.GetImgName());
                _fileHandler.WriteTrackingTrial();
                _fileHandler.WriteKeyPressTrial();

                yield return new WaitForSeconds(_feedbackDisplayDuration);

                feedbackPanel.Neutral();

                yield return new WaitForSeconds(iti - _feedbackDisplayDuration);

                _ongoingTrial = stimulusPanel.Check4Quits();

                yield break;
            }
            yield return null;
        }
        Debug.Log("Stimulus Onset");

        trajectoryTracker.SyncPulse(new float[] { -250, -250, -250, -250, -250, Time.timeSinceLevelLoad });
        keyPressTracker.SyncPulse(-250);

        feedbackPanel.Neutral();
        stimulusPanel.LightsOn();

        //_initiationButton.LightsOff();
        //_shortButton.LightsOff();
        //_longButton.LightsOff();

        while (Time.timeSinceLevelLoad < stimulusOffsetTime)
        {
            if (_longButton.IsPressed || _shortButton.IsPressed || (!_initiationButton.IsPressed && isFixationRequired))
            {
                stimulusPanel.LightsOff();

                _shortButton.IsActive = false;
                _longButton.IsActive = false;
                _shortButton.ContactEnd();
                _longButton.ContactEnd();

                feedbackPanel.Abort();

                if (_abortedPreviousTrial)
                {
                    stimulusPanel.StimulusIndex++;
                }

                if (!_abortedPreviousTrial)
                {
                    _abortedPreviousTrial = true;
                }

                Debug.Log("Trial Aborted");

                _fileHandler.WriteBhvTrial(preStimulusDelay, stimulusDuration, -1, -1, -1, -1, -1, -1, stimulusPanel.GetImgName());
                _fileHandler.WriteTrackingTrial();
                _fileHandler.WriteKeyPressTrial();

                yield return new WaitForSeconds(_feedbackDisplayDuration);

                feedbackPanel.Neutral();

                yield return new WaitForSeconds(iti - _feedbackDisplayDuration);

                _ongoingTrial = stimulusPanel.Check4Quits();

                yield break;
            }
            yield return null;
        }

        Debug.Log("Stimulus Offset");

        float reactionTime = Time.timeSinceLevelLoad;

        _shortButton.IsActive = true;
        _longButton.IsActive = true;

        stimulusPanel.LightsOff();
        //_longButton.LightsOn();
        //_shortButton.LightsOn();

        while (_initiationButton.IsTouched)
        {
            yield return null;
        }
        trajectoryTracker.SyncPulse(new float[] { -300, -300, -300, -300, -300, Time.timeSinceLevelLoad });
        keyPressTracker.SyncPulse(-300);

        Debug.Log("Reaction");

        reactionTime = Time.timeSinceLevelLoad - reactionTime;

        float movementTime = Time.timeSinceLevelLoad;

        while (!_longButton.IsPressed && !_shortButton.IsPressed)
        {
            yield return null;
        }

        Debug.Log("Choice");

        trajectoryTracker.SyncPulse(new float[] { -400, -400, -400, -400, -400, Time.timeSinceLevelLoad });
        keyPressTracker.SyncPulse(-400);

        _shortButton.IsActive = false;
        _longButton.IsActive = false;
        _shortButton.ContactEnd();
        _longButton.ContactEnd();

        movementTime = Time.timeSinceLevelLoad - movementTime;

        int choiceLeft;
        int choiceLong;
        int choiceCorrect;

        if (stimulusDuration == categoryBoundary)
        {
            int die = Random.Range(0, 2);
            if (die == 0)
            {
                choiceLong = _longButton.IsPressed ? 1 : 0;
                choiceCorrect = 0;
                feedbackPanel.Negative();
            }
            else
            {
                choiceLong = _longButton.IsPressed ? 1 : 0;
                choiceCorrect = 1;
                feedbackPanel.Positive();
            }
        }

        else if (_longButton.IsPressed && stimulusDuration < categoryBoundary ||
                 _shortButton.IsPressed && stimulusDuration > categoryBoundary)
        {
            choiceLong = _longButton.IsPressed ? 1 : 0;
            choiceCorrect = 0;
            feedbackPanel.Negative();
        }

        else
        {
            choiceLong = _longButton.IsPressed ? 1 : 0;
            choiceCorrect = 1;
            feedbackPanel.Positive();
        }

        choiceLeft = contingency == Contingency.RightIsShortLeftIsLong ? choiceLong : 1 - choiceLong;

        //_initiationButton.LightsOff();
        //_longButton.LightsOff();
        //_shortButton.LightsOff();

        _fileHandler.WriteBhvTrial(preStimulusDelay, stimulusDuration, reactionTime, movementTime, choiceLeft, choiceLong, choiceCorrect, stimulusPanel.CurrentStimulus.InterTrialInterval, stimulusPanel.GetImgName());
        _fileHandler.WriteTrackingTrial();
        _fileHandler.WriteKeyPressTrial();

        this.ValidTrialCounter++;

        stimulusPanel.StimulusIndex++;

        _abortedPreviousTrial = false;

        yield return new WaitForSeconds(_feedbackDisplayDuration);

        feedbackPanel.Neutral();

        yield return new WaitForSeconds(iti - _feedbackDisplayDuration);

        _ongoingTrial = stimulusPanel.Check4Quits();
    }
}
