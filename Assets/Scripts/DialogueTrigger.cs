using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

[System.Serializable]
public class DialogueLine
{
    public string speakerName; 
    [TextArea(2, 5)] public string text;
}

[System.Serializable]
public class DialogueChoice
{
    public string choiceText;
    public DialogueSequence followUpSequence;
}

[System.Serializable]
public class DialogueSequence
{
    public List<DialogueLine> lines;
    
    public bool hasChoices;
    public DialogueChoice option1;
    public DialogueChoice option2;

    public UnityEvent onSequenceEnd; 
}

public class DialogueTrigger : MonoBehaviour
{
    [Header("Main Conversation")]
    public DialogueSequence mainDialogue;
    
    [Header("Camera Magic")]
    public Transform cameraSocket; 
    
    private bool playerInRange = false;

    void Update()
    {
        if (playerInRange && Input.GetKeyDown(KeyCode.E) && !DialogueManager.instance.dialogueCanvas.activeSelf)
        {
            DialogueManager.instance.StartDialogue(mainDialogue, cameraSocket);
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player")) playerInRange = true;
    }

    void OnTriggerExit(Collider other)
    {
        if (other.CompareTag("Player")) playerInRange = false;
    }
}