using UnityEngine;

public class ObjectiveMarker : MonoBehaviour
{
    [Header("Visuals")]
    public GameObject minimapIcon; 
    public GameObject inGameMarker; 

    void Start()
    {
        if (minimapIcon != null) minimapIcon.SetActive(false);
        if (inGameMarker != null) inGameMarker.SetActive(false);
    }

    public void ActivateObjective()
    {
        if (minimapIcon != null) minimapIcon.SetActive(true);
        if (inGameMarker != null) inGameMarker.SetActive(true);
    }

    // Hides the markers when the player touches the trigger
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            if (minimapIcon != null) minimapIcon.SetActive(false);
            if (inGameMarker != null) inGameMarker.SetActive(false);
            
            Destroy(gameObject);
        }
    }
}