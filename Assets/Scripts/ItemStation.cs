using UnityEngine;

// Global enum so all scripts know what items exist!
public enum HeldItem { None, Water, Fertilizer, Pesticide }

public class ItemStation : MonoBehaviour
{
    [Header("What does this station give?")]
    public HeldItem itemGiven;
}