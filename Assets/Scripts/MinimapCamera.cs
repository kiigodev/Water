using UnityEngine;

public class MinimapCamera : MonoBehaviour
{
    public Transform player;
    public float mapHeight = 20f;

    void LateUpdate()
    {
        Vector3 newPosition = player.position;
        newPosition.y = mapHeight;
        transform.position = newPosition;
        
        // If want map rotate
        // transform.rotation = Quaternion.Euler(90f, player.eulerAngles.y, 0f);
    }
}