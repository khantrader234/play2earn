using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using TMPro;

public class CorporateNightmares : MonoBehaviour
{
    [Header("UI Elements")]
    [SerializeField] private UIManager uiManager;
    [SerializeField] private GameObject meetingPanel;
    [SerializeField] private TextMeshProUGUI meetingText;
    [SerializeField] private GameObject kpiPanel;
    [SerializeField] private TextMeshProUGUI kpiText;
    
    [Header("Corporate Parameters")]
    [SerializeField] private float meetingFrequency = 300f; // Every 5 minutes
    [SerializeField] private float kpiUpdateFrequency = 60f; // Every minute
    [SerializeField] private float productivity = 100f;
    [SerializeField] private float synergy = 0f;
    
    [Header("Effects")]
    [SerializeField] private AudioClip meetingSound;
    [SerializeField] private AudioClip kpiSound;
    [SerializeField] private ParticleSystem synergyParticles;
    
    private AudioSource audioSource;
    private float timeSinceLastMeeting = 0f;
    private float timeSinceLastKPI = 0f;
    private int meetingCount = 0;
    private bool isInMeeting = false;

    // Corporate buzzwords for meetings
    private readonly string[] meetingPhrases = new string[]
    {
        "Let's circle back on that",
        "We need to leverage our core competencies",
        "Let's take this offline",
        "We need to think outside the box",
        "Let's touch base on this",
        "We need to pivot our strategy",
        "Let's drill down into this",
        "We need to move the needle",
        "Let's unpack this",
        "We need to double-click on this"
    };

    // KPI metrics
    private readonly string[] kpiMetrics = new string[]
    {
        "Productivity: {0}% (Down from yesterday)",
        "Synergy: {0}% (We need more synergy)",
        "ROI: {0}% (Not enough return)",
        "Engagement: {0}% (Employees are disengaged)",
        "Innovation: {0}% (Not innovative enough)",
        "Efficiency: {0}% (Too many coffee breaks)",
        "Collaboration: {0}% (Not enough teamwork)",
        "Growth: {0}% (Not growing fast enough)",
        "Impact: {0}% (Not impactful enough)",
        "Value: {0}% (Not valuable enough)"
    };

    // Meeting agendas
    private readonly string[] meetingAgendas = new string[]
    {
        "Discussing why we're not meeting our KPIs",
        "Planning a meeting to plan our next meeting",
        "Reviewing the review process",
        "Discussing the discussion points",
        "Planning to plan our planning",
        "Reviewing our review of the review process",
        "Discussing why we're not discussing enough",
        "Planning our next planning session",
        "Reviewing why we're not reviewing enough",
        "Discussing our discussion strategy"
    };

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        StartCoroutine(UpdateKPIs());
        StartCoroutine(RandomMeetings());
    }

    IEnumerator UpdateKPIs()
    {
        while (true)
        {
            timeSinceLastKPI += Time.deltaTime;
            
            if (timeSinceLastKPI >= kpiUpdateFrequency)
            {
                timeSinceLastKPI = 0f;
                ShowKPIUpdate();
            }

            yield return null;
        }
    }

    void ShowKPIUpdate()
    {
        // Randomly decrease productivity
        productivity = Mathf.Max(0f, productivity - Random.Range(1f, 5f));
        
        // Randomly increase or decrease synergy
        synergy = Mathf.Clamp(synergy + Random.Range(-10f, 5f), 0f, 100f);

        // Show random KPI metric
        string metric = kpiMetrics[Random.Range(0, kpiMetrics.Length)];
        float value = Random.Range(0f, 100f);
        kpiText.text = string.Format(metric, value);

        // Show KPI panel
        kpiPanel.SetActive(true);
        PlaySound(kpiSound);

        // Show synergy particles if synergy is high
        if (synergy > 50f && synergyParticles != null)
        {
            synergyParticles.Play();
        }

        StartCoroutine(HideKPI());
    }

    IEnumerator HideKPI()
    {
        yield return new WaitForSeconds(3f);
        kpiPanel.SetActive(false);
    }

    IEnumerator RandomMeetings()
    {
        while (true)
        {
            timeSinceLastMeeting += Time.deltaTime;
            
            if (timeSinceLastMeeting >= meetingFrequency && !isInMeeting)
            {
                timeSinceLastMeeting = 0f;
                StartCoroutine(StartMeeting());
            }

            yield return null;
        }
    }

    IEnumerator StartMeeting()
    {
        isInMeeting = true;
        meetingCount++;
        
        // Show meeting panel
        meetingPanel.SetActive(true);
        PlaySound(meetingSound);

        // Generate meeting content
        string agenda = meetingAgendas[Random.Range(0, meetingAgendas.Length)];
        string phrase = meetingPhrases[Random.Range(0, meetingPhrases.Length)];
        
        meetingText.text = $"MEETING #{meetingCount}\n\nAgenda: {agenda}\n\n{phrase}";

        // Decrease productivity during meeting
        float originalProductivity = productivity;
        productivity = Mathf.Max(0f, productivity - 20f);

        yield return new WaitForSeconds(5f);

        // End meeting
        meetingPanel.SetActive(false);
        isInMeeting = false;

        // Show post-meeting update
        string update = $"Meeting completed. Productivity decreased from {originalProductivity:F0}% to {productivity:F0}%";
        uiManager.ShowUpdate(update);
    }

    private void PlaySound(AudioClip clip)
    {
        if (audioSource != null && clip != null)
        {
            audioSource.clip = clip;
            audioSource.pitch = Random.Range(0.9f, 1.1f);
            audioSource.Play();
        }
    }

    // Easter egg for developers
    void OnEnable()
    {
        if (Application.isEditor)
        {
            Debug.Log("You're reading the source code? That's not very synergistic of you.");
        }
    }
} 