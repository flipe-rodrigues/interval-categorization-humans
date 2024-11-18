using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.Linq;
using UnityEngine.SceneManagement;
using System.IO;

public class StimulusPanelBhv : MonoBehaviour
{
    public int StimulusIndex { get { return _stimulusIndex; } set { _stimulusIndex = value; } }
    public Stimulus CurrentStimulus { get { return _currentStimulus; } }
    private Color EmissionColor
    {
        get { return _renderer.material.GetColor("_EmissionColor"); }
        set { _renderer.material.SetColor("_EmissionColor", value); }
    }

    public TextAsset testImageSequence;
    public bool debugging = false;

    private Transform _transform;
    private Renderer _renderer;
    [SerializeField] private int _stimulusIndex = 0;
    [SerializeField] private Stimulus _currentStimulus;
    [SerializeField] private List<Stimulus> _allStimuli;

    void Awake()
    {
        _transform = this.GetComponent<Transform>();
        _renderer = this.GetComponent<Renderer>();
    }

    void Start()
    {
        this.LoadAllStimuli();
    }

    private void LoadAllStimuli()
    {
        // Load all CSV file names from the specified directory in the Resources folder
        TextAsset[] csvFiles = Resources.LoadAll<TextAsset>("Image Sequences");
        if (csvFiles.Length == 0)
        {
            Debug.LogError("No CSV files found in the specified directory.");
            return;
        }

        // Select a random CSV file
        TextAsset csvFile = csvFiles[Random.Range(0, csvFiles.Length)];
        if (debugging)
        {
            csvFile = testImageSequence;
        }

        // Read the CSV file contents
        StringReader reader = new StringReader(csvFile.text);
        List<Dictionary<string, string>> csvData = new List<Dictionary<string, string>>();

        // Read the header line
        string headerLine = reader.ReadLine();
        if (headerLine == null)
        {
            Debug.LogError("CSV file is empty.");
            return;
        }
        string[] headers = headerLine.Split(',');

        // Read the rest of the lines
        string line;
        while ((line = reader.ReadLine()) != null)
        {
            string[] fields = line.Split(',');
            Dictionary<string, string> entry = new Dictionary<string, string>();
            for (int i = 0; i < headers.Length; i++)
            {
                string header = headers[i].Replace("\"", "");
                string field = fields[i].Replace("\"", "");
                entry[header] = field;
            }
            csvData.Add(entry);
        }

        // Populate stimulus list
        _allStimuli = new List<Stimulus>();
        foreach (var entry in csvData)
        {
            string imagePath = Path.Combine("GAPED", Regex.Replace(entry["file_name"], Regex.Escape(".png"), "", RegexOptions.IgnoreCase));
            Texture2D image = Resources.Load<Texture2D>(imagePath);
            float duration = float.Parse(entry["duration"]) / 1e3f;
            float interTrialInterval = float.Parse(entry["iti"]) / 1e3f;
            Phase phase = int.Parse(entry["phase"]) == 3 ? Phase.Test : Phase.Train;
            Stimulus stimulus = new Stimulus(image, duration, interTrialInterval, phase);
            _allStimuli.Add(stimulus);
        }
    }

    public void DrawNextStimulus()
    {
        _currentStimulus = _allStimuli[_stimulusIndex];
        _renderer.material.SetTexture("_MainTex", _currentStimulus.Image);
        _renderer.material.SetTexture("_EmissionMap", _currentStimulus.Image);
        _transform.localScale = new Vector3(_currentStimulus.Image.width / (float)_currentStimulus.Image.height, 1, 1);
    }

    public void RemovePreviousStimulus()
    {
        _allStimuli.Remove(_currentStimulus);
    }

    public void LightsOn()
    {
        this.EmissionColor = Color.white * 0.85f;
    }

    public void LightsOff()
    {
        this.EmissionColor = Color.clear;
    }

    public string GetImgName()
    {
        return _currentStimulus.Image.name;
    }

    public bool Check4Quits()
    {
        if (_stimulusIndex == _allStimuli.Count) //(_allStimuli.Count == 0)
        {
            StartCoroutine(this.ByeBye());

            return true;
        }
        else
        {
            return false;
        }
    }

    private IEnumerator ByeBye()
    {
        Texture2D byebye = Resources.Load("byebye") as Texture2D;

        _renderer.material.SetTexture("_MainTex", byebye);
        _renderer.material.SetTexture("_EmissionMap", byebye);

        this.LightsOn();

        yield return new WaitForSeconds(10);

        SceneManager.LoadScene("Setup");
    }
}
