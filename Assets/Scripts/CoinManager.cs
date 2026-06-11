using UnityEngine;
using TMPro;

public class CoinManager : MonoBehaviour
{
    public static CoinManager Instance;

    [Header("Player Wallet")]
    public int startingCoins = 50; // <-- Set this in inspector!
    public int currentCoins = 0;
    
    [Header("UI Setup")]
    public TextMeshProUGUI coinText;

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        currentCoins = startingCoins; // Give them the starting cash!
        UpdateCoinUI();
    }

    public void AddCoins(int amount)
    {
        currentCoins += amount;
        UpdateCoinUI();
        Debug.Log($"[ECONOMY] Earned {amount} coins! Total: {currentCoins}");
    }

    public void SpendCoins(int amount)
    {
        if (currentCoins >= amount)
        {
            currentCoins -= amount;
            UpdateCoinUI();
        }
    }

    void UpdateCoinUI()
    {
        if (coinText != null) coinText.text = currentCoins.ToString();
    }
}