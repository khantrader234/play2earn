using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class UIManager : MonoBehaviour
{
    [Header("Panels")]
    [SerializeField] private GameObject codeReviewPanel;
    [SerializeField] private GameObject achievementPanel;
    [SerializeField] private GameObject updateNotification;
    [SerializeField] private GameObject callMomPrompt;
    [SerializeField] private GameObject uninstallWarning;
    [SerializeField] private GameObject keyboardSmashPanel;
    [SerializeField] private GameObject despairMeterPanel;
    [SerializeField] private GameObject meetingPanel;
    [SerializeField] private GameObject kpiPanel;
    [SerializeField] private GameObject productivityMeterPanel;
    [SerializeField] private GameObject errorPanel;
    [SerializeField] private GameObject ticketPanel;
    [SerializeField] private GameObject troubleshootingPanel;
    [SerializeField] private GameObject systemStabilityPanel;

    [Header("Text Elements")]
    [SerializeField] private TextMeshProUGUI reviewCommentText;
    [SerializeField] private TextMeshProUGUI bugReportText;
    [SerializeField] private TextMeshProUGUI achievementText;
    [SerializeField] private TextMeshProUGUI updateText;
    [SerializeField] private TextMeshProUGUI playtimeText;
    [SerializeField] private TextMeshProUGUI momMessageText;
    [SerializeField] private TextMeshProUGUI keyboardSmashText;
    [SerializeField] private TextMeshProUGUI despairLevelText;
    [SerializeField] private TextMeshProUGUI meetingText;
    [SerializeField] private TextMeshProUGUI kpiText;
    [SerializeField] private TextMeshProUGUI productivityText;
    [SerializeField] private TextMeshProUGUI errorText;
    [SerializeField] private TextMeshProUGUI ticketText;
    [SerializeField] private TextMeshProUGUI troubleshootingText;
    [SerializeField] private TextMeshProUGUI systemStabilityText;

    [Header("Visual Effects")]
    [SerializeField] private Image coffeeStainImage;
    [SerializeField] private Image tearDropImage;
    [SerializeField] private ParticleSystem errorParticles;
    [SerializeField] private Image despairMeterFill;
    [SerializeField] private Color[] despairColors;
    [SerializeField] private Image productivityMeterFill;
    [SerializeField] private Color[] productivityColors;
    [SerializeField] private ParticleSystem synergyParticles;
    [SerializeField] private Image systemStabilityFill;
    [SerializeField] private Color[] stabilityColors;
    [SerializeField] private ParticleSystem blueScreenParticles;

    [Header("Audio")]
    [SerializeField] private AudioClip achievementSound;
    [SerializeField] private AudioClip errorSound;
    [SerializeField] private AudioClip updateSound;
    [SerializeField] private AudioClip momCallSound;
    [SerializeField] private AudioClip keyboardSmashSound;
    [SerializeField] private AudioClip existentialCrisisSound;
    [SerializeField] private AudioClip meetingSound;
    [SerializeField] private AudioClip kpiSound;
    [SerializeField] private AudioClip ticketSound;
    [SerializeField] private AudioClip troubleshootingSound;

    private AudioSource audioSource;
    private CanvasGroup codeReviewGroup;
    private CanvasGroup achievementGroup;
    private CanvasGroup updateGroup;
    private CanvasGroup keyboardSmashGroup;
    private CanvasGroup meetingGroup;
    private CanvasGroup kpiGroup;
    private CanvasGroup errorGroup;
    private CanvasGroup ticketGroup;
    private CanvasGroup troubleshootingGroup;

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        
        // Initialize canvas groups for fade effects
        codeReviewGroup = codeReviewPanel.GetComponent<CanvasGroup>();
        achievementGroup = achievementPanel.GetComponent<CanvasGroup>();
        updateGroup = updateNotification.GetComponent<CanvasGroup>();
        keyboardSmashGroup = keyboardSmashPanel.GetComponent<CanvasGroup>();
        meetingGroup = meetingPanel.GetComponent<CanvasGroup>();
        kpiGroup = kpiPanel.GetComponent<CanvasGroup>();
        errorGroup = errorPanel.GetComponent<CanvasGroup>();
        ticketGroup = ticketPanel.GetComponent<CanvasGroup>();
        troubleshootingGroup = troubleshootingPanel.GetComponent<CanvasGroup>();

        // Set initial states
        SetPanelVisibility(codeReviewPanel, false);
        SetPanelVisibility(achievementPanel, false);
        SetPanelVisibility(updateNotification, false);
        SetPanelVisibility(callMomPrompt, false);
        SetPanelVisibility(uninstallWarning, false);
        SetPanelVisibility(keyboardSmashPanel, false);
        SetPanelVisibility(despairMeterPanel, true);
        SetPanelVisibility(meetingPanel, false);
        SetPanelVisibility(kpiPanel, false);
        SetPanelVisibility(productivityMeterPanel, true);
        SetPanelVisibility(errorPanel, false);
        SetPanelVisibility(ticketPanel, false);
        SetPanelVisibility(troubleshootingPanel, false);
        SetPanelVisibility(systemStabilityPanel, true);

        // Set up visual effects
        if (coffeeStainImage != null)
        {
            coffeeStainImage.color = new Color(1f, 1f, 1f, 0f);
        }
        if (tearDropImage != null)
        {
            tearDropImage.color = new Color(1f, 1f, 1f, 0f);
        }
        if (despairMeterFill != null)
        {
            despairMeterFill.fillAmount = 0f;
            despairMeterFill.color = despairColors[0];
        }
        if (productivityMeterFill != null)
        {
            productivityMeterFill.fillAmount = 1f;
            productivityMeterFill.color = productivityColors[0];
        }
        if (systemStabilityFill != null)
        {
            systemStabilityFill.fillAmount = 1f;
            systemStabilityFill.color = stabilityColors[0];
        }
    }

    public void ShowCodeReview(string review, string bug)
    {
        reviewCommentText.text = review;
        bugReportText.text = bug;
        StartCoroutine(FadeInPanel(codeReviewPanel, codeReviewGroup));
        PlaySound(errorSound);
        if (errorParticles != null)
        {
            errorParticles.Play();
        }
    }

    public void ShowAchievement(string achievement)
    {
        achievementText.text = achievement;
        StartCoroutine(FadeInPanel(achievementPanel, achievementGroup));
        PlaySound(achievementSound);
    }

    public void ShowUpdate(string message)
    {
        updateText.text = message;
        StartCoroutine(FadeInPanel(updateNotification, updateGroup));
        PlaySound(updateSound);
    }

    public void ShowCallMom(string message)
    {
        momMessageText.text = message;
        SetPanelVisibility(callMomPrompt, true);
        PlaySound(momCallSound);
    }

    public void ShowUninstallWarning()
    {
        SetPanelVisibility(uninstallWarning, true);
    }

    public void UpdatePlaytimeText(string text)
    {
        playtimeText.text = text;
    }

    public void ShowCoffeeStain(float duration)
    {
        if (coffeeStainImage != null)
        {
            StartCoroutine(FadeInOutImage(coffeeStainImage, duration));
        }
    }

    public void ShowTearDrop(float duration)
    {
        if (tearDropImage != null)
        {
            StartCoroutine(FadeInOutImage(tearDropImage, duration));
        }
    }

    public void UpdateDespairMeter(float despairLevel, float maxDespair)
    {
        if (despairMeterFill != null)
        {
            float fillAmount = despairLevel / maxDespair;
            despairMeterFill.fillAmount = fillAmount;
            
            // Update color based on despair level
            int colorIndex = Mathf.FloorToInt(fillAmount * (despairColors.Length - 1));
            despairMeterFill.color = despairColors[colorIndex];
        }

        if (despairLevelText != null)
        {
            despairLevelText.text = $"Despair Level: {Mathf.FloorToInt(despairLevel)}%";
        }
    }

    public void ShowKeyboardSmash(string text)
    {
        keyboardSmashText.text = text;
        StartCoroutine(FadeInPanel(keyboardSmashPanel, keyboardSmashGroup));
        PlaySound(keyboardSmashSound);
    }

    public void UpdateProductivityMeter(float productivity)
    {
        if (productivityMeterFill != null)
        {
            float fillAmount = productivity / 100f;
            productivityMeterFill.fillAmount = fillAmount;
            
            // Update color based on productivity level
            int colorIndex = Mathf.FloorToInt((1f - fillAmount) * (productivityColors.Length - 1));
            productivityMeterFill.color = productivityColors[colorIndex];
        }

        if (productivityText != null)
        {
            productivityText.text = $"Productivity: {Mathf.FloorToInt(productivity)}%";
        }
    }

    public void ShowMeeting(string agenda, string phrase)
    {
        meetingText.text = $"MEETING\n\nAgenda: {agenda}\n\n{phrase}";
        StartCoroutine(FadeInPanel(meetingPanel, meetingGroup));
        PlaySound(meetingSound);
    }

    public void ShowKPI(string metric)
    {
        kpiText.text = metric;
        StartCoroutine(FadeInPanel(kpiPanel, kpiGroup));
        PlaySound(kpiSound);

        if (synergyParticles != null)
        {
            synergyParticles.Play();
        }
    }

    public void UpdateSystemStability(float stability)
    {
        if (systemStabilityFill != null)
        {
            float fillAmount = stability / 100f;
            systemStabilityFill.fillAmount = fillAmount;
            
            // Update color based on stability level
            int colorIndex = Mathf.FloorToInt((1f - fillAmount) * (stabilityColors.Length - 1));
            systemStabilityFill.color = stabilityColors[colorIndex];
        }

        if (systemStabilityText != null)
        {
            systemStabilityText.text = $"System Stability: {Mathf.FloorToInt(stability)}%";
        }
    }

    public void ShowError(string error)
    {
        errorText.text = error;
        StartCoroutine(FadeInPanel(errorPanel, errorGroup));
        PlaySound(errorSound);

        if (errorParticles != null)
        {
            errorParticles.Play();
        }
    }

    public void ShowTicket(string ticket)
    {
        ticketText.text = ticket;
        StartCoroutine(FadeInPanel(ticketPanel, ticketGroup));
        PlaySound(ticketSound);
    }

    public void ShowTroubleshooting(string step)
    {
        troubleshootingText.text = step;
        StartCoroutine(FadeInPanel(troubleshootingPanel, troubleshootingGroup));
        PlaySound(troubleshootingSound);
    }

    public void ShowBlueScreen()
    {
        if (blueScreenParticles != null)
        {
            blueScreenParticles.Play();
        }
    }

    private void SetPanelVisibility(GameObject panel, bool visible)
    {
        if (panel != null)
        {
            panel.SetActive(visible);
        }
    }

    private void PlaySound(AudioClip clip)
    {
        if (audioSource != null && clip != null)
        {
            audioSource.PlayOneShot(clip);
        }
    }

    private System.Collections.IEnumerator FadeInPanel(GameObject panel, CanvasGroup group)
    {
        SetPanelVisibility(panel, true);
        group.alpha = 0f;

        float duration = 0.5f;
        float elapsed = 0f;

        while (elapsed < duration)
        {
            group.alpha = Mathf.Lerp(0f, 1f, elapsed / duration);
            elapsed += Time.deltaTime;
            yield return null;
        }

        group.alpha = 1f;
        yield return new WaitForSeconds(3f);
        StartCoroutine(FadeOutPanel(panel, group));
    }

    private System.Collections.IEnumerator FadeOutPanel(GameObject panel, CanvasGroup group)
    {
        float duration = 0.5f;
        float elapsed = 0f;

        while (elapsed < duration)
        {
            group.alpha = Mathf.Lerp(1f, 0f, elapsed / duration);
            elapsed += Time.deltaTime;
            yield return null;
        }

        group.alpha = 0f;
        SetPanelVisibility(panel, false);
    }

    private System.Collections.IEnumerator FadeInOutImage(Image image, float duration)
    {
        float halfDuration = duration / 2f;
        float elapsed = 0f;

        // Fade in
        while (elapsed < halfDuration)
        {
            image.color = new Color(1f, 1f, 1f, Mathf.Lerp(0f, 1f, elapsed / halfDuration));
            elapsed += Time.deltaTime;
            yield return null;
        }

        image.color = new Color(1f, 1f, 1f, 1f);
        yield return new WaitForSeconds(halfDuration);

        // Fade out
        elapsed = 0f;
        while (elapsed < halfDuration)
        {
            image.color = new Color(1f, 1f, 1f, Mathf.Lerp(1f, 0f, elapsed / halfDuration));
            elapsed += Time.deltaTime;
            yield return null;
        }

        image.color = new Color(1f, 1f, 1f, 0f);
    }
} 