const admin = require('firebase-admin');

// NOTE: This script is an example of how to add providers to Firebase
// To use it, you need to:
// 1. Download a service account key from Firebase console
// 2. Save it as serviceAccountKey.json in this directory
// 3. Run the script with: node add-providers.js

// SECURITY WARNING: Never commit your service account key to Git
// The .gitignore is set up to prevent this, but always double check!

/*
// Initialize Firebase Admin with service account (don't commit this)
admin.initializeApp({
  // Note: Replace with your own key file path - never commit this file to Git!
  credential: admin.credential.cert(require('./your-service-account-key.json'))
});
*/

// Provider data structure to add to Firestore
const providers = [
  {
    firstname: 'Alice',
    lastname: 'Smith',
    email: 'alice.smith@example.com',
    credentials: 'MD',
    specialty: 'Internal Medicine',
    bio: 'Board certified in Internal Medicine with 10 years of experience',
    languages: ['English', 'Spanish'],
    isAvailable: true,
    providerType: 'medicalProvider',
    cost: 150.00,
    waitTime: '5-10 minutes',
  },
  {
    firstname: 'Bob',
    lastname: 'Johnson',
    email: 'bob.johnson@example.com',
    credentials: 'NP',
    specialty: 'Family Practice',
    bio: 'Experienced family nurse practitioner specializing in pediatric and adult care',
    languages: ['English'],
    isAvailable: true,
    providerType: 'medicalProvider',
    cost: 100.00,
    waitTime: '5 minutes',
  },
  {
    firstname: 'Carol',
    lastname: 'Williams',
    email: 'carol.williams@example.com',
    credentials: 'PA-C',
    specialty: 'Dermatology',
    bio: 'Specializing in skin conditions and preventative dermatology care',
    languages: ['English', 'French'],
    isAvailable: true,
    providerType: 'medicalProvider',
    cost: 125.00,
    waitTime: '10-15 minutes',
  },
  {
    firstname: 'David',
    lastname: 'Brown',
    email: 'david.brown@example.com',
    credentials: 'MD',
    specialty: 'Cardiology',
    bio: 'Cardiologist with focus on preventative care and heart health',
    languages: ['English', 'Mandarin'],
    isAvailable: true,
    providerType: 'medicalProvider',
    cost: 200.00,
    waitTime: '15 minutes',
  }
];

// Example function to add providers to Firestore (commented out for safety)
/*
const addProviders = async () => {
  const db = admin.firestore();
  
  for (const provider of providers) {
    // Generate a random ID if needed, or you could use the email as a unique identifier
    const docRef = await db.collection('providers').add({
      ...provider,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Added provider: ${provider.firstname} ${provider.lastname} with ID: ${docRef.id}`);
  }
  console.log('All providers added successfully!');
  process.exit(0);
};

// Run the function
addProviders().catch(error => {
  console.error('Error adding providers:', error);
  process.exit(1);
});
*/

// This script is a template - run it after adding your own Firebase credentials
console.log("Provider template script - modify with your Firebase credentials to use"); 