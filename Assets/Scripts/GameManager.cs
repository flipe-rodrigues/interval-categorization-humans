using UnityEngine;
using UnityEngine.SceneManagement;

public class GameManager : Singleton<GameManager> 
{
	void Update ()
    {
	    if (Input.GetKeyDown(KeyCode.Escape) && Input.GetKey(KeyCode.LeftShift))
        {
            Application.Quit();
        }

        if (Input.GetKeyDown(KeyCode.Escape) && !Input.GetKey(KeyCode.LeftShift))
        {
            SceneManager.LoadScene("Setup");
        }
    }
}
