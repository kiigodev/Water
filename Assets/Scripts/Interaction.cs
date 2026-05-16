using UnityEngine;

public class Interaction : MonoBehaviour
{
    [Header("Player Inventory")]
    public HeldItem currentItem = HeldItem.None;

    Land selectedLand;
    ItemStation selectedStation;

    void Update()
    {
        RaycastHit hit;
        if(Physics.Raycast(transform.position, Vector3.down, out hit, 1.5f))
        {
            OnInteract(hit);
        }
        else
        {
            ClearSelection();
        }

        // ONLY handling the 'E' pickup here! Leaving your click alone.
        if (Input.GetKeyDown(KeyCode.E))
        {
            if (selectedStation != null)
            {
                if (currentItem != HeldItem.None)
                {
                    Debug.Log("Already have an item!");
                }
                else
                {
                    currentItem = selectedStation.itemGiven;
                    Debug.Log("Picked up: " + currentItem);
                }
            }
        }
    }

    public void OnInteract(RaycastHit hit)
    {
        Land land = hit.collider.GetComponent<Land>();
        if(land != null)
        {
            selectedStation = null;
            SelectLand(land);
            return;
        }

        ItemStation station = hit.collider.GetComponent<ItemStation>();
        if(station != null)
        {
            if (selectedLand != null) selectedLand.Select(false);
            selectedLand = null;
            selectedStation = station;
            return;
        }

        ClearSelection();
    }

    public void SelectLand(Land land)
    {
        if(selectedLand != null) selectedLand.Select(false);
        selectedLand = land;
        land.Select(true);
    }

    void ClearSelection()
    {
        if(selectedLand != null)
        {
            selectedLand.Select(false);
            selectedLand = null;
        }
        selectedStation = null;
    }

    // Put this back EXACTLY how it was so your player script can call it!
    public void Interact()
    {
        if(selectedLand != null)
        {
            bool itemUsed = selectedLand.Interact(currentItem);
            if (itemUsed) 
            {
                currentItem = HeldItem.None; 
            }
        }
    }
}