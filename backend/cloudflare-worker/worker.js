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
      const articles = Array.isArray(body.articles) ? body.articles : [];
      if (!question) return json({ error: "question is required" }, 400, corsHeaders);

      const provider = (env.LLM_PROVIDER || "deepseek").toLowerCase();
      const cfg = resolveProviderConfig(provider, env);
      if (!cfg.apiKey) {
        return json({ error: `${provider} api key is missing` }, 500, corsHeaders);
      }

      const timeoutMs = Number(env.TIMEOUT_MS || 12000);
      const maxArticles = Number(env.MAX_ARTICLES || 120);

      const articleList = articles.slice(0, maxArticles).map((a, idx) => ({
        id: Number(a.id || idx + 1),
        title: String(a.title || ""),
        permalink: String(a.permalink || "#"),
        summary: String(a.summary || "").slice(0, 280),
        series: asList(a.series),
        categories: asList(a.categories),
        tags: asList(a.tags),
        section: String(a.section || ""),
        date: String(a.date || "")
      }));

      const contextText = articleList.map((c) => {
        return [
          `[${c.id}] 标题：${c.title}`,
          `链接：${c.permalink}`,
          `时间：${c.date}`,
          `系列：${c.series.join(" / ")}`,
          `分类：${c.categories.join(" / ")}`,
          `标签：${c.tags.join(" / ")}`,
          `摘要：${c.summary}`
        ].join("\n");
      }).join("\n\n");

      const systemPrompt = [
        "你是博客问答助手。你必须先在给定文章列表中检索相关内容，再回答。",
        "规则：",
        "1) 回答简洁，中文输出；",
        "2) 每个关键结论后必须带引用编号，如[1][2]；",
        "3) 只能引用给定文章编号，禁止杜撰来源；",
        "4) 最后输出“来源”小节，列出编号对应标题与链接；",
        "5) 若信息不足，明确说明不足并给出最接近的相关文章编号。"
      ].join("\n");

      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      let response;
      try {
        response = await fetch(cfg.baseUrl.replace(/\/+$/, "") + "/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${cfg.apiKey}`
          },
          body: JSON.stringify({
            model: cfg.model,
            temperature: 0.2,
            max_tokens: 800,
            messages: [
              { role: "system", content: systemPrompt },
              {
                role: "user",
                content: `用户问题：\n${question}\n\n可用文章列表：\n${contextText}`
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
        return json({ error: `LLM upstream error: ${response.status}`, detail: t.slice(0, 600) }, 502, corsHeaders);
      }

      const data = await response.json();
      const answer = data?.choices?.[0]?.message?.content || "";
      if (!answer) return json({ error: "empty answer" }, 502, corsHeaders);

      const sources = pickSourcesFromAnswer(answer, articleList);
      return json(
        {
          answer,
          sources,
          provider: cfg.provider,
          model: cfg.model
        },
        200,
        corsHeaders
      );
    } catch (err) {
      const msg = err && err.name === "AbortError" ? "upstream timeout" : (err?.message || "internal error");
      return json({ error: msg }, 500, corsHeaders);
    }
  }
};

function asList(v) {
  if (Array.isArray(v)) return v.map((x) => String(x || "")).filter(Boolean);
  if (typeof v === "string" && v.trim()) return [v.trim()];
  return [];
}

function resolveProviderConfig(provider, env) {
  if (provider === "qwen") {
    return {
      provider: "qwen",
      baseUrl: env.QWEN_BASE_URL || "https://dashscope.aliyuncs.com/compatible-mode/v1",
      model: env.QWEN_MODEL || "qwen-plus",
      apiKey: env.QWEN_API_KEY || ""
    };
  }
  return {
    provider: "deepseek",
    baseUrl: env.DEEPSEEK_BASE_URL || "https://api.deepseek.com/v1",
    model: env.DEEPSEEK_MODEL || "deepseek-chat",
    apiKey: env.DEEPSEEK_API_KEY || ""
  };
}

function pickSourcesFromAnswer(answer, articleList) {
  const ids = Array.from(
    new Set(
      (answer.match(/\[(\d+)\]/g) || [])
        .map((x) => Number(x.replace(/[^\d]/g, "")))
        .filter(Boolean)
    )
  );

  const map = new Map(articleList.map((a) => [a.id, { id: a.id, title: a.title, permalink: a.permalink }]));
  return ids.map((id) => map.get(id)).filter(Boolean).slice(0, 8);
}

function json(data, status, headers) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...headers
    }
  });
}

