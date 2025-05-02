using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;

public class CodeReviewNightmares : MonoBehaviour
{
    [Header("UI Elements")]
    [SerializeField] private UIManager uiManager;
    
    [Header("Timing")]
    [SerializeField] private float minTimeBetweenReviews = 30f;
    [SerializeField] private float maxTimeBetweenReviews = 120f;
    
    private AudioSource audioSource;
    private int reviewCount = 0;
    
    // Lists of increasingly absurd code review comments
    private readonly string[] reviewComments = new string[]
    {
        "This code smells worse than my coffee after 3 all-nighters",
        "Have you considered using quantum computing for this?",
        "This function is more complex than my relationship with my ex",
        "The indentation here is giving me existential dread",
        "This variable name is longer than my last relationship",
        "Your code is so bad, it made my IDE cry",
        "This is the programming equivalent of giving a cat a bath",
        "I've seen better code in a fortune cookie",
        "This function is more convoluted than my life choices",
        "Your code is like a horror movie - full of jump scares"
    };

    // List of increasingly ridiculous bug reports
    private readonly string[] bugReports = new string[]
    {
        "Game crashes when player thinks about their life choices",
        "Character's tears are causing memory leaks",
        "The existential crisis feature is too realistic",
        "Player's depression puddles are too wet",
        "Windows error sounds are too comforting",
        "Therapy DLC is working as intended (this is a bug)",
        "Game is too self-aware",
        "Player's mental state is affecting the physics engine",
        "The fourth wall is too broken",
        "Game is making too much sense"
    };

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        StartCoroutine(RandomCodeReviews());
    }

    IEnumerator RandomCodeReviews()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(minTimeBetweenReviews, maxTimeBetweenReviews));
            ShowCodeReview();
        }
    }

    void ShowCodeReview()
    {
        reviewCount++;
        
        // Get random review comment and bug report
        string review = reviewComments[Random.Range(0, reviewComments.Length)];
        string bug = bugReports[Random.Range(0, bugReports.Length)];
        
        // Add increasingly concerning prefixes
        string prefix = reviewCount switch
        {
            > 10 => "URGENT: ",
            > 5 => "IMPORTANT: ",
            _ => "FYI: "
        };

        // Use UI manager to show the review
        uiManager.ShowCodeReview(prefix + review, "BUG REPORT: " + bug);
    }

    // Easter egg for developers
    void OnEnable()
    {
        if (Application.isEditor)
        {
            Debug.Log("You're reading the source code? That's meta.");
        }
    }
} 