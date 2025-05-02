using UnityEngine;
using System.Collections;

public class PlayerCharacter : MonoBehaviour
{
    [Header("Character States")]
    [SerializeField] private float mentalStability = 100f;
    [SerializeField] private float coffeeAddiction = 0f;
    [SerializeField] private float existentialDread = 0f;
    [SerializeField] private float productivity = 100f;
    
    [Header("Visual Elements")]
    [SerializeField] private SpriteRenderer characterSprite;
    [SerializeField] private ParticleSystem tearParticles;
    [SerializeField] private ParticleSystem coffeeStainParticles;
    [SerializeField] private ParticleSystem existentialCrisisParticles;
    
    [Header("Animation")]
    [SerializeField] private Animator animator;
    [SerializeField] private float shakeMagnitude = 0.1f;
    
    [Header("References")]
    [SerializeField] private UIManager uiManager;
    
    private Vector3 originalPosition;
    private bool isHavingBreakdown = false;
    private bool isInMeeting = false;
    
    private readonly string[] breakdownPhrases = new string[]
    {
        "I can't take this anymore!",
        "Why are we still here? Just to suffer?",
        "The code... it's all meaningless!",
        "Another meeting? ANOTHER MEETING?!",
        "I don't want to live in a world of JIRA tickets!",
        "The sprints never end... they never end...",
        "My life is an infinite loop...",
        "Control-Z can't undo my life choices...",
        "Alt-F4 me out of existence..."
    };

    void Start()
    {
        originalPosition = transform.position;
        StartCoroutine(DegradeMentalState());
        StartCoroutine(IncreaseCoffeeAddiction());
    }

    void Update()
    {
        // Update visual state based on mental stability
        if (mentalStability < 50f && !isHavingBreakdown)
        {
            StartCoroutine(TriggerBreakdown());
        }

        // Shake character based on coffee addiction
        if (coffeeAddiction > 70f)
        {
            transform.position = originalPosition + Random.insideUnitSphere * (shakeMagnitude * (coffeeAddiction / 100f));
        }

        // Visual effects for existential dread
        if (existentialDread > 80f && existentialCrisisParticles != null)
        {
            existentialCrisisParticles.Play();
        }

        // Update UI
        uiManager.UpdateDespairMeter(existentialDread, 100f);
        uiManager.UpdateProductivityMeter(productivity);
    }

    private IEnumerator DegradeMentalState()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(10f, 30f));
            
            if (!isInMeeting) // Meetings degrade mental state separately
            {
                mentalStability = Mathf.Max(0f, mentalStability - Random.Range(1f, 5f));
                existentialDread = Mathf.Min(100f, existentialDread + Random.Range(1f, 3f));
                productivity = Mathf.Max(0f, productivity - Random.Range(0f, 2f));
            }

            // Trigger tear particles
            if (tearParticles != null && mentalStability < 70f)
            {
                tearParticles.Play();
            }

            // Update animation state
            if (animator != null)
            {
                animator.SetFloat("MentalStability", mentalStability / 100f);
                animator.SetFloat("ExistentialDread", existentialDread / 100f);
            }
        }
    }

    private IEnumerator IncreaseCoffeeAddiction()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(20f, 60f));
            
            coffeeAddiction = Mathf.Min(100f, coffeeAddiction + Random.Range(5f, 15f));
            productivity = Mathf.Min(100f, productivity + Random.Range(10f, 20f));

            if (coffeeStainParticles != null && coffeeAddiction > 50f)
            {
                coffeeStainParticles.Play();
            }

            // Temporary productivity boost
            StartCoroutine(CoffeeCrash());
        }
    }

    private IEnumerator CoffeeCrash()
    {
        yield return new WaitForSeconds(Random.Range(30f, 60f));
        productivity = Mathf.Max(0f, productivity - Random.Range(20f, 40f));
        mentalStability = Mathf.Max(0f, mentalStability - Random.Range(5f, 10f));
    }

    private IEnumerator TriggerBreakdown()
    {
        isHavingBreakdown = true;
        
        // Show random breakdown phrase
        string phrase = breakdownPhrases[Random.Range(0, breakdownPhrases.Length)];
        uiManager.ShowKeyboardSmash(phrase);

        // Visual effects
        if (tearParticles != null) tearParticles.Play();
        if (existentialCrisisParticles != null) existentialCrisisParticles.Play();

        // Violent shaking
        float breakdownDuration = Random.Range(3f, 7f);
        float elapsed = 0f;
        
        while (elapsed < breakdownDuration)
        {
            transform.position = originalPosition + Random.insideUnitSphere * (shakeMagnitude * 2f);
            elapsed += Time.deltaTime;
            yield return null;
        }

        transform.position = originalPosition;
        isHavingBreakdown = false;
    }

    public void OnMeetingStart()
    {
        isInMeeting = true;
        mentalStability = Mathf.Max(0f, mentalStability - 20f);
        existentialDread = Mathf.Min(100f, existentialDread + 15f);
        productivity = 0f; // Meetings kill productivity
    }

    public void OnMeetingEnd()
    {
        isInMeeting = false;
        StartCoroutine(PostMeetingRecovery());
    }

    private IEnumerator PostMeetingRecovery()
    {
        yield return new WaitForSeconds(Random.Range(10f, 20f));
        productivity = Mathf.Min(100f, productivity + Random.Range(5f, 15f));
    }

    // Easter egg
    void OnApplicationQuit()
    {
        Debug.Log("You can check out any time you like, but you can never leave...");
    }
} 