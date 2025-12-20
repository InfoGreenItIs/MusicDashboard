const admin = require('firebase-admin');

// Initialize Firebase Admin with Application Default Credentials
// This works automatically if you have run 'gcloud auth application-default login'
// Otherwise, you will need to point to a service account key file.
try {
  admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: 'musicdashboard-6fddb' // Your project ID
  });
} catch (e) {
  // If no default creds, try to load from a local service account key file if present (optional fallback)
  console.log("Could not initialize with Application Default Credentials. Checking for service-account.json...");
  try {
     const serviceAccount = require('./service-account.json');
     admin.initializeApp({
       credential: admin.credential.cert(serviceAccount)
     });
  } catch(e2) {
     console.error("Failed to initialize Firebase Admin. Please run 'gcloud auth application-default login' first.");
     console.error(e);
     process.exit(1);
  }
}

const db = admin.firestore();

const users = [
  'dvmaren@gmail.com',
  'mike.vanderlans@gmail.com'
];

async function seed() {
  console.log('Seeding database users...');
  
  for (const email of users) {
    await db.collection('dashboard_users').doc(email).set({
      email: email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      role: 'admin' 
    });
    console.log(`✅ Added/Updated: ${email}`);
  }
  
  console.log('Database seeding complete!');
}

seed().catch(console.error);
