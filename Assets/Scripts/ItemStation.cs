using UnityEngine;

public class ItemStation : MonoBehaviour
{
    [Header("What does this station give?")]
    public HeldItem itemGiven; //[cite: 1]
    public int amount = 1; 

    [Header("UI Hover Settings")]
    public string customName = ""; 

    [Header("Pickup Settings")]
    [Tooltip("If true, the station disappears after you pick up the item.")]
    public bool destroyOnPickup = false; 

    public string GetDisplayName()
    {
        return string.IsNullOrEmpty(customName) ? itemGiven.ToString() : customName;
    }

    // This handles adding the item and the destruction logic
    public void Pickup()
    {
        // Tell the inventory to add the items
        InventoryManager.Instance.AddItem(itemGiven, amount);
        
        Debug.Log($"[STATION] {GetDisplayName()} collected. Destroy on pickup: {destroyOnPickup}");

        if (destroyOnPickup)
        {
            Destroy(gameObject); // Self-destruct for realism!
        }
    }
}