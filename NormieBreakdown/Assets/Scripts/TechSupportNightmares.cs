using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using TMPro;

public class TechSupportNightmares : MonoBehaviour
{
    [Header("UI Elements")]
    [SerializeField] private UIManager uiManager;
    [SerializeField] private GameObject errorPanel;
    [SerializeField] private TextMeshProUGUI errorText;
    [SerializeField] private GameObject ticketPanel;
    [SerializeField] private TextMeshProUGUI ticketText;
    [SerializeField] private GameObject troubleshootingPanel;
    [SerializeField] private TextMeshProUGUI troubleshootingText;
    
    [Header("Tech Support Parameters")]
    [SerializeField] private float errorFrequency = 120f; // Every 2 minutes
    [SerializeField] private float ticketFrequency = 180f; // Every 3 minutes
    [SerializeField] private float systemStability = 100f;
    
    [Header("Effects")]
    [SerializeField] private AudioClip errorSound;
    [SerializeField] private AudioClip ticketSound;
    [SerializeField] private AudioClip troubleshootingSound;
    [SerializeField] private ParticleSystem errorParticles;
    [SerializeField] private ParticleSystem blueScreenParticles;
    
    private AudioSource audioSource;
    private float timeSinceLastError = 0f;
    private float timeSinceLastTicket = 0f;
    private int errorCount = 0;
    private int ticketCount = 0;
    private bool isInTroubleshooting = false;

    // List of absurd error messages
    private readonly string[] errorMessages = new string[]
    {
        "Error 404: Sanity not found",
        "Exception: Life has no meaning",
        "Stack Overflow: Too many problems",
        "Memory Leak: Tears detected",
        "Null Reference: Purpose of life",
        "Buffer Overflow: Too many feelings",
        "Segmentation Fault: Personality split",
        "Runtime Error: Existence failed",
        "Syntax Error: Life choices invalid",
        "Fatal Error: Will to live not found"
    };

    // List of help desk tickets
    private readonly string[] ticketMessages = new string[]
    {
        "Ticket #{0}: Game keeps making me question my life choices",
        "Ticket #{0}: Character's tears are causing performance issues",
        "Ticket #{0}: Existential crisis feature too realistic",
        "Ticket #{0}: Coffee stains affecting collision detection",
        "Ticket #{0}: Synergy particles causing visual hallucinations",
        "Ticket #{0}: Productivity meter too accurate",
        "Ticket #{0}: Meetings are too relatable",
        "Ticket #{0}: KPIs making me feel inadequate",
        "Ticket #{0}: Keyboard smashing too therapeutic",
        "Ticket #{0}: Despair meter working as intended (this is a bug)"
    };

    // List of absurd troubleshooting steps
    private readonly string[] troubleshootingSteps = new string[]
    {
        "Step 1: Have you tried turning your brain off and on again?",
        "Step 2: Please describe your childhood trauma in detail",
        "Step 3: Try uninstalling your self-esteem",
        "Step 4: Reinstall your will to live",
        "Step 5: Clear your existential cache",
        "Step 6: Defragment your personality",
        "Step 7: Update your life choices",
        "Step 8: Reboot your sense of purpose",
        "Step 9: Check if your soul is properly connected",
        "Step 10: Try being someone else"
    };

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        StartCoroutine(RandomErrors());
        StartCoroutine(RandomTickets());
    }

    IEnumerator RandomErrors()
    {
        while (true)
        {
            timeSinceLastError += Time.deltaTime;
            
            if (timeSinceLastError >= errorFrequency)
            {
                timeSinceLastError = 0f;
                ShowError();
            }

            yield return null;
        }
    }

    void ShowError()
    {
        errorCount++;
        systemStability = Mathf.Max(0f, systemStability - Random.Range(5f, 15f));
        
        // Get random error message
        string error = errorMessages[Random.Range(0, errorMessages.Length)];
        errorText.text = $"ERROR #{errorCount}\n\n{error}\n\nSystem Stability: {systemStability:F0}%";
        
        // Show error panel
        errorPanel.SetActive(true);
        PlaySound(errorSound);

        // Show error particles
        if (errorParticles != null)
        {
            errorParticles.Play();
        }

        // Chance for blue screen
        if (Random.value < 0.1f)
        {
            StartCoroutine(ShowBlueScreen());
        }

        StartCoroutine(HideError());
    }

    IEnumerator ShowBlueScreen()
    {
        if (blueScreenParticles != null)
        {
            blueScreenParticles.Play();
        }

        // Show blue screen error
        string blueScreen = ":( Your PC ran into a problem and needs to restart.\nWe're just collecting some error info, and then we'll restart for you.\n(0% complete)\n\nStop code: EXISTENTIAL_CRISIS";
        uiManager.ShowUpdate(blueScreen);

        yield return new WaitForSeconds(3f);

        // "Restart" the game
        systemStability = 100f;
        errorCount = 0;
        ticketCount = 0;
    }

    IEnumerator HideError()
    {
        yield return new WaitForSeconds(3f);
        errorPanel.SetActive(false);
    }

    IEnumerator RandomTickets()
    {
        while (true)
        {
            timeSinceLastTicket += Time.deltaTime;
            
            if (timeSinceLastTicket >= ticketFrequency)
            {
                timeSinceLastTicket = 0f;
                ShowTicket();
            }

            yield return null;
        }
    }

    void ShowTicket()
    {
        ticketCount++;
        
        // Get random ticket message
        string ticket = string.Format(ticketMessages[Random.Range(0, ticketMessages.Length)], ticketCount);
        ticketText.text = ticket;
        
        // Show ticket panel
        ticketPanel.SetActive(true);
        PlaySound(ticketSound);

        // Start troubleshooting after delay
        StartCoroutine(StartTroubleshooting());
    }

    IEnumerator StartTroubleshooting()
    {
        yield return new WaitForSeconds(2f);
        
        isInTroubleshooting = true;
        troubleshootingPanel.SetActive(true);
        
        // Show each troubleshooting step
        foreach (string step in troubleshootingSteps)
        {
            troubleshootingText.text = step;
            PlaySound(troubleshootingSound);
            yield return new WaitForSeconds(2f);
        }

        // End troubleshooting
        troubleshootingPanel.SetActive(false);
        ticketPanel.SetActive(false);
        isInTroubleshooting = false;

        // Show resolution (always fails)
        string resolution = "Resolution: Unable to reproduce issue. Ticket closed.";
        uiManager.ShowUpdate(resolution);
    }

    private void PlaySound(AudioClip clip)
    {
        if (audioSource != null && clip != null)
        {
            audioSource.clip = clip;
            audioSource.pitch = Random.Range(0.8f, 1.2f);
            audioSource.Play();
        }
    }

    // Easter egg for developers
    void OnEnable()
    {
        if (Application.isEditor)
        {
            Debug.Log("You're reading the source code? That's not in the troubleshooting guide.");
        }
    }
} 