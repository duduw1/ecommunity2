// 1. Importações
const functions = require("firebase-functions");
const { GoogleGenerativeAI } = require("@google/generative-ai"); 
require('dotenv').config(); 

// 2. Configuração
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY || ""); 

// 3. Endpoint
exports.getGeminiResponse = functions.https.onCall(async (data, context) => {
    // REMOVI O LOG QUE CAUSAVA O CRASH (JSON.stringify de objeto circular)

    // Tenta extrair o texto de várias formas possíveis (compatibilidade v1/v2/Raw)
    let userPrompt = null;
    
    // Se for objeto direto com .text ou .prompt
    if (data) {
        userPrompt = data.text || data.prompt || data.message;
        
        // Se 'data' for na verdade um objeto Request da v2, o payload real está em .data
        if (!userPrompt && data.data) {
             const innerData = data.data;
             userPrompt = innerData.text || innerData.prompt || innerData.message;
        }
    }

    // Se chegou como string
    if (!userPrompt && typeof data === 'string') {
        userPrompt = data;
    }

    if (!userPrompt) {
        // Log seguro (apenas chaves, sem stringify recursivo)
        console.warn("Payload recebido sem prompt. Chaves:", data ? Object.keys(data) : "null");
        throw new functions.https.HttpsError('invalid-argument', 'Prompt obrigatório. Verifique o envio.');
    }

    const fullPrompt = `
    You are EcoMestre, an expert Ecological Consultant for the E-Community App.
    Keep your answers short, concise and friendly.
    Answer in Portuguese.
    User Question: ${userPrompt}
    `;

    try {
        if (!GEMINI_API_KEY) throw new Error("API Key ausente.");

        // Modelo Flash
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

        const result = await model.generateContent(fullPrompt);
        const responseText = result.response.text();

        return { text: responseText };

    } catch (error) {
        console.error("Gemini API Error:", error);
        if (error.message.includes("503") || error.message.includes("overloaded")) {
             throw new functions.https.HttpsError('unavailable', 'Servidor sobrecarregado. Tente em 1 minuto.');
        }
        throw new functions.https.HttpsError('internal', `Erro API: ${error.message}`);
    }
});
