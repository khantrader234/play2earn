using UnityEngine;
using System.Collections;
using System.IO;
using UnityEngine.UI;
using System.Diagnostics;
using Debug = UnityEngine.Debug;

public class PunishingGameDesign : MonoBehaviour
{
    [Header("Life Choices")]
    [SerializeField] private int deathCount = 0;
    [SerializeField] private float totalPlaytime = 0f;
    [SerializeField] private GameObject callMomPrompt;
    [SerializeField] private AudioClip sadTromboneSound;
    [SerializeField] private GameObject achievementPanel;
    [SerializeField] private Text achievementText;
    
    [Header("UI Elements")]
    [SerializeField] private Text playtimeText;
    [SerializeField] private GameObject uninstallWarning;
    [SerializeField] private GameObject updateNotification;
    [SerializeField] private Text updateText;
    
    private AudioSource audioSource;
    private bool hasCalledMom = false;
    private readonly float maxPlaytime = 21600f; // 6 hours in seconds
    private int achievementCount = 0;

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
        LoadGameStats();
        StartCoroutine(TrackPlaytime());
        StartCoroutine(CheckPlayerMentalHealth());
        StartCoroutine(FakeUpdates());
    }

    IEnumerator FakeUpdates()
    {
        while (true)
        {
            yield return new WaitForSeconds(Random.Range(300f, 900f)); // Every 5-15 minutes
            
            string[] updateMessages = new string[]
            {
                "New Update: Added more bugs!",
                "Patch Notes: Removed fun",
                "Update: Now with 200% more existential dread",
                "Hotfix: Fixed player's will to live",
                "Update: Added more microtransactions",
                "Patch: Removed all hope",
                "Update: Now with more coffee stains!",
                "Hotfix: Fixed the 'enjoyment' bug"
            };

            ShowUpdateNotification(updateMessages[Random.Range(0, updateMessages.Length)]);
        }
    }

    void ShowUpdateNotification(string message)
    {
        updateText.text = message;
        updateNotification.SetActive(true);
        StartCoroutine(HideUpdateNotification());
    }

    IEnumerator HideUpdateNotification()
    {
        yield return new WaitForSeconds(5f);
        updateNotification.SetActive(false);
    }

    public void OnPlayerDeath()
    {
        deathCount++;
        SaveGameStats();

        // Check for achievements
        CheckAchievements();

        // After 50 deaths, guilt trip the player
        if (deathCount >= 50 && !hasCalledMom)
        {
            ShowCallMomPrompt();
        }
    }

    void CheckAchievements()
    {
        string achievement = null;

        switch (deathCount)
        {
            case 10:
                achievement = "First Time?";
                break;
            case 25:
                achievement = "Getting the Hang of Dying";
                break;
            case 50:
                achievement = "Professional Corpse";
                break;
            case 100:
                achievement = "Death is Your Middle Name";
                break;
        }

        if (achievement != null)
        {
            ShowAchievement(achievement);
        }
    }

    void ShowAchievement(string achievement)
    {
        achievementCount++;
        achievementText.text = $"ACHIEVEMENT UNLOCKED: {achievement}\n({achievementCount}/4)";
        achievementPanel.SetActive(true);
        StartCoroutine(HideAchievement());
    }

    IEnumerator HideAchievement()
    {
        yield return new WaitForSeconds(3f);
        achievementPanel.SetActive(false);
    }

    void ShowCallMomPrompt()
    {
        callMomPrompt.SetActive(true);
        StartCoroutine(ShowGuiltyMessages());
    }

    IEnumerator ShowGuiltyMessages()
    {
        string[] guiltyMessages = new string[]
        {
            "Your mom misses you...",
            "When was the last time you called?",
            "She just wants to know if you're eating well",
            "Dad asks about you too (but won't admit it)",
            "*Sends childhood photo*"
        };

        foreach (string message in guiltyMessages)
        {
            Debug.Log($"Mom's Phone: {message}");
            yield return new WaitForSeconds(5f);
        }
    }

    IEnumerator TrackPlaytime()
    {
        while (true)
        {
            totalPlaytime += Time.deltaTime;
            UpdatePlaytimeUI();

            // Check for 6-hour mark
            if (totalPlaytime >= maxPlaytime)
            {
                StartSelfUninstall();
            }

            yield return null;
        }
    }

    void UpdatePlaytimeUI()
    {
        int hours = Mathf.FloorToInt(totalPlaytime / 3600f);
        int minutes = Mathf.FloorToInt((totalPlaytime % 3600f) / 60f);
        
        if (hours >= 5)
        {
            playtimeText.color = Color.red;
            playtimeText.text = $"Time Wasted: {hours}h {minutes}m";
        }
        else
        {
            playtimeText.text = $"Time Played: {hours}h {minutes}m";
        }
    }

    IEnumerator CheckPlayerMentalHealth()
    {
        while (true)
        {
            // Send concerning notifications
            if (totalPlaytime > 7200f) // After 2 hours
            {
                string[] notifications = new string[]
                {
                    "Normie (💔): pls stop playing",
                    "Normie (😢): this isn't healthy",
                    "Normie (🤖): beep boop your life is a loop"
                };

                Debug.Log(notifications[Random.Range(0, notifications.Length)]);
            }

            yield return new WaitForSeconds(300f); // Check every 5 minutes
        }
    }

    void StartSelfUninstall()
    {
        StartCoroutine(SelfUninstallSequence());
    }

    IEnumerator SelfUninstallSequence()
    {
        // Show dramatic warning
        uninstallWarning.SetActive(true);
        
        // Play sad trombone
        audioSource.clip = sadTromboneSound;
        audioSource.Play();

        yield return new WaitForSeconds(5f);

        // Get game directory
        string gameDir = Application.dataPath;
        gameDir = Directory.GetParent(gameDir).FullName;

        // Create batch file for uninstall
        string batchPath = Path.Combine(gameDir, "uninstall.bat");
        string batchContent = @"
            @echo off
            echo Normie has left the building...
            timeout /t 5
            rmdir /s /q """ + gameDir + @"""
        ";

        File.WriteAllText(batchPath, batchContent);

        // Execute batch file
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = batchPath;
        startInfo.UseShellExecute = true;
        Process.Start(startInfo);

        // Quit game
        Application.Quit();
    }

    void SaveGameStats()
    {
        PlayerPrefs.SetInt("DeathCount", deathCount);
        PlayerPrefs.SetFloat("TotalPlaytime", totalPlaytime);
        PlayerPrefs.Save();
    }

    void LoadGameStats()
    {
        deathCount = PlayerPrefs.GetInt("DeathCount", 0);
        totalPlaytime = PlayerPrefs.GetFloat("TotalPlaytime", 0f);
    }

    void OnApplicationQuit()
    {
        SaveGameStats();
    }
} 