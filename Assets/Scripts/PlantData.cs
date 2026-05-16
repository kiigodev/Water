using UnityEngine;

[CreateAssetMenu(fileName = "NewPlant", menuName = "Farming/PlantData")]
public class PlantData : ScriptableObject
{
    public GameObject plantPrefab;
    public float timeToFullyGrow = 60f; 
    public float timeToSpoil = 30f; 
}