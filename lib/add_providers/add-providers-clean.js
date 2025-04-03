const admin = require('firebase-admin');

// NOTE: This script is an example of how to add physical therapist providers to Firebase
// To use it, you need to:
// 1. Download a service account key from Firebase console
// 2. Save it as serviceAccountKey.json in this directory (which is gitignored)
// 3. Run the script with: node add-providers-clean.js

// SECURITY WARNING: Never commit your service account key to Git
// The .gitignore is set up to prevent this, but always double check!

// Initialize Firebase Admin with service account
admin.initializeApp({
  // Using your existing service account key
  credential: admin.credential.cert(require('./uber-health-app-8200a95aff26.json'))
});

// Physical Therapist provider data structure to add to Firestore
const physicalTherapists = [
  {
    firstname: 'Michael',
    lastname: 'Peterson',
    email: 'michael.peterson@example.com',
    credentials: 'DPT',
    specialty: 'Orthopedic Physical Therapy',
    bio: 'Specializing in sports injuries and post-surgical rehabilitation with 8 years of experience',
    languages: ['English', 'Spanish'],
    isAvailable: true,
    providerType: 'physicalTherapist',
    cost: 120.00,
    waitTime: '5-10 minutes',
  },
  {
    firstname: 'Sophia',
    lastname: 'Chen',
    email: 'sophia.chen@example.com',
    credentials: 'DPT, OCS',
    specialty: 'Neurological Rehabilitation',
    bio: 'Board-certified specialist in neurological physical therapy with experience in stroke and TBI recovery',
    languages: ['English', 'Mandarin'],
    isAvailable: true,
    providerType: 'physicalTherapist',
    cost: 130.00,
    waitTime: '10 minutes',
  },
  {
    firstname: 'James',
    lastname: 'Wilson',
    email: 'james.wilson@example.com',
    credentials: 'DPT, CSCS',
    specialty: 'Sports Physical Therapy',
    bio: 'Certified strength and conditioning specialist focusing on athletic performance and injury prevention',
    languages: ['English'],
    isAvailable: true,
    providerType: 'physicalTherapist',
    cost: 125.00,
    waitTime: '5-15 minutes',
  }
];

// Function to add physical therapists to Firestore
const addPhysicalTherapists = async () => {
  const db = admin.firestore();

  for (const therapist of physicalTherapists) {
    // Generate a document reference in the providers collection
    const docRef = await db.collection('providers').add({
      ...therapist,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Added physical therapist: ${therapist.firstname} ${therapist.lastname} with ID: ${docRef.id}`);
  }
  console.log('All physical therapists added successfully!');
  process.exit(0);
};

// Run the function
addPhysicalTherapists().catch(error => {
  console.error('Error adding physical therapists:', error);
  process.exit(1);
});

console.log("Adding physical therapists to Firebase..."); 