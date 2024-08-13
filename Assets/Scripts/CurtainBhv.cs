using UnityEngine;
using System.Collections;

public class CurtainBhv : MonoBehaviour {

    public float targetX;

    private Transform _transform;
    private Cloth _cloth;

	// Use this for initialization
	void Awake ()
    {
        _transform = this.GetComponent<Transform>();
        _cloth = this.GetComponent<Cloth>();
	}
	
	// Update is called once per frame
	void Update ()
    {
        //_transform.Translate(Vector3.left * Time.deltaTime);
        
	}
}
