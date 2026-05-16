using UnityEngine;

public class Billboard : MonoBehaviour
{
    void LateUpdate()
    {
        // Makes the Canvas match the exact direction the camera is looking!
        transform.LookAt(transform.position + Camera.main.transform.forward);
    }
}