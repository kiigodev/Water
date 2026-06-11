using UnityEngine;

public class ObjectiveHandler : MonoBehaviour
{
    [Header("Objective Requirements")]
    public string questDescription = "Collect 5 Farmed Plants"; // Type this in Inspector!
    public HeldItem requiredItem;
    public int requiredAmount = 1;
    
    [Header("Rewards")]
    public int coinReward = 50;

    [Header("Objective Dialogues")]
    public DialogueSequence inProgressDialogue; 
    public DialogueSequence successDialogue;    
    public DialogueSequence completedDialogue;  

    [Header("Dependencies")]
    public DialogueTrigger originalTrigger; 
    public Transform cameraSocket; 

    private bool isObjectiveActive = false;
    private bool isCompleted = false;
    private bool playerInRange = false;

    public void ActivateObjective()
    {
        if (originalTrigger) originalTrigger.enabled = false; 
        isObjectiveActive = true;
        
        // POPUP THE NEW UI!
        QuestUIManager.Instance.StartQuest(questDescription);
    }

    void Update()
    {
        if (playerInRange && Input.GetKeyDown(KeyCode.E) && !DialogueManager.instance.dialogueCanvas.activeSelf)
        {
            if (isCompleted)
            {
                DialogueManager.instance.StartDialogue(completedDialogue, cameraSocket); 
                return;
            }

            if (isObjectiveActive)
            {
                CheckObjective();
            }
        }
    }

    void CheckObjective()
    {
        int playerAmount = InventoryManager.Instance.inventory[requiredItem];
        
        if (playerAmount >= requiredAmount)
        {
            InventoryManager.Instance.inventory[requiredItem] -= requiredAmount;
            InventoryManager.Instance.UpdateUI();
            
            DialogueManager.instance.StartDialogue(successDialogue, cameraSocket);
            CoinManager.Instance.AddCoins(coinReward);
            
            isObjectiveActive = false;
            isCompleted = true;

            // CLEAR THE UI AND SHOW SUCCESS POPUP!
            QuestUIManager.Instance.CompleteQuest();
        }
        else
        {
            DialogueManager.instance.StartDialogue(inProgressDialogue, cameraSocket); 
        }
    }

    void OnTriggerEnter(Collider other) { if (other.CompareTag("Player")) playerInRange = true; }
    void OnTriggerExit(Collider other) { if (other.CompareTag("Player")) playerInRange = false; }
}