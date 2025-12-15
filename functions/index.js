// 1. Importações
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai"); 
const logger = require("firebase-functions/logger");
require('dotenv').config(); 

// 2. Configuração
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY || ""); 

// 3. Endpoint
exports.getGeminiResponse = onCall(
    { cors: true, maxInstances: 10 }, 
    async (request) => {
        const data = request.data;
        const userPrompt = data.text || data.prompt; 

        if (!userPrompt) {
            throw new HttpsError('invalid-argument', 'Prompt obrigatório.');
        }

        // Instruções embutidas no prompt para o modelo Pro (que não suporta systemInstruction nativo igual o 1.5)
        const fullPrompt = `
        Atue como um Consultor Ecológico experiente do App E-Community.
        Responda apenas sobre reciclagem e sustentabilidade.
        
        Pergunta do usuário: ${userPrompt}
        `;

        try {
            if (!GEMINI_API_KEY) throw new Error("API Key ausente");

            // Usando gemini-pro (mais estável)
            const model = genAI.getGenerativeModel({ model: "gemini-pro" });

            const result = await model.generateContent(fullPrompt);
            const responseText = result.response.text();

            return { text: responseText };

        } catch (error) {
            logger.error("Gemini API Error:", error);
            throw new HttpsError('internal', `DEBUG ERRO: ${error.message}`);
        }
    }
);
