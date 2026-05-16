using UnityEngine;

public class Land : MonoBehaviour
{
    public Material soilMat, farmMat, wateredMat;
    public enum LandStatus { Soil, Farm, Watered }
    
    [Header("Set this in the Inspector!")]
    public LandStatus landStatus; 
    
    new Renderer renderer;
    public GameObject select;

    [Header("UI System")]
    public GameObject plantUICanvas; 
    public PlantUI uiScript;

    [Header("Plant Info")]
    public PlantData currentPlantData; 
    private PlantVisuals currentVisuals; 
    private GameObject activePlantObject; 

    [Header("Placement")]
    public Transform plantSocket; 

    public float currentGrowth = 0f;    
    
    private bool isPlanted = false;
    private bool isDead = false;
    private bool isReadyToHarvest = false;
    private bool isWithered = false;

    [Header("Plant Needs")]
    public float idealWater = 0.5f;
    public float idealFertilizer = 0.5f;
    public float idealPesticide = 0.5f;

    [Header("Current Levels")]
    [Range(0f, 1f)] public float currentWater = 0.5f;
    [Range(0f, 1f)] public float currentFertilizer = 0.5f;
    [Range(0f, 1f)] public float currentPesticide = 0.5f;

    [Header("Drain Rates")]
    public float waterDrain = 0.02f; 
    public float fertDrain = 0.01f;
    public float pestDrain = 0.015f;

    [Header("Item Boosts")]
    public float waterBoost = 0.4f;
    public float fertBoost = 0.4f;
    public float pestBoost = 0.4f;

    void Start()
    {
        renderer = GetComponent<Renderer>();
        SwitchLand(landStatus); 
        Select(false);
    }

    void Update()
    {
        if (isPlanted && !isDead && !isWithered)
        {
            if (!isReadyToHarvest)
            {
                DrainStats();
                CalculateGrowth();
                
                if (!isReadyToHarvest && !isDead)
                {
                    UpdateGrowingMesh(); 
                }
            }
            else
            {
                HarvestTimeout(); 
            }
        }
        UpdateUI();
    }

    void DrainStats()
    {
        currentWater -= waterDrain * Time.deltaTime;
        currentFertilizer -= fertDrain * Time.deltaTime;
        currentPesticide -= pestDrain * Time.deltaTime;

        currentWater = Mathf.Clamp01(currentWater);
        currentFertilizer = Mathf.Clamp01(currentFertilizer);
        currentPesticide = Mathf.Clamp01(currentPesticide);
    }

    void CalculateGrowth()
    {
        float waterDiff = Mathf.Abs(idealWater - currentWater);
        float fertDiff = Mathf.Abs(idealFertilizer - currentFertilizer);
        float pestDiff = Mathf.Abs(idealPesticide - currentPesticide);

        float worstDiff = Mathf.Max(waterDiff, Mathf.Max(fertDiff, pestDiff));
        float currentGrowthRate = 1f;

        if (worstDiff <= 0.15f) currentGrowthRate = 1f;      
        else if (worstDiff <= 0.35f) currentGrowthRate = 0.5f;    
        else currentGrowthRate = -1f;    

        currentGrowth += currentGrowthRate * (100f / currentPlantData.timeToFullyGrow) * Time.deltaTime;

        if (currentGrowth >= 100f)
        {
            currentGrowth = 100f;
            isReadyToHarvest = true;
            if (currentVisuals)
            {
                currentVisuals.HideAllPlants();
                if (currentVisuals.readyToHarvestMesh) currentVisuals.readyToHarvestMesh.SetActive(true);
            }
        }
        else if (currentGrowth <= 0f) 
        {
            currentGrowth = 0f;
            isDead = true;
            if (currentVisuals)
            {
                currentVisuals.HideAllPlants();
                if (currentVisuals.deadMesh) currentVisuals.deadMesh.SetActive(true);
            }
        }
    }

    void UpdateGrowingMesh()
    {
        if (currentVisuals == null) return;
        
        currentVisuals.HideAllPlants();

        if (currentWater > 0.8f) {
            if (currentVisuals.tooMuchWaterMesh) currentVisuals.tooMuchWaterMesh.SetActive(true);
            SwitchLand(LandStatus.Watered);
        } 
        else if (currentFertilizer < 0.2f) { 
            if (currentVisuals.lackOfFertilizerMesh) currentVisuals.lackOfFertilizerMesh.SetActive(true);
            SwitchLand(LandStatus.Soil);
        } 
        else if (currentPesticide < 0.2f) {
            if (currentVisuals.lackOfPesticideMesh) currentVisuals.lackOfPesticideMesh.SetActive(true);
            SwitchLand(LandStatus.Farm);
        } 
        else if (currentPesticide > 0.8f) {
            if (currentVisuals.tooMuchPesticideMesh) currentVisuals.tooMuchPesticideMesh.SetActive(true);
            SwitchLand(LandStatus.Farm);
        } 
        else {
            if (currentVisuals.healthyMesh) currentVisuals.healthyMesh.SetActive(true);
            SwitchLand(LandStatus.Farm);
        }
    }

    void HarvestTimeout()
    {
        currentGrowth -= (100f / currentPlantData.timeToSpoil) * Time.deltaTime;
        if (currentGrowth <= 0f)
        {
            currentGrowth = 0f;
            isWithered = true;
            if (currentVisuals)
            {
                currentVisuals.HideAllPlants();
                if (currentVisuals.witheredMesh) currentVisuals.witheredMesh.SetActive(true);
            }
        }
    }

    void UpdateUI()
    {
        if (uiScript != null && plantUICanvas.activeSelf)
        {
            uiScript.waterSlider.value = currentWater;
            uiScript.fertilizerSlider.value = currentFertilizer;
            uiScript.pesticideSlider.value = currentPesticide;
            uiScript.progressSlider.value = currentGrowth / 100f; 
        }
    }

    public void SwitchLand(LandStatus statusToSwitch)
    {
        landStatus = statusToSwitch;
        Material materialToSwitch = soilMat;

        switch (statusToSwitch)
        {
            case(LandStatus.Soil): materialToSwitch = soilMat; break;
            case(LandStatus.Farm): materialToSwitch = farmMat; break;
            case(LandStatus.Watered): materialToSwitch = wateredMat; break; 
        }
        renderer.material = materialToSwitch;
    }

    public void Select(bool toggle)
    {
        if (select) select.SetActive(toggle);
        if (plantUICanvas) plantUICanvas.SetActive(toggle); 
    }

    public bool Interact(HeldItem heldItem)
    {
        if (!isPlanted)
        {
            if (heldItem != HeldItem.None)
            {
                Debug.Log("No Plant here");
                return false; 
            }

            if (currentPlantData == null || currentPlantData.plantPrefab == null) return false;

            Vector3 spawnPos = plantSocket != null ? plantSocket.position : transform.position;
            activePlantObject = Instantiate(currentPlantData.plantPrefab, spawnPos, Quaternion.identity, transform);
            currentVisuals = activePlantObject.GetComponent<PlantVisuals>();

            if (currentVisuals)
            {
                currentVisuals.HideAllPlants();
                if (currentVisuals.healthyMesh) currentVisuals.healthyMesh.SetActive(true);
            }
            
            isPlanted = true;
            isDead = false;
            isReadyToHarvest = false;
            isWithered = false;
            currentGrowth = 5f; 
            
            currentWater = 0.5f;
            currentFertilizer = 0.5f;
            currentPesticide = 0.5f;
            
            return false; 
        }

        if (isPlanted && !isDead && !isWithered && !isReadyToHarvest && heldItem != HeldItem.None)
        {
            if (heldItem == HeldItem.Water) currentWater += waterBoost;
            else if (heldItem == HeldItem.Fertilizer) currentFertilizer += fertBoost;
            else if (heldItem == HeldItem.Pesticide) currentPesticide += pestBoost;

            currentWater = Mathf.Clamp01(currentWater);
            currentFertilizer = Mathf.Clamp01(currentFertilizer);
            currentPesticide = Mathf.Clamp01(currentPesticide);

            return true; 
        }

        return false;
    }
}