import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { OpenAI } from "openai";

// Initialize Firebase admin
admin.initializeApp();

/**
 * Generates an AI response using OpenAI's API
 */
export const generateAIResponse = functions.https.onCall(async (data: any, context: any) => {
    try {
        // Verify authentication
        // if (!context.auth) {
        //     throw new Error("User must be authenticated to use this feature");
        // }

        // Get OpenAI API key from environment
        const apiKey = process.env.OPENAI_API_KEY;
        if (!apiKey) {
            console.error("OpenAI API key not configured");
            throw new Error("OpenAI API key not configured");
        }

        console.log('OpenAI API key found in environment variables');

        // Log only the keys to avoid circular structure issues
        let dataKeys = [];
        if (data) {
            dataKeys = Object.keys(data);
        }
        console.log('Received request with data keys:', dataKeys);

        // Check if data exists and contains messages
        if (!data) {
            console.error('No data provided');
            throw new Error("No request data provided");
        }

        // Try to handle different possible message formats
        let messages;
        if (data.messages) {
            messages = data.messages;
            console.log('Found messages directly in data');
        } else if (data.data && data.data.messages) {
            messages = data.data.messages;
            console.log('Found messages in data.data');
        } else {
            console.error('No messages found in request. Data keys:', dataKeys);
            throw new Error("Missing messages data");
        }

        if (!Array.isArray(messages)) {
            console.error('Messages is not an array:', typeof messages);
            throw new Error("Messages must be an array");
        }

        console.log('Message count:', messages.length);

        // Try to fix message format if needed
        const formattedMessages = messages.map(msg => {
            // Create a new message object with just role and content
            return {
                role: msg.role || 'user',
                content: msg.content || ''
            };
        });

        console.log('Formatted messages:', formattedMessages.length);

        const openaiClient = new OpenAI({ apiKey });

        const completion = await openaiClient.chat.completions.create({
            model: "gpt-4o",
            messages: formattedMessages,
            temperature: data.temperature || 0.7,
            max_tokens: data.maxTokens || 150,
        });

        const aiResponse = completion.choices[0]?.message?.content;
        if (!aiResponse) {
            throw new Error("Failed to generate AI response");
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
export const generateMedicalSummary = functions.https.onCall(async (data: any, context: any) => {
    try {
        // Verify authentication
        // if (!context.auth) {
        //     throw new Error("User must be authenticated to use this feature");
        // }

        const { messages: chatMessages, patientData, category, providerType } = data;

        // Get OpenAI API key from environment
        const apiKey = process.env.OPENAI_API_KEY;
        if (!apiKey) {
            console.error("OpenAI API key not configured");
            throw new Error("OpenAI API key not configured");
        }

        console.log('OpenAI API key found in environment variables');
        const openaiClient = new OpenAI({ apiKey });

        if (!chatMessages || !Array.isArray(chatMessages)) {
            throw new Error("Invalid messages format");
        }

        // Create system prompt
        const systemPrompt = `
        You are a medical AI assistant tasked with creating professional medical summaries.
        Based on the conversation, extract patient information and format it as a concise medical summary.
        Focus on key details related to the patient's symptoms, medical history, and current condition.
        Consider the specific category (${category}) and provider type (${providerType}) when creating this summary.
        Your summary will be used by healthcare providers to quickly understand the patient's situation.
        `;

        const systemMessage = {
            role: "system",
            content: systemPrompt,
        };

        // Combine messages
        const openaiMessages = [
            systemMessage,
            ...chatMessages,
        ];

        const completion = await openaiClient.chat.completions.create({
            model: "gpt-4o",
            messages: openaiMessages,
            temperature: 0.3,
        });

        const aiResponse = completion.choices[0]?.message?.content;
        if (!aiResponse) {
            throw new Error("Failed to generate medical summary");
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