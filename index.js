const express = require('express');
const app = express();
const port = 3000;

// In-memory storage (in a real app, you'd use a database)
const players = new Map();
const scores = [];
const apiKeys = new Map(); // Store API keys (in real app, use secure storage)

// Middleware to parse JSON bodies
app.use(express.json());

// Authentication middleware
const authenticateApiKey = (req, res, next) => {
    const apiKey = req.header('X-API-Key');
    if (!apiKey) {
        return res.status(401).json({ error: 'API key is required' });
    }
    
    const player = apiKeys.get(apiKey);
    if (!player) {
        return res.status(401).json({ error: 'Invalid API key' });
    }
    
    req.player = player; // Attach player to request
    next();
};

// Error handling middleware
const errorHandler = (err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        error: 'Something went wrong!',
        message: err.message 
    });
};

// Basic route
app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to Play2Earn API',
        status: 'Server is running',
        endpoints: {
            player: {
                create: 'POST /player',
                get: 'GET /player/:username',
            },
            scores: {
                submit: 'POST /score',
                highscores: 'GET /highscores',
                playerScores: 'GET /scores/:player'
            }
        }
    });
});

// Register new player and get API key
app.post('/register', (req, res) => {
    const { username, email, avatar } = req.body;
    
    // Validation
    if (!username || !email) {
        return res.status(400).json({ error: 'Username and email are required' });
    }
    
    if (players.has(username)) {
        return res.status(409).json({ error: 'Username already exists' });
    }
    
    // Create player profile
    const player = {
        username,
        email,
        avatar,
        createdAt: new Date().toISOString()
    };
    
    // Generate API key (in real app, use proper key generation)
    const apiKey = Buffer.from(`${username}-${Date.now()}`).toString('base64');
    
    players.set(username, player);
    apiKeys.set(apiKey, username);
    
    res.status(201).json({
        message: 'Registration successful',
        apiKey,
        player
    });
});

// Get player profile (requires authentication)
app.get('/player/:username', authenticateApiKey, (req, res) => {
    const { username } = req.params;
    
    if (!players.has(username)) {
        return res.status(404).json({ error: 'Player not found' });
    }
    
    // Only allow players to view their own profile or use admin key
    if (req.player !== username && req.player !== 'admin') {
        return res.status(403).json({ error: 'Access denied' });
    }
    
    res.json(players.get(username));
});

// Update player profile (requires authentication)
app.put('/player/:username', authenticateApiKey, (req, res) => {
    const { username } = req.params;
    const updates = req.body;
    
    if (!players.has(username)) {
        return res.status(404).json({ error: 'Player not found' });
    }
    
    // Only allow players to update their own profile
    if (req.player !== username) {
        return res.status(403).json({ error: 'Access denied' });
    }
    
    const player = players.get(username);
    const updatedPlayer = {
        ...player,
        ...updates,
        username, // Prevent username change
        createdAt: player.createdAt // Preserve creation date
    };
    
    players.set(username, updatedPlayer);
    res.json(updatedPlayer);
});

// Submit score (requires authentication)
app.post('/score', authenticateApiKey, (req, res) => {
    const { score } = req.body;
    const player = req.player;
    
    if (typeof score !== 'number' || score < 0) {
        return res.status(400).json({ error: 'Valid score is required' });
    }
    
    const scoreEntry = {
        player,
        score,
        timestamp: new Date().toISOString()
    };
    
    scores.push(scoreEntry);
    
    // Calculate player's rank
    const position = scores
        .filter(s => s.score > score)
        .length + 1;
    
    res.json({
        message: `Score recorded for ${player}: ${score}`,
        timestamp: scoreEntry.timestamp,
        rank: position
    });
});

// Get high scores with pagination
app.get('/highscores', (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    
    const startIndex = (page - 1) * limit;
    
    const topScores = [...scores]
        .sort((a, b) => b.score - a.score)
        .slice(startIndex, startIndex + limit)
        .map((score, index) => ({
            ...score,
            rank: startIndex + index + 1
        }));
    
    res.json({
        message: `High Scores (Page ${page})`,
        scores: topScores,
        pagination: {
            page,
            limit,
            total: scores.length,
            totalPages: Math.ceil(scores.length / limit)
        }
    });
});

// Get player's scores (requires authentication)
app.get('/scores/:player', authenticateApiKey, (req, res) => {
    const { player } = req.params;
    
    // Only allow players to view their own scores or use admin key
    if (req.player !== player && req.player !== 'admin') {
        return res.status(403).json({ error: 'Access denied' });
    }
    
    const playerScores = scores
        .filter(score => score.player === player)
        .sort((a, b) => b.score - a.score);
    
    res.json({
        player,
        totalGames: playerScores.length,
        highestScore: playerScores[0]?.score || 0,
        scores: playerScores
    });
});

// Add error handling middleware
app.use(errorHandler);

// Start the server
app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
    
    // Add admin API key for testing
    const adminKey = 'admin-key-123';
    apiKeys.set(adminKey, 'admin');
    console.log(`Admin API Key for testing: ${adminKey}`);
}); 