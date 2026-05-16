using UnityEngine;

public class ThirdPersonCamera : MonoBehaviour
{
    [Header("Target")]
    public Transform player;

    [Header("Distance Settings")]
    public float minDistance = 0.5f;
    public float maxDistance = 5f;
    public float zoomSpeed = 5f;
    public float smoothSpeed = 10f;

    [Header("Position Offset")]
    public float height = 1.5f;
    public float horizontalOffset = 0f;

    [Header("Mouse Look")]
    public float mouseSensitivity = 200f;
    public float minVerticalAngle = -40f;
    public float maxVerticalAngle = 70f;

    // 🧱 NEW: Collision Stuff!
    [Header("Collision")]
    public LayerMask collisionMask;
    public float cameraRadius = 0.2f;

    float targetDistance;
    float currentDistance;

    float xRotation = 0f;
    float yRotation = 0f;

    // 🎥 NEW: Dialogue Camera Stuff!
    private bool isInDialogue = false;
    private Transform currentSocket;

    void Start()
    {
        targetDistance = maxDistance;
        currentDistance = maxDistance;

        Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        if (isInDialogue) return; 

        HandleMouseLook();
        HandleZoom();
    }

    void LateUpdate()
    {
        if (isInDialogue && currentSocket != null)
        {
            transform.position = Vector3.Lerp(transform.position, currentSocket.position, Time.deltaTime * smoothSpeed);
            transform.rotation = Quaternion.Slerp(transform.rotation, currentSocket.rotation, Time.deltaTime * smoothSpeed);
            return;
        }

        UpdateCameraPosition();
    }

    void HandleMouseLook()
    {
        float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity * Time.deltaTime;
        float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity * Time.deltaTime;

        yRotation += mouseX;
        xRotation -= mouseY;
        xRotation = Mathf.Clamp(xRotation, minVerticalAngle, maxVerticalAngle);
    }

    void HandleZoom()
    {
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        targetDistance -= scroll * zoomSpeed;
        targetDistance = Mathf.Clamp(targetDistance, minDistance, maxDistance);
    }

    void UpdateCameraPosition()
    {
        currentDistance = Mathf.Lerp(currentDistance, targetDistance, Time.deltaTime * smoothSpeed);

        Quaternion rotation = Quaternion.Euler(xRotation, yRotation, 0);
        Vector3 direction = rotation * Vector3.back;
        Vector3 right = rotation * Vector3.right;

        Vector3 targetPivot = player.position + Vector3.up * height + right * horizontalOffset;
        
        float finalDistance = currentDistance;
        if (Physics.SphereCast(targetPivot, cameraRadius, direction, out RaycastHit hit, currentDistance, collisionMask))
        {
            finalDistance = hit.distance; 
        }

        Vector3 position = targetPivot + direction * finalDistance;

        transform.position = position;
        transform.rotation = rotation;

        player.rotation = Quaternion.Euler(0, yRotation, 0);
    }

    public void SetDialogueCamera(bool active, Transform socket = null)
    {
        isInDialogue = active;
        currentSocket = socket;
    }
}