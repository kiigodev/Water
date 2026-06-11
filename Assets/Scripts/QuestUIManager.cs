using UnityEngine;
using TMPro;
using System.Collections;

public class QuestUIManager : MonoBehaviour
{
    public static QuestUIManager Instance;

    [Header("Popup UI (Fades away)")]
    public GameObject popupPanel;
    public TextMeshProUGUI popupText;
    public float popupDuration = 3f;

    [Header("Persistent UI (Stays on screen)")]
    public GameObject persistentPanel;
    public TextMeshProUGUI persistentText;

    void Awake() { Instance = this; }

    void Start()
    {
        if(popupPanel) popupPanel.SetActive(false);
        if(persistentPanel) persistentPanel.SetActive(false);
    }

    public void StartQuest(string description)
    {
        // Turn on the sticky objective text
        if (persistentPanel) persistentPanel.SetActive(true);
        if (persistentText) persistentText.text = "Objective: " + description;

        // Flash the "New Objective!" popup
        ShowPopup("New Objective!");
    }

    public void CompleteQuest()
    {
        // Turn off the sticky text
        if (persistentPanel) persistentPanel.SetActive(false);
        
        // Flash the completion popup!
        ShowPopup("Objective Complete!");
    }

    void ShowPopup(string message)
    {
        if (popupPanel)
        {
            popupPanel.SetActive(true);
            if (popupText) popupText.text = message;
            StopAllCoroutines();
            StartCoroutine(HidePopupTimer());
        }
    }

    IEnumerator HidePopupTimer()
    {
        yield return new WaitForSeconds(popupDuration);
        if (popupPanel) popupPanel.SetActive(false);
    }
}