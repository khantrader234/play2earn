using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class NormieMentalState : MonoBehaviour
{
    [Header("Existential Parameters")]
    [SerializeField] private float mentalStability = 100f;
    [SerializeField] private float tearProductionRate = 1f;
    [SerializeField] private int wavesSurvivedBeforeBreakdown = 0;
    [SerializeField] private float coffeeAddiction = 0f;
    [SerializeField] private float existentialCrisisLevel = 0f;

    [Header("Tear Physics")]
    [SerializeField] private GameObject tearPrefab;
    [SerializeField] private float tearViscosity = 0.5f;
    [SerializeField] private float puddleFormationThreshold = 5f;
    [SerializeField] private GameObject coffeeStainPrefab;

    // List of increasingly concerning dialog options
    private readonly string[] phaseOneDialog = new string[]
    {
        "WHY DO WE KEEP DOING THIS?",
        "I DIDN'T SIGN UP FOR THIS!",
        "IS THIS WHAT GAME DEVELOPMENT HAS BECOME?"
    };

    private readonly string[] phaseTwoDialog = new string[]
    {
        "*[KEYBOARD SMASHING INTENSIFIES]*",
        "ASDFJKL;ASDFJKL;",
        "404: SANITY NOT FOUND"
    };

    private readonly string[] phaseThreeDialog = new string[]
    {
        "*Windows XP shutdown sound*",
        "CTRL+ALT+DEFEAT",
        "TASK FAILED SUCCESSFULLY"
    };

    private List<GameObject> depressionPuddles = new List<GameObject>();
    private AudioSource windowsErrorSound;
    private int currentPhase = 1;

    void Start()
    {
        // Initialize with concerning levels of enthusiasm
        windowsErrorSound = GetComponent<AudioSource>();
        StartCoroutine(ProduceTears());
        StartCoroutine(PostExistentialTweets());
        StartCoroutine(CoffeeAddictionCycle());
    }

    IEnumerator ProduceTears()
    {
        while (mentalStability > 0)
        {
            // Spawn tears with physics that definitely won't break the game
            Vector3 tearPosition = transform.position + Random.insideUnitSphere;
            GameObject tear = Instantiate(tearPrefab, tearPosition, Quaternion.identity);
            
            // Apply emotional force
            Rigidbody2D tearRb = tear.GetComponent<Rigidbody2D>();
            tearRb.AddForce(Vector2.down * (1f / mentalStability), ForceMode2D.Impulse);

            // Check for puddle formation (because misery loves company)
            CheckPuddleFormation(tear);

            yield return new WaitForSeconds(1f / tearProductionRate);
        }
    }

    void CheckPuddleFormation(GameObject tear)
    {
        // Count nearby tears for puddle formation
        Collider2D[] nearbyTears = Physics2D.OverlapCircleAll(tear.transform.position, 1f);
        if (nearbyTears.Length >= puddleFormationThreshold)
        {
            CreateDepressionPuddle(tear.transform.position);
        }
    }

    void CreateDepressionPuddle(Vector3 position)
    {
        // Create a puddle of pure sadness
        GameObject puddle = new GameObject("DepressionPuddle");
        puddle.transform.position = position;
        
        // Add collider that slows down enemies (and player's will to continue)
        CircleCollider2D puddleCollider = puddle.AddComponent<CircleCollider2D>();
        puddleCollider.isTrigger = true;
        
        depressionPuddles.Add(puddle);
    }

    IEnumerator PostExistentialTweets()
    {
        while (true)
        {
            // Post increasingly concerning tweets at 3 AM
            if (System.DateTime.Now.Hour == 3)
            {
                string[] currentDialogPool = currentPhase == 1 ? phaseOneDialog :
                                           currentPhase == 2 ? phaseTwoDialog :
                                           phaseThreeDialog;

                string tweet = currentDialogPool[Random.Range(0, currentDialogPool.Length)];
                Debug.Log($"@NormieDevs: {tweet} #GameDev #Help");
            }
            yield return new WaitForSeconds(60f); // Check every minute
        }
    }

    IEnumerator CoffeeAddictionCycle()
    {
        while (true)
        {
            // Increase coffee addiction over time
            coffeeAddiction += 0.1f;
            
            // Create coffee stains randomly
            if (Random.value < 0.1f)
            {
                CreateCoffeeStain();
            }

            // Effects of coffee addiction
            if (coffeeAddiction > 50f)
            {
                tearProductionRate *= 1.1f;
                mentalStability -= 0.5f;
            }

            yield return new WaitForSeconds(10f);
        }
    }

    void CreateCoffeeStain()
    {
        Vector3 stainPosition = transform.position + Random.insideUnitSphere * 2f;
        GameObject stain = Instantiate(coffeeStainPrefab, stainPosition, Quaternion.identity);
        
        // Make coffee stains slippery
        CircleCollider2D stainCollider = stain.AddComponent<CircleCollider2D>();
        stainCollider.isTrigger = true;
        
        // Add physics material for slipperiness
        PhysicsMaterial2D slippery = new PhysicsMaterial2D("Slippery");
        slippery.friction = 0.1f;
        stainCollider.sharedMaterial = slippery;
    }

    public void OnWaveCompleted()
    {
        wavesSurvivedBeforeBreakdown++;
        mentalStability -= 10f;
        existentialCrisisLevel += 15f;

        // Update phase based on mental stability
        if (wavesSurvivedBeforeBreakdown >= 5)
        {
            currentPhase = 2;
        }
        if (wavesSurvivedBeforeBreakdown >= 8)
        {
            currentPhase = 3;
            StartCoroutine(PlayWindowsErrors());
        }

        // Trigger existential crisis effects
        if (existentialCrisisLevel > 50f)
        {
            StartCoroutine(ExistentialCrisisEffects());
        }
    }

    IEnumerator PlayWindowsErrors()
    {
        // Play Windows error sounds in a way that questions reality
        while (currentPhase == 3)
        {
            windowsErrorSound.pitch = Random.Range(0.5f, 2f);
            windowsErrorSound.Play();
            yield return new WaitForSeconds(Random.Range(0.1f, 0.5f));
        }
    }

    IEnumerator ExistentialCrisisEffects()
    {
        // Randomly invert controls
        if (Random.value < 0.3f)
        {
            InvertControls();
            yield return new WaitForSeconds(5f);
            RestoreControls();
        }

        // Randomly change gravity
        if (Random.value < 0.2f)
        {
            Physics2D.gravity *= -1;
            yield return new WaitForSeconds(3f);
            Physics2D.gravity *= -1;
        }

        // Randomly spawn existential questions
        if (Random.value < 0.4f)
        {
            SpawnExistentialQuestion();
        }
    }

    void InvertControls()
    {
        // Invert player controls temporarily
        // This would need to be connected to your player controller
        Debug.Log("Controls inverted! Good luck with that!");
    }

    void RestoreControls()
    {
        // Restore normal controls
        Debug.Log("Controls restored. For now...");
    }

    void SpawnExistentialQuestion()
    {
        string[] questions = new string[]
        {
            "What is the meaning of game development?",
            "Why do we keep respawning?",
            "Is this real life?",
            "What happens when the game ends?",
            "Am I just a collection of pixels?"
        };

        string question = questions[Random.Range(0, questions.Length)];
        Debug.Log($"EXISTENTIAL QUESTION: {question}");
    }

    void OnTriggerEnter2D(Collider2D other)
    {
        if (other.CompareTag("Enemy"))
        {
            // Slow down enemies in depression puddles
            other.GetComponent<Rigidbody2D>().drag *= 2f;
        }
    }

    void OnTriggerExit2D(Collider2D other)
    {
        if (other.CompareTag("Enemy"))
        {
            // Reset enemy speed (if they survive the existential crisis)
            other.GetComponent<Rigidbody2D>().drag /= 2f;
        }
    }
} 