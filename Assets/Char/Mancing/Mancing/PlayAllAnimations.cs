using UnityEngine;

public class PlayAllAnimations : MonoBehaviour
{
    [Header("Assign di Inspector")]
    public Animator badanAnimator;
    public Animator ikanAnimator;
    public Animator pancinganAnimator;
    public Animator ujungPancinganAnimator;

    void Start()
    {
        PlayAll();
    }

    void PlayAll()
    {
        if (badanAnimator != null)
            badanAnimator.Play("Badan");
        
        if (ikanAnimator != null)
            ikanAnimator.Play("Ikan");
        
        if (pancinganAnimator != null)
            pancinganAnimator.Play("Pancingan");
        
        if (ujungPancinganAnimator != null)
            ujungPancinganAnimator.Play("Ujung Pancingan");
    }
}