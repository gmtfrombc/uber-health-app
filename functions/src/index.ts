/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as admin from "firebase-admin";
import OpenAI from "openai";
import * as functions from "firebase-functions";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Initialize Firebase admin
admin.initializeApp();

// Define OpenAI message type
type OpenAIMessage = {
    role: "system" | "user" | "assistant";
    content: string;
};

/**
 * Utility function to get the OpenAI API key from various sources
 */
function getOpenAIAPIKey(): string {
    try {
        console.log('Trying to get OpenAI API key from various sources...');

        // Try to get from Firebase config
        const configKey = functions.config().openai?.api_key;
        console.log('Firebase config key:', configKey ? 'found' : 'not found');
        if (configKey) {
            console.log('Using API key from Firebase config');
            return configKey;
        }

        // Try to get from environment variables
        const envKey = process.env.OPENAI_API_KEY;
        console.log('Environment variable key:', envKey ? 'found' : 'not found');
        if (envKey) {
            console.log('Using API key from environment variables');
            return envKey;
        }

        console.log('No OpenAI API key found from any source');
        throw new Error('No OpenAI API key found');
    } catch (e) {
        console.error('Failed to get OpenAI API key:', e);
        throw new Error('No OpenAI API key found');
    }
}

/**
 * Generates an AI response using OpenAI's API
 */
export const generateAIResponse = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    try {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated to use this feature"
            );
        }

        // Get OpenAI API key
        let apiKey;

        // First, check if the API key was provided in the request data
        if (data.apiKey) {
            console.log('Using API key provided in request data');
            apiKey = data.apiKey;
        } else {
            try {
                apiKey = getOpenAIAPIKey();
            } catch (e) {
                throw new functions.https.HttpsError(
                    "failed-precondition",
                    "OpenAI API key not configured"
                );
            }
        }

        const openaiClient = new OpenAI({ apiKey });

        if (!data.messages || !Array.isArray(data.messages)) {
            throw new functions.https.HttpsError("invalid-argument", "Invalid messages format");
        }

        // Cast the messages to the type required by OpenAI
        const messages = data.messages as OpenAIMessage[];

        const completion = await openaiClient.chat.completions.create({
            model: "gpt-4o",
            messages: messages,
            temperature: data.temperature || 0.7,
            max_tokens: data.maxTokens || 150,
        });

        const aiResponse = completion.choices[0]?.message?.content;
        if (!aiResponse) {
            throw new functions.https.HttpsError("internal", "Failed to generate AI response");
        }

        return {
            success: true,
            content: aiResponse,
        };
    } catch (error) {
        console.error("Error in generateAIResponse:", error);
        return {
            success: false,
            error: error instanceof Error ? error.message : "Unknown error",
        };
    }
});

/**
 * Generates a medical summary based on patient data
 */
export const generateMedicalSummary = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
    try {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated to use this feature"
            );
        }

        // Get data from request
        const { messages: chatMessages, patientData, category, providerType, apiKey: requestApiKey } = data;

        // Get OpenAI API key
        let apiKey;

        // First, check if the API key was provided in the request data
        if (requestApiKey) {
            console.log('Using API key provided in request data');
            apiKey = requestApiKey;
        } else {
            try {
                apiKey = getOpenAIAPIKey();
            } catch (e) {
                throw new functions.https.HttpsError(
                    "failed-precondition",
                    "OpenAI API key not configured"
                );
            }
        }

        const openaiClient = new OpenAI({ apiKey });

        if (!chatMessages || !Array.isArray(chatMessages)) {
            throw new functions.https.HttpsError("invalid-argument", "Invalid messages format");
        }

        // Create system prompt
        const systemPrompt = `
        You are a medical AI assistant tasked with creating professional medical summaries.
        Based on the conversation, extract patient information and format it as a concise medical summary.
        Focus on key details related to the patient's symptoms, medical history, and current condition.
        Consider the specific category (${category}) and provider type (${providerType}) when creating this summary.
        Your summary will be used by healthcare providers to quickly understand the patient's situation.
        `;

        const systemMessage: OpenAIMessage = {
            role: "system",
            content: systemPrompt,
        };

        // Cast message array to OpenAIMessage type
        const userMessages = chatMessages as OpenAIMessage[];

        const openaiMessages: OpenAIMessage[] = [
            systemMessage,
            ...userMessages,
        ];

        const completion = await openaiClient.chat.completions.create({
            model: "gpt-4o",
            messages: openaiMessages,
            temperature: 0.3,
        });

        const aiResponse = completion.choices[0]?.message?.content;
        if (!aiResponse) {
            throw new functions.https.HttpsError("internal", "Failed to generate medical summary");
        }

        return {
            success: true,
            summary: aiResponse,
        };
    } catch (error) {
        console.error("Error in generateMedicalSummary:", error);
        return {
            success: false,
            error: error instanceof Error ? error.message : "Unknown error",
        };
    }
});
