// 1. Importações
const functions = require('firebase-functions');
const { GoogleGenerativeAI } = require("@google/generative-ai"); // Correção da lib

// 2. Configuração segura da API Key
// Para rodar localmente ou deploy, use variáveis de ambiente.
// NUNCA deixe a chave hardcoded no arquivo como estava antes.
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || functions.config().gemini.key;

if (!GEMINI_API_KEY) {
    console.error("ERRO: Chave da API Gemini não encontrada.");
}

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

// 3. Definindo o endpoint HTTPS
exports.getGeminiResponse = functions.https.onCall(async (data, context) => {
    // Autenticação básica (Opcional, mas recomendada)
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'A função deve ser chamada por um usuário autenticado.'
        );
    }

    const userPrompt = data.prompt;

    if (!userPrompt) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'O prompt é obrigatório.'
        );
    }

    // Definição da "Persona" do Agente
    const systemInstruction = `
        You are an expert Ecological Consultant and Recycling Agent for the E-Community App.
        Your goal is to provide accurate recycling tips and green advice.

        RULES:
        1. ONLY respond to questions related to recycling, waste disposal, sustainability, and green living.
        2. Your answer must match the language of the user's question (Portuguese/English).
        3. If a question is off-topic (e.g., recipes, math, coding), decline politely and redirect to recycling.
    `;

    try {
        // Inicializa o modelo (use 'gemini-1.5-flash' ou 'gemini-pro')
        const model = genAI.getGenerativeModel({
            model: "gemini-1.5-flash",
            systemInstruction: systemInstruction // Suportado nos modelos mais novos
        });

        const result = await model.generateContent(userPrompt);
        const responseText = result.response.text();

        return { text: responseText };

    } catch (error) {
        console.error("Gemini API Error:", error);
        throw new functions.https.HttpsError(
            'internal',
            'Falha ao obter resposta do assistente de IA.'
        );
    }
});
