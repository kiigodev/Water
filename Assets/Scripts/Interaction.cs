using UnityEngine;

public class Interaction : MonoBehaviour
{
    Land selectedLand; //[cite: 2]
    ItemStation selectedStation; //[cite: 2]

    void Update()
    {
        RaycastHit hit;
        if(Physics.Raycast(transform.position, Vector3.down, out hit, 1.5f)) {
            OnInteract(hit);
        } else {
            ClearSelection();
        }

        // Handle the 'E' pickup
        if (Input.GetKeyDown(KeyCode.E) && selectedStation != null)
        {
            // CALLING THE STATION LOGIC DIRECTLY
            selectedStation.Pickup(); 
        }
    }

    public void OnInteract(RaycastHit hit)
    {
        ItemStation station = hit.collider.GetComponent<ItemStation>(); //[cite: 2]
        if(station != null) {
            if (selectedLand != null) selectedLand.Select(false);
            selectedLand = null;
            selectedStation = station;
            InventoryManager.Instance.SetHover(true, $"[E] Pick up {station.GetDisplayName()}");
            return;
        }

        Land land = hit.collider.GetComponent<Land>(); //[cite: 2]
        if(land != null) {
            selectedStation = null;
            SelectLand(land);
            InventoryManager.Instance.SetHover(false);
            return;
        }

        ClearSelection();
    }

    public void SelectLand(Land land)
    {
        if(selectedLand != null) selectedLand.Select(false);
        selectedLand = land;
        land.Select(true); //[cite: 2]
    }

    void ClearSelection()
    {
        if(selectedLand != null) {
            selectedLand.Select(false);
            selectedLand = null;
        }
        selectedStation = null;
        InventoryManager.Instance.SetHover(false);
    }

    public void Interact()
    {
        if(selectedLand != null)
        {
            bool itemUsed = selectedLand.Interact(InventoryManager.Instance.currentItem); //[cite: 2]
            if (itemUsed) InventoryManager.Instance.ConsumeItem(); 
        }
    }
}