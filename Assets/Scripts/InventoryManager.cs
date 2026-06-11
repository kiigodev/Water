using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;
using System.Collections;

public class InventoryManager : MonoBehaviour
{
    public static InventoryManager Instance;

    [Header("UI Slots (Order: Shovel, Water, Fert, Pest, SeedA, SeedB, PlantA, PlantB, None)")]
    public Image[] slotImages = new Image[9]; // Bumped up to 9!
    public TextMeshProUGUI[] stackTexts = new TextMeshProUGUI[9]; 
    public Color equippedColor = Color.green;
    public Color unequippedColor = Color.white;

    [Header("Main UI Parent")]
    [Tooltip("Drag the parent GameObject that holds all 9 slots here!")]
    public GameObject mainInventoryCanvas; 

    public void ToggleVisibility(bool isVisible)
    {
        if (mainInventoryCanvas) mainInventoryCanvas.SetActive(isVisible);
    }

    [Header("Hover & Popup Panels")]
    public GameObject hoverPanel; 
    public TextMeshProUGUI hoverText;
    public GameObject popupPanel; 
    public TextMeshProUGUI popupText;
    public float popupDisplayTime = 2.0f;

    [Header("Hand Meshes")]
    public GameObject shovelMesh;
    public GameObject waterMesh;

    public HeldItem currentItem = HeldItem.None;
    
    // Updated Dictionary with the new items!
    public Dictionary<HeldItem, int> inventory = new Dictionary<HeldItem, int>()
    {
        { HeldItem.Shovel, 0 }, { HeldItem.Water, 0 }, { HeldItem.Fertilizer, 0 },
        { HeldItem.Pesticide, 0 }, { HeldItem.SeedA, 0 }, { HeldItem.SeedB, 0 }, 
        { HeldItem.FarmedPlantA, 0 }, { HeldItem.FarmedPlantB, 0 }, { HeldItem.None, 1 }
    };

    void Awake() { Instance = this; }

    void Start() { UpdateUI(); }

    void Update()
    {
        // Added the new keybinds for slots 8 and 9!
        if (Input.GetKeyDown(KeyCode.Alpha1)) Equip(HeldItem.Shovel);
        if (Input.GetKeyDown(KeyCode.Alpha2)) Equip(HeldItem.Water);
        if (Input.GetKeyDown(KeyCode.Alpha3)) Equip(HeldItem.Fertilizer);
        if (Input.GetKeyDown(KeyCode.Alpha4)) Equip(HeldItem.Pesticide);
        if (Input.GetKeyDown(KeyCode.Alpha5)) Equip(HeldItem.SeedA);
        if (Input.GetKeyDown(KeyCode.Alpha6)) Equip(HeldItem.SeedB);
        if (Input.GetKeyDown(KeyCode.Alpha7)) Equip(HeldItem.FarmedPlantA);
        if (Input.GetKeyDown(KeyCode.Alpha8)) Equip(HeldItem.FarmedPlantB);
        if (Input.GetKeyDown(KeyCode.Alpha9)) Equip(HeldItem.None);
    }

    public void AddItem(HeldItem item, int amount)
    {
        if (item == HeldItem.Shovel || item == HeldItem.Water) inventory[item] = 1;
        else inventory[item] += amount;

        ShowPopup($"Obtained {amount}x {item}!");
        UpdateUI();
    }

    public void ConsumeItem()
    {
        if (currentItem != HeldItem.Shovel && currentItem != HeldItem.Water && currentItem != HeldItem.None)
        {
            inventory[currentItem]--;
            if (inventory[currentItem] <= 0)
            {
                inventory[currentItem] = 0;
                Equip(HeldItem.None);
            }
            UpdateUI();
        }
    }

    void Equip(HeldItem item)
    {
        if (inventory[item] > 0 || item == HeldItem.None)
        {
            currentItem = item;
            if(shovelMesh) shovelMesh.SetActive(item == HeldItem.Shovel);
            if(waterMesh) waterMesh.SetActive(item == HeldItem.Water);
            UpdateUI();
        }
    }

    public void UpdateUI()
    {
        // Added the new items to the UI update loop
        HeldItem[] order = { HeldItem.Shovel, HeldItem.Water, HeldItem.Fertilizer, HeldItem.Pesticide, HeldItem.SeedA, HeldItem.SeedB, HeldItem.FarmedPlantA, HeldItem.FarmedPlantB, HeldItem.None };
        for (int i = 0; i < order.Length; i++)
        {
            if (slotImages[i]) slotImages[i].color = (currentItem == order[i]) ? equippedColor : unequippedColor;
            if (stackTexts[i])
            {
                int count = inventory[order[i]];
                stackTexts[i].text = (count > 0 && order[i] != HeldItem.None) ? count.ToString() : "";
            }
        }
    }

    public void SetHover(bool active, string msg = "")
    {
        if (hoverPanel) hoverPanel.SetActive(active);
        if (hoverText) hoverText.text = msg;
    }

    public void ShowPopup(string msg)
    {
        if (popupPanel)
        {
            popupPanel.SetActive(true);
            popupText.text = msg;
            StopAllCoroutines();
            StartCoroutine(HidePopup());
        }
    }

    IEnumerator HidePopup() { yield return new WaitForSeconds(popupDisplayTime); popupPanel.SetActive(false); }
}