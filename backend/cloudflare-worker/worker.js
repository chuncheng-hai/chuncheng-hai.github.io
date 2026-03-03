export default {
  async fetch(request, env) {
    const corsHeaders = {
      "Access-Control-Allow-Origin": env.ALLOW_ORIGIN || "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization"
    };

    if (request.method === "OPTIONS") {
      return new Response("", { status: 204, headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return json({ error: "Method Not Allowed" }, 405, corsHeaders);
    }

    try {
      const body = await request.json();
      const question = String(body.question || "").trim();
      const contexts = Array.isArray(body.contexts) ? body.contexts : [];
      if (!question) return json({ error: "question is required" }, 400, corsHeaders);

      const baseUrl = env.OPENAI_BASE_URL || "https://api.openai.com/v1";
      const model = env.OPENAI_MODEL || "gpt-4o-mini";
      const timeoutMs = Number(env.TIMEOUT_MS || 12000);
      const apiKey = env.OPENAI_API_KEY;

      const contextText = contexts.slice(0, 4).map((c, idx) => {
        const id = c.id || idx + 1;
        const title = c.title || "";
        const permalink = c.permalink || "";
        const summary = c.summary || "";
        const content = c.content || "";
        return [
          `[${id}] 标题：${title}`,
          `链接：${permalink}`,
          `摘要：${summary}`,
          `内容片段：${content}`
        ].join("\n");
      }).join("\n\n");

      const systemPrompt = [
        "你是博客问答助手。必须优先使用给定上下文回答。",
        "规则：",
        "1) 每个关键结论后必须带引用编号，如[1][2]；",
        "2) 只能引用已提供的编号，禁止杜撰来源；",
        "3) 结尾给出简短总结；",
        "4) 信息不足时明确说不足。"
      ].join("\n");

      const headers = { "Content-Type": "application/json" };
      if (apiKey) {
        headers.Authorization = `Bearer ${apiKey}`;
      }

      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      let response;
      try {
        response = await fetch(baseUrl.replace(/\/+$/, "") + "/chat/completions", {
          method: "POST",
          headers,
          body: JSON.stringify({
            model,
            temperature: 0.2,
            max_tokens: 500,
            messages: [
              { role: "system", content: systemPrompt },
              {
                role: "user",
                content: `用户问题：\n${question}\n\n可用上下文：\n${contextText}`
              }
            ]
          }),
          signal: controller.signal
        });
      } finally {
        clearTimeout(timer);
      }

      if (!response.ok) {
        const t = await response.text();
        return json({ error: `LLM upstream error: ${response.status}`, detail: t.slice(0, 500) }, 502, corsHeaders);
      }

      const data = await response.json();
      const answer = data?.choices?.[0]?.message?.content || "";
      if (!answer) return json({ error: "empty answer" }, 502, corsHeaders);

      return json({ answer }, 200, corsHeaders);
    } catch (err) {
      const msg = err && err.name === "AbortError" ? "upstream timeout" : (err?.message || "internal error");
      return json({ error: msg }, 500, corsHeaders);
    }
  }
};

function json(data, status, headers) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...headers
    }
  });
}
