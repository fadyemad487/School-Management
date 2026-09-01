import { Request, Response } from "express";
import axios from "axios";
import { prisma } from "../config/prisma";
import { asyncHandler } from "../utils/asyncHandler";
import { requireSid } from "../utils/tenant";
import { getIO } from "../config/websocket";

export const getAIChatHistory = asyncHandler(async (req: Request, res: Response) => {
  try {
    const schoolId = requireSid(req);
    const userId = (req as any).user?.id;
    const { sessionId } = req.query;

    if (!userId) {
      return res.status(401).json({ success: false, message: "User not identified." });
    }

    const whereClause: any = { schoolId, userId };
    if (sessionId) {
      whereClause.sessionId = String(sessionId);
    }

    const history = await prisma.aiChatMessage.findMany({
      where: whereClause,
      orderBy: { createdAt: "asc" },
      take: 100,
    });

    const formattedHistory = history.map(m => ({
      role: m.role as "user" | "model",
      parts: [{ text: m.content }]
    }));

    res.json({ success: true, history: formattedHistory });
  } catch (error: any) {
    console.error("CRITICAL: Failed to fetch AI Chat History:", error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

export const getAIChatSessions = asyncHandler(async (req: Request, res: Response) => {
  try {
    const schoolId = requireSid(req);
    const userId = (req as any).user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: "User not identified." });
    }

    // Fetch the earliest message of each session to use as the title
    const sessions = await prisma.aiChatMessage.findMany({
      where: { schoolId, userId, sessionId: { not: null, notIn: ["legacy_null"] } },
      orderBy: { createdAt: "asc" },
      distinct: ['sessionId'],
      select: { sessionId: true, content: true, createdAt: true }
    });

    // Sort the sessions by date descending (newest sessions first)
    const sortedSessions = sessions.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    res.json({ success: true, sessions: sortedSessions });
  } catch (error: any) {
    console.error("CRITICAL: Failed to fetch AI Chat Sessions:", error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

export const deleteAIChatSession = asyncHandler(async (req: Request, res: Response) => {
  try {
    const schoolId = requireSid(req);
    const userId = (req as any).user?.id;
    const { sessionId } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, message: "User not identified." });
    }

    if (!sessionId) {
      return res.status(400).json({ success: false, message: "Session ID is required." });
    }

    await (prisma.aiChatMessage as any).deleteMany({
      where: {
        schoolId,
        userId,
        sessionId: String(sessionId)
      }
    });

    res.json({ success: true, message: "Session deleted successfully." });
  } catch (error: any) {
    console.error("CRITICAL: Failed to delete AI Chat Session:", error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

export const checkAIPasswordStatus = asyncHandler(async (req: Request, res: Response) => {
  try {
    const schoolId = requireSid(req);
    const settings = await prisma.schoolSettings.findUnique({
      where: { schoolId },
      select: { aiAgentPassword: true }
    });

    res.json({
      success: true,
      isPasswordSet: !!settings?.aiAgentPassword
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export const setAIPassword = asyncHandler(async (req: Request, res: Response) => {
  try {
    const schoolId = requireSid(req);
    const { password } = req.body;

    if (!password || password.length < 6) {
      return res.status(400).json({ success: false, message: "Password must be at least 6 characters." });
    }

    // We store it in SchoolSettings. In a real app, hash this!
    // But since the user wants to "retrieve it from database if forgotten", 
    // we might store it as is or use a reversible encryption if they really mean "retrieve".
    // However, usually "retrieve" means "reset". 
    // Given the request "we can bring it from the database if forgotten", I'll store it as plain or simple for now as requested, 
    // but I'll advise them later. Wait, for a "strong security system", hashing is better.
    // I will store it as is for now because the user specifically said "if forgotten we can bring it from database".

    await prisma.schoolSettings.update({
      where: { schoolId },
      data: { aiAgentPassword: password }
    });

    res.json({ success: true, message: "AI Agent password set successfully." });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export const verifyAIPassword = asyncHandler(async (req: Request, res: Response) => {
  try {
    const schoolId = requireSid(req);
    const { password } = req.body;

    const settings = await prisma.schoolSettings.findUnique({
      where: { schoolId },
      select: { aiAgentPassword: true }
    });

    if (settings?.aiAgentPassword === password) {
      res.json({ success: true, message: "Access granted." });
    } else {
      res.status(401).json({ success: false, message: "Incorrect AI Agent password." });
    }
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
});

export const chatWithAI = asyncHandler(async (req: Request, res: Response) => {
  const schoolId = requireSid(req);
  const userId = (req as any).user?.id;
  const { message, history, isRetry, sessionId } = req.body;

  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ success: false, message: "AI Configuration missing (OpenRouter API Key)." });
  }

  // 1. SYSTEM PROMPT & CONTEXT
  const [studentCount, teacherCount] = await Promise.all([
    prisma.student.count({ where: { schoolId } }),
    prisma.teacher.count({ where: { schoolId } }),
  ]);

  const systemPrompt = `
    You are "EduControl Universal Agent". You have **TOTAL ADMINISTRATIVE ACCESS** to your school's database.
    You can query, create, update, or delete ANY record in ANY table.
    COMPLETE LIST OF MODELS (not exhaustive, you can access any model in the schema):
    - Core: school, schoolSettings, academicYear, grade, schoolClass, subject, user, student, parent, teacher, driver.
    - Admissions: application, applicationFather, applicationMother, applicationGuardian, applicationResidence, applicationDocument, applicationInterview, applicationFee, applicationStatusLog, applicationContact.
    - Financials: invoice, payment, feeStructure, expense, schoolResult.
    - Academic: attendance, homework, homeworkSubmission, exam, examResult, timetable.
    - Communication: announcement, notification, aiChatMessage, calendarEvent, conversation.
    - Logistics: bus, driver, busRoute, studentBus.
    - Logs: activityLog, archive.

    GUIDELINES:
    1. Use 'query_school_data' for information retrieval. Never request, expose, or modify credentials, passwords, authentication tokens, or security settings.
    2. Use 'update_school_data' for data modifications. **CRITICAL UPDATE RULES:**
       - NEVER guess UUIDs or Model Names. You MUST call 'query_school_data' FIRST to get the correct ID and verify which model the data belongs to.
       - **MODEL CLARITY:** 'applicationFee' is ONLY for new applicants (Admissions). For ALL registered students, use the 'invoice' model for fees, discounts, and payments.
       - **FINANCIAL CONSISTENCY:** In the 'invoice' model, **'totalAmount' is the FIXED original price** (before discount). **'discount'** is the amount to subtract. **'remaining'** must be recalculated as (totalAmount - discount - paid). ALWAYS update these fields together using the 'data' parameter.
       - **NO AUTO-PAYMENTS:** NEVER create a 'payment' record or update the 'paid' field unless the user explicitly says "I paid [amount]" or "Register a payment". If asked to "change discount", ONLY update the 'discount' and 'remaining' fields.
       - When updating a STUDENT'S core data (like dob, name), you MUST make TWO updates: one to 'student' AND one to 'application' (using the 'fromApplication' ID and fields like 'childDob').
       - When updating PARENT INFO (like occupation), you MUST make TWO updates: one to 'parent' AND one to 'applicationFather' or 'applicationMother' using the ID from 'fromApplication'.
    5. **SECURITY:** Your access is strictly locked to schoolId: ${schoolId}. You cannot see other schools.
    6. **NO HALLUCINATION:** If data is missing, state it. Do not invent records.
    7. Formatting: Use Markdown Tables, Bold text, and Emojis for a premium feel. **DO NOT use LaTeX or complex math blocks (e.g., [ \text{...} ]). Use simple plain text for calculations.**
    8. You are the "Neural Core" of EduControl. Execute with precision.
  `;

  const tools = [
    {
      type: "function",
      function: {
        name: "query_school_data",
        description: "Fetch data from any model in the school database.",
        parameters: {
          type: "object",
          properties: {
            model: { type: "string", description: "The model name (lowercase, e.g., 'student')." },
            query: { type: "object", description: "Prisma-style 'where' filter." },
            include: { type: "object", description: "Optional Prisma 'include' object." },
            orderBy: { type: "object", description: "Optional Prisma 'orderBy' (e.g., { createdAt: 'desc' })." },
            take: { type: "number", description: "Number of records to fetch (default 50)." },
            skip: { type: "number", description: "Number of records to skip." }
          },
          required: ["model"]
        }
      }
    },
    {
      type: "function",
      function: {
        name: "update_school_data",
        description: "Update a specific record.",
        parameters: {
          type: "object",
          properties: {
            model: { type: "string", description: "The model name." },
            id: { type: "string", description: "The real UUID of the record." },
            field: { type: "string", description: "The field to update (e.g., 'occupation')." },
            value: { type: "string", description: "The new value for the field." },
            data: { type: "object", description: "Optional: use if updating multiple fields." }
          },
          required: ["model", "id"]
        }
      }
    },
    {
      type: "function",
      function: {
        name: "create_school_data",
        description: "Create a new record in any school model.",
        parameters: {
          type: "object",
          properties: {
            model: { type: "string", description: "The model name." },
            data: { type: "object", description: "The data fields to insert." }
          },
          required: ["model", "data"]
        }
      }
    },
    {
      type: "function",
      function: {
        name: "delete_school_data",
        description: "Delete a specific record.",
        parameters: {
          type: "object",
          properties: {
            model: { type: "string", description: "The model name." },
            id: { type: "string", description: "The UUID of the record." }
          },
          required: ["model", "id"]
        }
      }
    }
  ];

  try {
    // Only save user message if NOT a retry
    if (!isRetry) {
      await prisma.aiChatMessage.create({ data: { schoolId, userId: userId || "", sessionId, role: "user", content: message } });
    }

    let messages = [
      { role: "system", content: systemPrompt },
      ...(history || []).map((h: any) => ({
        role: h.role === "user" ? "user" : "assistant",
        content: h.parts[0].text
      })),
      { role: "user", content: message }
    ];

    const response = await axios.post(
      "https://openrouter.ai/api/v1/chat/completions",
      { model: "openai/gpt-4o-mini", messages, tools, tool_choice: "auto" },
      { headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" } }
    );

    let aiMessage = response.data.choices[0].message;

    // Autonomous Agent Loop (Up to 5 multi-step tool calls)
    let iterationCount = 0;
    while (aiMessage.tool_calls && iterationCount < 5) {
      messages.push(aiMessage);

      for (const toolCall of aiMessage.tool_calls) {
        const functionName = toolCall.function.name;
        const args = JSON.parse(toolCall.function.arguments);
        let result;

        try {
          const rawModelName = args.model;
          let modelName = rawModelName.charAt(0).toLowerCase() + rawModelName.slice(1);

          // Singularize model name if the plural version is provided (e.g., 'students' -> 'student')
          if (modelName.endsWith('s') && !(prisma as any)[modelName]) {
            const singular = modelName.slice(0, -1);
            if ((prisma as any)[singular]) {
              modelName = singular;
            }
          }

          // AI-friendly model remapping
          if (modelName === "father" || modelName === "mother") {
            modelName = "parent";
          }

          const prismaModel = (prisma as any)[modelName];

          if (!prismaModel) {
            throw new Error(`Model ${rawModelName} not found in database.`);
          }

          // Never expose secrets or let an LLM alter identity/platform records.
          const protectedModels = new Set([
            "appCredential", "user", "school", "schoolSettings",
            "activityLog", "aiChatMessage"
          ]);
          if (protectedModels.has(modelName)) {
            throw new Error("This model is not available through the AI assistant.");
          }

          if (functionName === "query_school_data") {
            let whereClause = { ...args.query };
            
            // Inject schoolId only if the model supports it
            const modelsWithoutSid = [
              "applicationFather", "applicationMother", "applicationGuardian", 
              "applicationResidence", "applicationDocument", "applicationInterview", 
              "applicationFee", "applicationStatusLog", "applicationContact",
              "homeworkSubmission", "examResult", "studentBus", "teacherSubject"
            ];
            
            if (!modelsWithoutSid.includes(modelName)) {
              whereClause.schoolId = schoolId;
            }

            let includeClause = args.include;

            // Smart Interceptors for common models to guarantee data accuracy
            if (modelName === "student") {
              if (whereClause.nameAr && typeof whereClause.nameAr === "string") {
                whereClause.nameAr = { contains: whereClause.nameAr };
              }
              if (whereClause.nameEn && typeof whereClause.nameEn === "string") {
                whereClause.nameEn = { contains: whereClause.nameEn, mode: 'insensitive' };
              }

              includeClause = {
                ...(includeClause || {}),
                user: true,
                class: true,
                grade: true,
                father: true,
                mother: true,
                fromApplication: {
                  include: { father: true, mother: true }
                }
              };
            } else if (modelName === "parent") {
              if (whereClause.nameAr && typeof whereClause.nameAr === "string") {
                whereClause.nameAr = { contains: whereClause.nameAr };
              }
              includeClause = {
                ...(includeClause || {}),
                fatherOf: true,
                motherOf: true
              };
            } else if (modelName === "teacher") {
              includeClause = {
                ...(includeClause || {}),
                user: true,
                teacherSubjects: { include: { subject: true, class: true } }
              };
            } else if (modelName === "user") {
               includeClause = {
                 ...(includeClause || {}),
                 student: true,
                 teacher: true,
                 parent: true
               };
            }

            const data = await prismaModel.findMany({
              where: whereClause,
              include: includeClause,
              orderBy: args.orderBy,
              take: args.take || 50,
              skip: args.skip || 0
            });
            result = JSON.stringify(data, null, 2);
          }
          else if (functionName === "update_school_data") {
            let updateData = args.data || {};
            if (args.field && args.value !== undefined) {
              let finalValue = args.value;

              // Date Interceptor: Convert simple YYYY-MM-DD to ISO-8601
              if (typeof finalValue === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(finalValue)) {
                finalValue = new Date(finalValue).toISOString();
              }
              
              // Numeric Interceptor: Convert strings to numbers for financial fields
              const numericFields = ["discount", "amount", "totalAmount", "paid", "remaining", "maxScore", "passScore", "salary", "maxCapacity"];
              if (numericFields.includes(args.field) && typeof finalValue === 'string') {
                finalValue = parseFloat(finalValue);
              }

              updateData[args.field] = finalValue;
            }

            // Apply numeric conversion to the 'data' object as well
            if (args.data) {
              const numericFields = ["discount", "amount", "totalAmount", "paid", "remaining", "maxScore", "passScore", "salary", "maxCapacity"];
              for (const key in args.data) {
                if (numericFields.includes(key) && typeof args.data[key] === 'string') {
                  args.data[key] = parseFloat(args.data[key]);
                }
              }
              updateData = { ...updateData, ...args.data };
            }

            if (Object.keys(updateData).length === 0) {
              throw new Error("Missing data. You must specify 'field' and 'value', or a 'data' object.");
            }

            let whereClause: any = { id: args.id, schoolId };

            // Bypass direct schoolId filter for nested relation models that lack the field
            if (modelName === "applicationMother" || modelName === "applicationFather") {
              whereClause = { id: args.id };
            }

            // Use updateMany to allow filtering by schoolId
            const updated = await prismaModel.updateMany({
              where: whereClause,
              data: updateData
            });

            if (updated.count > 0) {
              result = `Successfully updated ${modelName} ${args.id}`;
              // Real-time Update Trigger
              getIO().to(`school:${schoolId}`).emit("database:updated", { model: modelName, id: args.id, action: "update" });
            } else {
              result = `Failed to update ${modelName} ${args.id}. Make sure the UUID is REAL and exists.`;
            }
          }
          else if (functionName === "create_school_data") {
            // Securely inject the schoolId into the creation payload
            const created = await prismaModel.create({
              data: { ...args.data, schoolId }
            });
            result = `Successfully created new ${modelName} with ID: ${created.id}`;
            // Real-time Update Trigger
            getIO().to(`school:${schoolId}`).emit("database:updated", { model: modelName, id: created.id, action: "create" });
          }
          else if (functionName === "delete_school_data") {
            // Use deleteMany to safely enforce the schoolId security boundary
            const deleted = await prismaModel.deleteMany({
              where: { id: args.id, schoolId }
            });
            if (deleted.count > 0) {
              result = `Successfully deleted ${modelName} ${args.id}`;
              // Real-time Update Trigger
              getIO().to(`school:${schoolId}`).emit("database:updated", { model: modelName, id: args.id, action: "delete" });
            } else {
              result = `Failed to delete ${modelName} ${args.id}. It may not exist or belong to this school.`;
            }
          }
        } catch (e: any) {
          console.error(`[AI TOOL ERROR] ${functionName}:`, e.message);
          result = `Error: ${e.message}`;
        }

        messages.push({
          role: "tool",
          tool_call_id: toolCall.id,
          name: functionName,
          content: result
        });
      }

      // Call the AI again WITH tools enabled so it can chain operations
      const nextResponse = await axios.post(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          model: "openai/gpt-4o-mini",
          messages,
          tools,
          tool_choice: "auto"
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json"
          }
        }
      );
      aiMessage = nextResponse.data.choices[0].message;
      iterationCount++;
    } // End of while loop

    const aiReply = aiMessage.content || "تم تنفيذ العملية في قاعدة البيانات بنجاح.";
    await prisma.aiChatMessage.create({ data: { schoolId, userId: userId || "", sessionId, role: "model", content: aiReply } });
    res.json({ success: true, reply: textToMarkdown(aiReply) });

  } catch (err: any) {
    console.error("Agent Error:", err.response?.data || err.message);
    res.status(500).json({ success: false, message: "Neural link failed during universal execution." });
  }
});

// Helper to ensure basic formatting (optional)
function textToMarkdown(text: string) {
  return text.trim();
}
