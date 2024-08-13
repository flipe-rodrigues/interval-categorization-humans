using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;
using System.IO;

public class PostBuildProcessor : IPostprocessBuildWithReport
{
    // The order in which this postprocessor is called. Lower numbers are called earlier.
    public int callbackOrder { get { return 0; } }

    public void OnPostprocessBuild(BuildReport report)
    {
        if (report.summary.platform == BuildTarget.StandaloneWindows || report.summary.platform == BuildTarget.StandaloneWindows64)
        {
            CreateCustomFolders(report.summary.outputPath);
        }
    }

    private void CreateCustomFolders(string buildPath)
    {
        string rootPath = Path.GetDirectoryName(buildPath);

        // Define your custom folders
        string[] foldersToCreate = new string[]
        {
            Application.productName + "_Data/Data",
            Application.productName + "_Data/Data/Behavior",
            Application.productName + "_Data/Data/Trajectories",
        };

        foreach (var folder in foldersToCreate)
        {
            string folderPath = Path.Combine(rootPath, folder);
            if (!Directory.Exists(folderPath))
            {
                Directory.CreateDirectory(folderPath);
            }
        }
    }
}