using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using TMPro;

public class DeveloperDespair : MonoBehaviour
{
    [Header("UI Elements")]
    [SerializeField] private UIManager uiManager;
    [SerializeField] private GameObject keyboardSmashPanel;
    [SerializeField] private TextMeshProUGUI keyboardSmashText;
    
    [Header("Despair Parameters")]
    [SerializeField] private float despairLevel = 0f;
    [SerializeField] private float despairIncreaseRate = 0.1f;
    [SerializeField] private float maxDespairLevel = 100f;
    
    [Header("Effects")]
    [SerializeField] private ParticleSystem despairParticles;
    [SerializeField] private AudioClip keyboardSmashSound;
    [SerializeField] private AudioClip existentialCrisisSound;
    
    private AudioSource audioSource;
    private bool isInCrisis = false;
    private float timeSinceLastCrisis = 0f;
    private readonly float minTimeBetweenCrises = 60f;

    // List of keyboard smash combinations
    private readonly string[] keyboardSmashes = new string[]
    {
        "ASDFJKL;ASDFJKL;",
        "QWERTYUIOP",
        "ZXCVBNM,./",
        "1234567890",
        "!@#$%^&*()",
        "asdfghjkl;'",
        "qwertyuiop[]",
        "zxcvbnm,./",
        "`1234567890-=",
        "~!@#$%^&*()_+"
    };

    // List of existential crisis events
    private readonly string[] crisisEvents = new string[]
    {
        "Why am I even doing this?",
        "Is this what my life has become?",
        "I should have been a farmer...",
        "Maybe I should learn to knit instead",
        "What's the point of all this?",
        "I miss my childhood...",
        "Why did I choose this career?",
        "Is this really what I wanted?",
        "I could have been happy...",
        "What have I done with my life?"
    };

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        StartCoroutine(IncreaseDespair());
        StartCoroutine(RandomCrisisEvents());
    }

    IEnumerator IncreaseDespair()
    {
        while (true)
        {
            despairLevel += despairIncreaseRate * Time.deltaTime;
            despairLevel = Mathf.Clamp(despairLevel, 0f, maxDespairLevel);
            
            // Trigger effects based on despair level
            if (despairLevel > 50f && !isInCrisis)
            {
                StartCoroutine(KeyboardSmashEvent());
            }
            
            if (despairLevel > 75f && timeSinceLastCrisis >= minTimeBetweenCrises)
            {
                StartCoroutine(ExistentialCrisisEvent());
            }

            yield return null;
        }
    }

    IEnumerator KeyboardSmashEvent()
    {
        isInCrisis = true;
        
        // Show keyboard smash text
        string smash = keyboardSmashes[Random.Range(0, keyboardSmashes.Length)];
        keyboardSmashText.text = smash;
        keyboardSmashPanel.SetActive(true);
        
        // Play keyboard smash sound
        audioSource.clip = keyboardSmashSound;
        audioSource.pitch = Random.Range(0.8f, 1.2f);
        audioSource.Play();
        
        // Show particles
        if (despairParticles != null)
        {
            despairParticles.Play();
        }

        yield return new WaitForSeconds(2f);
        
        keyboardSmashPanel.SetActive(false);
        isInCrisis = false;
    }

    IEnumerator ExistentialCrisisEvent()
    {
        timeSinceLastCrisis = 0f;
        isInCrisis = true;
        
        // Get random crisis event
        string crisis = crisisEvents[Random.Range(0, crisisEvents.Length)];
        
        // Show crisis in UI
        uiManager.ShowUpdate(crisis);
        
        // Play crisis sound
        audioSource.clip = existentialCrisisSound;
        audioSource.pitch = Random.Range(0.8f, 1.2f);
        audioSource.Play();
        
        // Trigger visual effects
        if (despairParticles != null)
        {
            despairParticles.startLifetime = 2f;
            despairParticles.Play();
        }

        // Randomly invert controls or change gravity
        if (Random.value < 0.5f)
        {
            Physics2D.gravity *= -1;
            yield return new WaitForSeconds(3f);
            Physics2D.gravity *= -1;
        }

        yield return new WaitForSeconds(5f);
        isInCrisis = false;
    }

    IEnumerator RandomCrisisEvents()
    {
        while (true)
        {
            timeSinceLastCrisis += Time.deltaTime;
            
            // Random chance for crisis based on despair level
            if (Random.value < despairLevel / maxDespairLevel * 0.01f && timeSinceLastCrisis >= minTimeBetweenCrises)
            {
                StartCoroutine(ExistentialCrisisEvent());
            }
            
            yield return new WaitForSeconds(1f);
        }
    }

    public void AddDespair(float amount)
    {
        despairLevel = Mathf.Clamp(despairLevel + amount, 0f, maxDespairLevel);
    }

    public void ResetDespair()
    {
        despairLevel = 0f;
        timeSinceLastCrisis = minTimeBetweenCrises;
    }

    // Easter egg for developers
    void OnEnable()
    {
        if (Application.isEditor)
        {
            Debug.Log("You're reading the source code? That's meta. And concerning.");
        }
    }
} 