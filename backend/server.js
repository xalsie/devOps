const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { MongoClient, ObjectId } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/devops';
const DB_NAME = 'devops';

let fakeDatabase = {
  users: [
    { 
      _id: new ObjectId(), 
      name: 'John Doe', 
      email: 'john@example.com', 
      createdAt: new Date() 
    },
    { 
      _id: new ObjectId(), 
      name: 'Jane Smith', 
      email: 'jane@example.com', 
      createdAt: new Date() 
    }
  ]
};

let mongoClient;
let db;

app.use(helmet());
app.use(cors({
  origin: [
    process.env.FRONTEND_URL || 'http://localhost:5000',
    'http://localhost:8080',
    'http://localhost:3000'
  ],
  credentials: true
}));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use(limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

async function connectToDatabase() {
  try {
    if (process.env.USE_REAL_MONGODB === 'true') {
      mongoClient = new MongoClient(MONGODB_URI);
      await mongoClient.connect();
      db = mongoClient.db(DB_NAME);
      console.log('✅ Connecté à MongoDB');
    } else {
      console.log('⚠️  Utilisation de la fausse base de données en mémoire');
    }
  } catch (error) {
    console.error('❌ Erreur de connexion MongoDB:', error);
    console.log('⚠️  Utilisation de la fausse base de données en mémoire');
  }
}

function getCollection(collectionName) {
  if (db) {
    return db.collection(collectionName);
  }
  return null;
}


app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    database: db ? 'MongoDB' : 'Fake Database',
    version: process.env.npm_package_version || '1.0.0'
  });
});

app.get('/api/users', async (req, res) => {
  try {
    let users;
    
    if (db) {
      const collection = getCollection('users');
      users = await collection.find({}).toArray();
    } else {
      users = fakeDatabase.users;
    }
    
    res.json(users);
  } catch (error) {
    console.error('Erreur lors de la récupération des utilisateurs:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    
    if (!name || !email) {
      return res.status(400).json({ error: 'Nom et email requis' });
    }
    
    const newUser = {
      name,
      email,
      createdAt: new Date()
    };
    
    if (db) {
      const collection = getCollection('users');
      const result = await collection.insertOne(newUser);
      newUser._id = result.insertedId;
    } else {
      newUser._id = new ObjectId();
      fakeDatabase.users.push(newUser);
    }
    
    res.status(201).json(newUser);
  } catch (error) {
    console.error('Erreur lors de la création de l\'utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'ID invalide' });
    }
    
    let user;
    
    if (db) {
      const collection = getCollection('users');
      user = await collection.findOne({ _id: new ObjectId(id) });
    } else {
      user = fakeDatabase.users.find(u => u._id.toString() === id);
    }
    
    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.put('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email } = req.body;
    
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'ID invalide' });
    }
    
    if (!name || !email) {
      return res.status(400).json({ error: 'Nom et email requis' });
    }
    
    const updateData = {
      name,
      email,
      updatedAt: new Date()
    };
    
    let user;
    
    if (db) {
      const collection = getCollection('users');
      const result = await collection.findOneAndUpdate(
        { _id: new ObjectId(id) },
        { $set: updateData },
        { returnDocument: 'after' }
      );
      user = result.value;
    } else {
      const userIndex = fakeDatabase.users.findIndex(u => u._id.toString() === id);
      if (userIndex === -1) {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }
      fakeDatabase.users[userIndex] = { ...fakeDatabase.users[userIndex], ...updateData };
      user = fakeDatabase.users[userIndex];
    }
    
    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Erreur lors de la mise à jour de l\'utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.delete('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'ID invalide' });
    }
    
    let result;
    
    if (db) {
      const collection = getCollection('users');
      result = await collection.deleteOne({ _id: new ObjectId(id) });
      
      if (result.deletedCount === 0) {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }
    } else {
      const userIndex = fakeDatabase.users.findIndex(u => u._id.toString() === id);
      if (userIndex === -1) {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }
      fakeDatabase.users.splice(userIndex, 1);
    }
    
    res.json({ message: 'Utilisateur supprimé avec succès' });
  } catch (error) {
    console.error('Erreur lors de la suppression de l\'utilisateur:', error);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route non trouvée' });
});

app.use((error, req, res, next) => {
  console.error('Erreur non gérée:', error);
  res.status(500).json({ error: 'Erreur serveur interne' });
});

async function startServer() {
  await connectToDatabase();
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Serveur API démarré sur le port ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`🔗 API URL: http://localhost:${PORT}/api`);
  });
}

process.on('SIGINT', async () => {
  console.log('\n⏹️  Arrêt du serveur...');
  if (mongoClient) {
    await mongoClient.close();
    console.log('🔒 Connexion MongoDB fermée');
  }
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n⏹️  Arrêt du serveur...');
  if (mongoClient) {
    await mongoClient.close();
    console.log('🔒 Connexion MongoDB fermée');
  }
  process.exit(0);
});

startServer().catch(console.error);

module.exports = app;
