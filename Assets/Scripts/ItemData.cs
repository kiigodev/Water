using UnityEngine;

[CreateAssetMenu(fileName = "New Item", menuName = "Inventory/Item")]
public class ItemData : ScriptableObject
{
    public string itemID; // Your special ID! e.g., "tool_shovel"
    public string itemName;
    public Sprite icon; // The image for the UI slot
    public GameObject handPrefab; // The 3D model when held
}