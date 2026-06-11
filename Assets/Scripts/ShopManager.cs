using UnityEngine;
using TMPro;
using System.Collections;

public class ShopManager : MonoBehaviour
{
    public static ShopManager Instance;

    [Header("Shop Panels")]
    public GameObject buyShopPanel;  // Drag your Buy UI here
    public GameObject sellShopPanel; // Drag your Sell UI here

    [Header("Buy Prices & Amounts")]
    public int seedAPrice = 10;
    public int seedAAmount = 1;
    public int seedBPrice = 20;
    public int seedBAmount = 1;

    [Header("Sell Prices & Amounts")]
    public int plantASellPrice = 15;
    public int plantASellAmount = 1;
    public int plantBSellPrice = 25;
    public int plantBSellAmount = 1;

    [Header("Feedback Popups")]
    public GameObject feedbackPanel;
    public TextMeshProUGUI feedbackText;
    public string successMsgBuyA = "Bought Seed A!";
    public string successMsgBuyB = "Bought Seed B!";
    public string failMsgBuy = "Not enough coins, bro!";
    
    public string successMsgSellA = "Sold Farmed Plant A!";
    public string successMsgSellB = "Sold Farmed Plant B!";
    public string failMsgSell = "You don't have enough plants, bro!";
    
    public float popupTimer = 1.5f;

    private SimpleThirdPerson playerScript;
    private ThirdPersonCamera camScript; 

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        playerScript = FindObjectOfType<SimpleThirdPerson>();
        
        if (Camera.main != null) 
            camScript = Camera.main.GetComponent<ThirdPersonCamera>(); 
            
        if (buyShopPanel) buyShopPanel.SetActive(false);
        if (sellShopPanel) sellShopPanel.SetActive(false);
        if (feedbackPanel) feedbackPanel.SetActive(false);
    }

    // ================= BUY SHOP =================
    public void OpenBuyShop()
    {
        buyShopPanel.SetActive(true);
        LockPlayer();
    }

    public void CloseBuyShop()
    {
        buyShopPanel.SetActive(false);
        if (feedbackPanel) feedbackPanel.SetActive(false);
        UnlockPlayer();
    }

    public void BuySeedA()
    {
        AttemptPurchase(seedAPrice, HeldItem.SeedA, seedAAmount, successMsgBuyA);
    }

    public void BuySeedB()
    {
        AttemptPurchase(seedBPrice, HeldItem.SeedB, seedBAmount, successMsgBuyB);
    }

    void AttemptPurchase(int price, HeldItem item, int amount, string successMsg)
    {
        if (CoinManager.Instance.currentCoins >= price)
        {
            CoinManager.Instance.SpendCoins(price);
            InventoryManager.Instance.AddItem(item, amount);
            ShowFeedback($"{successMsg} (-{price} Coins)");
        }
        else
        {
            ShowFeedback(failMsgBuy);
        }
    }

    // ================= SELL SHOP =================
    public void OpenSellShop()
    {
        sellShopPanel.SetActive(true);
        LockPlayer();
    }

    public void CloseSellShop()
    {
        sellShopPanel.SetActive(false);
        if (feedbackPanel) feedbackPanel.SetActive(false);
        UnlockPlayer();
    }

    public void SellPlantA()
    {
        AttemptSell(plantASellPrice, HeldItem.FarmedPlantA, plantASellAmount, successMsgSellA);
    }

    public void SellPlantB()
    {
        AttemptSell(plantBSellPrice, HeldItem.FarmedPlantB, plantBSellAmount, successMsgSellB);
    }

    void AttemptSell(int price, HeldItem item, int amount, string successMsg)
    {
        // Check if player actually has the plants in their inventory!
        if (InventoryManager.Instance.inventory[item] >= amount)
        {
            // Take the plant away
            InventoryManager.Instance.inventory[item] -= amount;
            InventoryManager.Instance.UpdateUI();

            // Give them the cash!
            CoinManager.Instance.AddCoins(price);
            ShowFeedback($"{successMsg} (+{price} Coins)");
        }
        else
        {
            ShowFeedback(failMsgSell);
        }
    }

    // ================= HELPER METHODS =================
    void LockPlayer()
    {
        if (playerScript) playerScript.SetFreeze(true);
        if (camScript) camScript.enabled = false; 
        
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
        
        InventoryManager.Instance.ToggleVisibility(false);
    }

    void UnlockPlayer()
    {
        if (playerScript) playerScript.SetFreeze(false);
        if (camScript) camScript.enabled = true; 
        
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
        
        InventoryManager.Instance.ToggleVisibility(true);
    }

    void ShowFeedback(string message)
    {
        if (feedbackPanel && feedbackText)
        {
            StopAllCoroutines(); 
            feedbackText.text = message;
            feedbackPanel.SetActive(true);
            StartCoroutine(HideFeedbackRoutine());
        }
    }

    IEnumerator HideFeedbackRoutine()
    {
        yield return new WaitForSeconds(popupTimer);
        if (feedbackPanel) feedbackPanel.SetActive(false);
    }
}