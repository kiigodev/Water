using System.Collections;
using UnityEngine;

public class EasterEggPickup : MonoBehaviour
{
    [Header("UI Setting")]
    public GameObject easterEggPanel;
    [SerializeField] private float autoCloseTime = 2f; 

    private bool isPlayerNearby = false;
    private bool alreadyPickedUp = false;

    void Update()
    {
        if (isPlayerNearby && !alreadyPickedUp && Input.GetKeyDown(KeyCode.E))
        {
            alreadyPickedUp = true; 

            if (easterEggPanel != null)
            {
                easterEggPanel.SetActive(true);
            }
            
            MeshRenderer[] childMeshes = GetComponentsInChildren<MeshRenderer>();
            foreach(MeshRenderer mesh in childMeshes)
            {
                mesh.enabled = false;
            }

            if (GetComponent<Collider>() != null) GetComponent<Collider>().enabled = false;

            StartCoroutine(ClosePanelRoutine());
        }
    }

    IEnumerator ClosePanelRoutine()
    {
        yield return new WaitForSeconds(autoCloseTime); 

        if (easterEggPanel != null)
        {
            easterEggPanel.SetActive(false);
        }
        
        gameObject.SetActive(false); 
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player")) isPlayerNearby = true;
    }

    void OnTriggerExit(Collider other)
    {
        if (other.CompareTag("Player")) isPlayerNearby = false;
    }
}