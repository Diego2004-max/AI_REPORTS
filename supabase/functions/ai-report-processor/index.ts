import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.21.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { action, ...params } = body;

    const geminiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const supabase = createClient(supabaseUrl, supabaseKey);
    const genAI = new GoogleGenerativeAI(geminiKey);

    let result: Record<string, unknown>;

    switch (action) {
      case "classify":
        result = await classifyReport(
          genAI,
          params.description as string,
          params.location as string | undefined,
        );
        break;
      case "credibility":
        result = await getCredibility(
          supabase,
          params.userId as string,
          params.description as string,
          params.latitude as number,
          params.longitude as number,
        );
        break;
      case "priority":
        result = getPriority(params);
        break;
      default:
        throw new Error(`Acción desconocida: ${action}`);
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

// ── classify ────────────────────────────────────────────────────────────────

async function classifyReport(
  genAI: GoogleGenerativeAI,
  description: string,
  location?: string,
): Promise<Record<string, unknown>> {
  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  const prompt = `Eres un clasificador de reportes viales de la ciudad de Pasto, Colombia.
Clasifica el reporte en UNA de estas categorías:
- Accidente de tránsito
- Infraestructura
- Seguridad
- Emergencia climática
- Servicios públicos

Extrae también:
- severidad: "baja" | "media" | "alta" | "crítica"
- ubicacion_sensible: boolean (¿menciona hospital, colegio, vía principal?)
- impacto_vial: boolean (¿bloquea o afecta el tránsito?)

Responde SOLO en JSON sin markdown.

Descripción: "${description}"${location ? `\nUbicación: "${location}"` : ""}`;

  const result = await model.generateContent(prompt);
  const raw = result.response.text().trim();
  const cleaned = raw
    .replace(/```json\s*/g, "")
    .replace(/```\s*/g, "")
    .trim();

  const parsed = JSON.parse(cleaned) as Record<string, unknown>;

  const category = (parsed.category as string) ?? "Accidente de tránsito";
  const severity = (parsed.severidad as string) ??
    (parsed.severity as string) ?? "media";

  // Confidence based on how well category maps to known values
  const knownCategories = [
    "Accidente de tránsito",
    "Infraestructura",
    "Seguridad",
    "Emergencia climática",
    "Servicios públicos",
  ];
  const confidence = knownCategories.includes(category) ? 0.88 : 0.65;

  return {
    category,
    confidence,
    severity,
    sensitive_location: (parsed.ubicacion_sensible as boolean) ??
      (parsed.sensitive_location as boolean) ?? false,
    road_impact: (parsed.impacto_vial as boolean) ??
      (parsed.road_impact as boolean) ?? false,
  };
}

// ── credibility ──────────────────────────────────────────────────────────────

async function getCredibility(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  description: string,
  lat: number,
  lng: number,
): Promise<Record<string, unknown>> {
  const now = new Date();
  const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000).toISOString();
  const twoHoursAgo = new Date(
    now.getTime() - 2 * 60 * 60 * 1000,
  ).toISOString();

  const [userQuery, zoneQuery] = await Promise.all([
    supabase
      .from("reports")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", fiveMinutesAgo),
    supabase
      .from("reports")
      .select("latitude, longitude")
      .gte("created_at", twoHoursAgo)
      .not("latitude", "is", null),
  ]);

  const userCount = (userQuery.count as number) ?? 0;

  // ~200m radius ≈ 0.002 degrees
  const nearby = ((zoneQuery.data as Array<{ latitude: number; longitude: number }>) ?? [])
    .filter((r) =>
      Math.abs(r.latitude - lat) < 0.002 && Math.abs(r.longitude - lng) < 0.002
    );

  let base = 1.0;
  if (userCount > 3) base -= 0.4;
  if (nearby.length > 0) base += 0.3;
  if ((description ?? "").length < 10) base -= 0.2;

  const score = Math.max(0.0, Math.min(1.0, base));

  return {
    credibility_score: score,
    corroborated_by: nearby.length,
  };
}

// ── priority ─────────────────────────────────────────────────────────────────

function getPriority(
  params: Record<string, unknown>,
): Record<string, unknown> {
  const severityMap: Record<string, number> = {
    baja: 0.25,
    media: 0.5,
    alta: 0.75,
    crítica: 1.0,
  };

  const severity = (params.severity as string) ?? "media";
  const confirmations = (params.confirmations as number) ?? 0;
  const sensitiveLoc = (params.sensitive_location as boolean) ?? false;
  const roadImpact = (params.road_impact as boolean) ?? false;
  const credScore = (params.credibility_score as number) ?? 1.0;

  const severityNum = severityMap[severity] ?? 0.5;

  const priority =
    severityNum * 0.35 +
    (Math.min(confirmations, 5) / 5) * 0.20 +
    (sensitiveLoc ? 0.15 : 0) +
    (roadImpact ? 0.15 : 0) +
    credScore * 0.15;

  return { priority_score: Math.max(0.0, Math.min(1.0, priority)) };
}
