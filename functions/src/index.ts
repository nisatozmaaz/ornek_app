// functions/src/index.ts
import { onCall } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2/options";

setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

type Item = { name: string; expiry: string };

// CALLABLE: Flutter'dan httpsCallable ile çağrılacak
export const suggestRecipes = onCall(async (request) => {
  const items = (request.data?.items as Item[]) ?? [];

  // 3 gün ve daha az kalanları bul
  const today = new Date();
  const soon = items.filter((it) => {
    const d = new Date(it.expiry);
    const diffDays = Math.ceil((d.getTime() - today.getTime()) / 86400000);
    return diffDays <= 3;
  });

  // Uygun yoksa boş dön
  if (soon.length === 0) {
    return { recipes: [] };
  }

  // Basit sahte öneri (AI olmadan) — önce entegrasyonu doğrulayalım
  const uses = soon.map((i) => i.name);
  const recipe = {
    title: "Kalanlarla Kolay Fırın",
    uses,
    ingredients: [...uses, "zeytinyağı", "tuz", "karabiber"],
    steps: [
      "Fırını 180°C ısıt.",
      "Malzemeleri doğra ve karıştır.",
      "Tepsiye al, üstüne zeytinyağı gezdir.",
      "20-25 dk pişir.",
    ],
    time_minutes: 25,
  };

  return { recipes: [recipe] };
});
