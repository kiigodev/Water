using UnityEngine;

public class PlantVisuals : MonoBehaviour
{
    public GameObject healthyMesh;
    public GameObject tooMuchWaterMesh;
    public GameObject lackOfFertilizerMesh; 
    public GameObject lackOfPesticideMesh;
    public GameObject tooMuchPesticideMesh;
    public GameObject deadMesh;
    public GameObject readyToHarvestMesh;
    public GameObject witheredMesh;

    public void HideAllPlants()
    {
        if (healthyMesh) healthyMesh.SetActive(false);
        if (tooMuchWaterMesh) tooMuchWaterMesh.SetActive(false);
        if (lackOfFertilizerMesh) lackOfFertilizerMesh.SetActive(false);
        if (lackOfPesticideMesh) lackOfPesticideMesh.SetActive(false);
        if (tooMuchPesticideMesh) tooMuchPesticideMesh.SetActive(false);
        if (deadMesh) deadMesh.SetActive(false);
        if (readyToHarvestMesh) readyToHarvestMesh.SetActive(false);
        if (witheredMesh) witheredMesh.SetActive(false);
    }
}