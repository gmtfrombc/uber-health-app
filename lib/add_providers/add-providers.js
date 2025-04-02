const admin = require('firebase-admin');
const serviceAccount = require('./uber-health-app-firebase-adminsdk-fbsvc-406cdd60c9.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }
];

// Add each provider to the 'providers' collection
const addProviders = async () => {
    for (const provider of providers) {
        // Generate a random ID if needed, or you could use the email as a unique identifier
        const docRef = await db.collection('providers').add(provider);
        console.log(`Added provider: ${provider.firstname} ${provider.lastname} with ID: ${docRef.id}`);
    }
    console.log('All providers added successfully!');
    process.exit(0);
};

addProviders().catch(error => {
    console.error('Error adding providers:', error);
    process.exit(1);
}); 