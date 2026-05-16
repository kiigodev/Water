using UnityEngine;

public class PlayerAnimator : MonoBehaviour
{
    private Animator animator;

    void Start()
    {
        animator = GetComponent<Animator>();
    }

void Update()
{
    float horizontal = Input.GetAxisRaw("Horizontal");
    float vertical = Input.GetAxisRaw("Vertical");

    bool isMoving = horizontal != 0 || vertical != 0;

    animator.SetBool("isWalking", isMoving);

    // Paksa animasi tidak berhenti di tengah jalan
    if (isMoving)
    {
        animator.speed = 1f; // animasi berjalan normal
    }
    else
    {
        animator.speed = 1f; // tetap normal saat idle
    }
}
}