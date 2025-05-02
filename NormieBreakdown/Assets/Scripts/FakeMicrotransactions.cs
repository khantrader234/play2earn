using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Collections.Generic;

public class FakeMicrotransactions : MonoBehaviour
{
    [Header("UI Elements")]
    [SerializeField] private Button therapyDLCButton;
    [SerializeField] private Text priceText;
    [SerializeField] private GameObject processingPanel;
    [SerializeField] private GameObject errorPanel;
    
    [Header("Fake Store Data")]
    [SerializeField] private float basePrice = 9.99f;
    [SerializeField] private float priceIncreaseRate = 1.5f;
    
    private int purchaseAttempts = 0;
    private bool isProcessing = false;

    // List of increasingly expensive therapy options
    private readonly string[] therapyTiers = new string[]
    {
        "Basic Emotional Support",
        "Premium Coping Mechanisms",
        "Deluxe Mental Stability Pack",
        "Ultimate Inner Peace Bundle",
        "Transcendent Enlightenment Suite"
    };

    // Fake error messages
    private readonly string[] errorMessages = new string[]
    {
        "Error: Therapy machine broke",
        "Unable to process: Too many emotional baggage",
        "Transaction failed: Inner peace not found",
        "404: Mental stability not found",
        "Error: Server is having an existential crisis"
    };

    void Start()
    {
        UpdatePrice();
        therapyDLCButton.onClick.AddListener(OnTherapyButtonClick);
    }

    void UpdatePrice()
    {
        // Increase price with each attempt
        float currentPrice = basePrice * Mathf.Pow(priceIncreaseRate, purchaseAttempts);
        string tierName = therapyTiers[Mathf.Min(purchaseAttempts, therapyTiers.Length - 1)];
        
        priceText.text = $"{tierName}\n${currentPrice:F2}";
    }

    public void OnTherapyButtonClick()
    {
        if (isProcessing) return;
        StartCoroutine(ProcessFakeTransaction());
    }

    IEnumerator ProcessFakeTransaction()
    {
        isProcessing = true;
        processingPanel.SetActive(true);
        
        // Show fake loading messages
        string[] loadingMessages = new string[]
        {
            "Connecting to therapy server...",
            "Analyzing mental state...",
            "Calculating emotional damage...",
            "Preparing coping mechanisms...",
            "Downloading virtual hugs..."
        };

        foreach (string message in loadingMessages)
        {
            Debug.Log(message);
            yield return new WaitForSeconds(Random.Range(0.5f, 1.5f));
        }

        processingPanel.SetActive(false);

        // Always fail with a random error
        ShowError(errorMessages[Random.Range(0, errorMessages.Length)]);
        
        purchaseAttempts++;
        UpdatePrice();
        
        // Add special messages for persistent players
        if (purchaseAttempts >= 5)
        {
            StartCoroutine(ShowPersistenceMessage());
        }

        isProcessing = false;
    }

    void ShowError(string message)
    {
        errorPanel.GetComponentInChildren<Text>().text = message;
        errorPanel.SetActive(true);
        StartCoroutine(AutoHideError());
    }

    IEnumerator AutoHideError()
    {
        yield return new WaitForSeconds(3f);
        errorPanel.SetActive(false);
    }

    IEnumerator ShowPersistenceMessage()
    {
        string[] persistenceMessages = new string[]
        {
            "You really want that therapy, huh?",
            "Have you tried turning your brain off and on again?",
            "Maybe the real therapy was the errors we made along the way",
            "Fun fact: This button will never work",
            "*Concerned developer noises*"
        };

        yield return new WaitForSeconds(1f);
        Debug.Log(persistenceMessages[Random.Range(0, persistenceMessages.Length)]);
    }

    // Easter egg for players who try to hack the system
    void OnEnable()
    {
        if (Application.isEditor)
        {
            Debug.Log("Nice try, but you can't debug your way to mental stability!");
        }
    }
} 