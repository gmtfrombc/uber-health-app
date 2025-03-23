import { SpeechClient, protos } from "@google-cloud/speech";

// Initialize Speech client
const speechClient = new SpeechClient();

// Configure speech-to-text settings
const speechToTextConfig: protos.google.cloud.speech.v1.IRecognitionConfig = {
    encoding: "LINEAR16",
    model: "medical_dictation",
    enableAutomaticPunctuation: true,
    maxAlternatives: 1,
};

export { speechClient, speechToTextConfig }; 