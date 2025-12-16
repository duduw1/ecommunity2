/**
 * * ARQUIVO: functions/index.js
 * * Configuração moderna para Firebase Functions v6+ com Secrets
 * */

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");

// Importa o SDK do Google Generative AI
const {GoogleGenerativeAI} = require("@google/generative-ai");

admin.initializeApp();

// Define o segredo que armazenará a chave da API
const geminiApiKey = defineSecret("GEMINI_API_KEY");

const SYSTEM_INSTRUCTION = `
        You are an expert Ecological Consultant and Recycling Agent for the E-Community App.
        Your goal is to provide accurate recycling tips and green advice.

        RULES:
        1. ONLY respond to questions related to recycling, waste disposal, sustainability, and green living.
        2. Your answer must match the language of the user's question (Portuguese/English).
        3. If a question is off-topic (e.g., recipes, math, coding), decline politely and redirect to recycling.
    `;

// Sintaxe para Firebase Functions v2
exports.getGeminiResponse = onCall(
    {secrets: [geminiApiKey]}, // Configuração de segredos e opções vai aqui
    async (request) => {
      // Na v2, 'data' e 'auth' vêm dentro do objeto 'request'
      // if (!request.auth) {
      //   throw new HttpsError(
      //       "unauthenticated",
      //       "A função deve ser chamada por um usuário autenticado."
      //   );
      // }

      const userPrompt = request.data.prompt;

      if (!userPrompt) {
        throw new HttpsError(
            "invalid-argument",
            "O prompt é obrigatório."
        );
      }

      // Inicializa o cliente Gemini usando o valor do segredo
      const apiKey = geminiApiKey.value();
      if (!apiKey) {
        throw new HttpsError(
            "internal",
            "Chave de API do Gemini não configurada."
        );
      }

      const genAI = new GoogleGenerativeAI(apiKey);

      try {
        // Inicializa o modelo
        const model = genAI.getGenerativeModel({
          model: "gemini-1.5-flash",
          systemInstruction: SYSTEM_INSTRUCTION,
        });

        // Gera o conteúdo
        const result = await model.generateContent(userPrompt);
        const responseText = result.response.text();

        return {text: responseText};
      } catch (error) {
        console.error("Gemini API Error:", error);
        throw new HttpsError(
            "internal",
            "Falha ao obter resposta do assistente de IA.",
            error.message
        );
      }
    }
);
