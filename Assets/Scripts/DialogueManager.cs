using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;

public class DialogueManager : MonoBehaviour
{
    public static DialogueManager instance;

    [Header("UI Elements")]
    public GameObject dialogueCanvas;
    public TextMeshProUGUI speakerNameText;
    public TextMeshProUGUI dialogueBodyText;
    
    [Header("Choices UI")]
    public GameObject optionsPanel;
    public Button option1Button;
    public TextMeshProUGUI option1Text;
    public Button option2Button;
    public TextMeshProUGUI option2Text;

    [Header("Settings")]
    public float typeSpeed = 0.02f;

    private DialogueSequence currentSequence;
    private int currentLineIndex = 0;
    private bool isTyping = false;
    private Coroutine typingCoroutine;
    
    private SimpleThirdPerson playerScript;
    private ThirdPersonCamera camScript; 

    void Awake()
    {
        if (instance == null) instance = this;
        else Destroy(gameObject);
    }

    void Start()
    {
        playerScript = FindObjectOfType<SimpleThirdPerson>();
        camScript = Camera.main.GetComponent<ThirdPersonCamera>();
        
        dialogueCanvas.SetActive(false);
        optionsPanel.SetActive(false);
    }

    public void StartDialogue(DialogueSequence sequence, Transform cameraSocket = null)
    {
        playerScript.SetFreeze(true); 
        if (camScript) camScript.SetDialogueCamera(true, cameraSocket);
        
        currentSequence = sequence;
        currentLineIndex = 0;
        dialogueCanvas.SetActive(true);
        optionsPanel.SetActive(false);
        InventoryManager.Instance.ToggleVisibility(false);
        
        DisplayNextLine();
    }

    public void OnScreenClicked()
    {
        if (optionsPanel.activeSelf) return; 

        if (isTyping)
        {
            StopCoroutine(typingCoroutine);
            dialogueBodyText.text = currentSequence.lines[currentLineIndex].text;
            isTyping = false;
        }
        else
        {
            currentLineIndex++;
            DisplayNextLine();
        }
    }

    void DisplayNextLine()
    {
        if (currentLineIndex < currentSequence.lines.Count)
        {
            DialogueLine line = currentSequence.lines[currentLineIndex];
            speakerNameText.text = line.speakerName;
            
            if (typingCoroutine != null) StopCoroutine(typingCoroutine);
            typingCoroutine = StartCoroutine(TypeSentence(line.text));
        }
        else
        {
            if (currentSequence.hasChoices) ShowOptions();
            else EndDialogue();
        }
    }

    IEnumerator TypeSentence(string sentence)
    {
        isTyping = true;
        dialogueBodyText.text = "";
        foreach (char letter in sentence.ToCharArray())
        {
            dialogueBodyText.text += letter;
            yield return new WaitForSeconds(typeSpeed);
        }
        isTyping = false;
    }

    void ShowOptions()
    {
        optionsPanel.SetActive(true);
        
        option1Text.text = currentSequence.option1.choiceText;
        option1Button.onClick.RemoveAllListeners();
        option1Button.onClick.AddListener(() => SelectOption(currentSequence.option1.followUpSequence));

        option2Text.text = currentSequence.option2.choiceText;
        option2Button.onClick.RemoveAllListeners();
        option2Button.onClick.AddListener(() => SelectOption(currentSequence.option2.followUpSequence));
    }

    void SelectOption(DialogueSequence followUp)
    {
        optionsPanel.SetActive(false);
        if (followUp != null && followUp.lines.Count > 0) StartDialogue(followUp);
        else EndDialogue();
    }

    public void EndDialogue()
    {
        dialogueCanvas.SetActive(false);
        playerScript.SetFreeze(false); 
        if (camScript) camScript.SetDialogueCamera(false); 
        InventoryManager.Instance.ToggleVisibility(true);
        
        if (currentSequence.onSequenceEnd != null) currentSequence.onSequenceEnd.Invoke();
    }
}