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
    public PlantData plantDataA; 
    public PlantData plantDataB; 
    private PlantData activePlantData; 
    private HeldItem harvestItemToGive; 

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

        currentGrowth += currentGrowthRate * (100f / activePlantData.timeToFullyGrow) * Time.deltaTime;

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
        currentGrowth -= (100f / activePlantData.timeToSpoil) * Time.deltaTime;
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
        Debug.Log($"Land received interaction! Item held: {heldItem}");

        // 1. PLANTING A SEED
        if (!isPlanted)
        {
            Debug.Log("Land is empty. Checking if we have a seed...");
            if (heldItem == HeldItem.SeedA || heldItem == HeldItem.SeedB)
            {
                Debug.Log("We have a seed! Setting up PlantData...");
                
                activePlantData = (heldItem == HeldItem.SeedA) ? plantDataA : plantDataB;
                harvestItemToGive = (heldItem == HeldItem.SeedA) ? HeldItem.FarmedPlantA : HeldItem.FarmedPlantB;
                
                if (activePlantData == null) {
                    Debug.LogWarning("BRO! activePlantData is empty in the Inspector! Can't plant!");
                    return false;
                }
                if (activePlantData.plantPrefab == null) {
                    Debug.LogWarning("BRO! plantPrefab is empty inside your PlantData! Can't plant!");
                    return false;
                }

                Debug.Log("PlantData is good. Spawning plant now!");
                Vector3 spawnPos = plantSocket != null ? plantSocket.position : transform.position;
                activePlantObject = Instantiate(activePlantData.plantPrefab, spawnPos, Quaternion.identity, transform);
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
                
                return true; 
            }
            Debug.Log("Not holding a seed, can't do anything to empty dirt.");
            return false; 
        }

        if (heldItem == HeldItem.Shovel)
        {
            // MUST CHECK THIS FIRST! 
            if (isDead || isWithered)
            {
                Debug.Log("Cleared dead/withered plant! (No items given)");
                ResetLand();
            }
            // IF it's not dead/withered, THEN check if we can harvest!
            else if (isReadyToHarvest)
            {
                Debug.Log("Harvested healthy plant!");
                InventoryManager.Instance.AddItem(harvestItemToGive, 1);
                ResetLand(); 
            }
            else
            {
                Debug.Log("Plant is still growing, shovel does nothing right now.");
            }
            return false; 
        }

        // 3. APPLYING STATS
        if (isPlanted && !isDead && !isWithered && !isReadyToHarvest && heldItem != HeldItem.None)
        {
            Debug.Log("Applying stats to growing plant!");
            if (heldItem == HeldItem.Water) currentWater += waterBoost;
            else if (heldItem == HeldItem.Fertilizer) currentFertilizer += fertBoost;
            else if (heldItem == HeldItem.Pesticide) currentPesticide += pestBoost;

            currentWater = Mathf.Clamp01(currentWater);
            currentFertilizer = Mathf.Clamp01(currentFertilizer);
            currentPesticide = Mathf.Clamp01(currentPesticide);

            return (heldItem == HeldItem.Fertilizer || heldItem == HeldItem.Pesticide); 
        }

        return false;
    }

    void ResetLand()
    {
        isPlanted = false;
        isReadyToHarvest = false;
        isDead = false;
        isWithered = false;
        if (activePlantObject != null) Destroy(activePlantObject);
        SwitchLand(LandStatus.Soil);
        UpdateUI();
    }
}