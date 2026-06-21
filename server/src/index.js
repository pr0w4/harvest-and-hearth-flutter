/**
 * Harvest & Hearth API — MongoDB + Clerk session JWT verification.
 *
 * Env: MONGODB_URI, CLERK_SECRET_KEY, PORT (optional, default 25165)
 *       Pterodactyl: SERVER_PORT, NODE_ENV
 *       Reads from .env file if exists (like localhost)
 * Middleware: compression (gzip), CORS
 */
import 'dotenv/config';
import compression from 'compression';
import cors from 'cors';
import express from 'express';
import { verifyToken } from '@clerk/backend';
import { MongoClient, ObjectId } from 'mongodb';

const PORT = Number(process.env.PORT) || Number(process.env.SERVER_PORT) || 25165;
const MONGODB_URI = process.env.MONGODB_URI || '';
const MONGODB_DB_NAME = process.env.MONGODB_DB_NAME || 'harvest_and_hearth';
const CLERK_SECRET_KEY = process.env.CLERK_SECRET_KEY || '';
const NODE_ENV = process.env.NODE_ENV || 'production';

const app = express();
app.disable('x-powered-by');
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '2mb' }));

let db;
let client;
const MAX_PLAN_MEAL_BADGES = 12;

async function connectMongo() {
  if (!MONGODB_URI) {
    console.error('Missing MONGODB_URI');
    process.exit(1);
  }
  client = new MongoClient(MONGODB_URI);
  await client.connect();
  db = client.db(MONGODB_DB_NAME);
  console.log(`MongoDB connected (db=${MONGODB_DB_NAME})`);
}

function profiles() {
  return db.collection('profiles');
}
function foodItems() {
  return db.collection('food_items');
}
function savedRecipes() {
  return db.collection('saved_recipes');
}
function notifications() {
  return db.collection('notifications');
}

function normalizeMealNames(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  const seen = new Set();
  for (const item of raw) {
    const s = String(item ?? '').trim();
    if (!s) continue;
    const key = s.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(s);
    if (out.length >= MAX_PLAN_MEAL_BADGES) break;
  }
  return out;
}

function normalizePlanSourceLabel(raw, fromShoppingPlan) {
  const s = String(raw ?? '').trim();
  if (s) return s;
  return fromShoppingPlan ? 'Từ shopping plan' : null;
}

async function clerkAuth(req, res, next) {
  if (!CLERK_SECRET_KEY) {
    return res.status(500).json({ error: 'Server missing CLERK_SECRET_KEY' });
  }
  const h = req.headers.authorization;
  if (!h?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Bearer token' });
  }
  const token = h.slice(7);
  try {
    const payload = await verifyToken(token, { secretKey: CLERK_SECRET_KEY });
    req.userId = payload.sub;
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

// ── Profile ────────────────────────────────────────────────────────────────
app.get('/api/v1/profile', clerkAuth, async (req, res) => {
  const uid = req.userId;
  let doc = await profiles().findOne({ _id: uid });
  if (!doc) {
    doc = {
      _id: uid,
      email: null,
      name: null,
      language: 'VIE',
      is_dark: false,
      updated_at: new Date(),
    };
    await profiles().insertOne(doc);
  }
  res.json({
    id: doc._id,
    email: doc.email,
    name: doc.name,
    language: doc.language,
    is_dark: doc.is_dark,
  });
});

app.put('/api/v1/profile', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const body = req.body || {};
  const patch = {
    updated_at: new Date(),
  };
  if ('email' in body) patch.email = body.email;
  if ('name' in body) patch.name = body.name;
  if ('language' in body) patch.language = body.language;
  if ('is_dark' in body) patch.is_dark = Boolean(body.is_dark);

  await profiles().updateOne(
    { _id: uid },
    { $set: patch },
    { upsert: true },
  );
  const doc = await profiles().findOne({ _id: uid });
  res.json({
    id: doc._id,
    email: doc.email,
    name: doc.name,
    language: doc.language,
    is_dark: doc.is_dark,
  });
});

// ── Food items ─────────────────────────────────────────────────────────────
app.get('/api/v1/food-items', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const rows = await foodItems()
    .find({ user_id: uid })
    .sort({ created_at: -1 })
    .toArray();
  res.json(
    rows.map((r) => ({
      id: r.id,
      user_id: r.user_id,
      name: r.name,
      category: r.category,
      storage: r.storage,
      quantity: r.quantity,
      unit: r.unit,
      added_date: r.added_date instanceof Date ? r.added_date.toISOString() : r.added_date,
      expiry_date:
        r.expiry_date == null
          ? null
          : r.expiry_date instanceof Date
            ? r.expiry_date.toISOString()
            : r.expiry_date,
      warning_days: r.warning_days,
      from_shopping_plan: Boolean(r.from_shopping_plan),
      shopping_plan_meal_names: normalizeMealNames(r.shopping_plan_meal_names),
      plan_source_label: normalizePlanSourceLabel(
        r.plan_source_label,
        Boolean(r.from_shopping_plan),
      ),
    })),
  );
});

app.post('/api/v1/food-items', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const rows = Array.isArray(req.body) ? req.body : [req.body];
  const now = new Date();
  const docs = rows.map((item) => {
    const fromShoppingPlan = Boolean(item.from_shopping_plan);
    return {
      id: item.id,
    user_id: uid,
    name: item.name,
    category: item.category,
    storage: item.storage,
    quantity: item.quantity,
    unit: item.unit,
    added_date: item.added_date,
    expiry_date: item.expiry_date ?? null,
    warning_days: item.warning_days ?? null,
    from_shopping_plan: fromShoppingPlan,
    shopping_plan_meal_names: normalizeMealNames(item.shopping_plan_meal_names),
    plan_source_label: normalizePlanSourceLabel(
      item.plan_source_label,
      fromShoppingPlan,
    ),
    created_at: now,
    };
  });
  if (docs.some((d) => !d.id)) {
    return res.status(400).json({ error: 'Each item needs id' });
  }
  await foodItems().insertMany(docs);
  res.status(201).json({ ok: true });
});

app.patch('/api/v1/food-items/:id', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { id } = req.params;
  const body = req.body || {};
  const r = await foodItems().findOne({ id, user_id: uid });
  if (!r) {
    return res.status(404).json({ error: 'Not found' });
  }
  const set = {};
  if ('name' in body) set.name = body.name;
  if ('category' in body) set.category = body.category;
  if ('storage' in body) set.storage = body.storage;
  if ('quantity' in body) set.quantity = body.quantity;
  if ('unit' in body) set.unit = body.unit;
  if ('added_date' in body) set.added_date = body.added_date;
  if ('expiry_date' in body) set.expiry_date = body.expiry_date;
  if ('warning_days' in body) set.warning_days = body.warning_days;
  if ('from_shopping_plan' in body) set.from_shopping_plan = Boolean(body.from_shopping_plan);
  if ('shopping_plan_meal_names' in body) {
    set.shopping_plan_meal_names = normalizeMealNames(body.shopping_plan_meal_names);
  }
  if ('plan_source_label' in body) {
    set.plan_source_label = normalizePlanSourceLabel(
      body.plan_source_label,
      'from_shopping_plan' in set ? Boolean(set.from_shopping_plan) : Boolean(r.from_shopping_plan),
    );
  }
  await foodItems().updateOne({ id, user_id: uid }, { $set: set });
  res.json({ ok: true });
});

app.delete('/api/v1/food-items/:id', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { id } = req.params;
  await foodItems().deleteOne({ id, user_id: uid });
  res.json({ ok: true });
});

// ── Saved recipes ────────────────────────────────────────────────────────────
app.get('/api/v1/saved-recipes', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const rows = await savedRecipes()
    .find({ user_id: uid })
    .sort({ created_at: -1 })
    .toArray();
  res.json(
    rows.map((r) => ({
      user_id: r.user_id,
      original_id: r.original_id,
      recipe_data: r.recipe_data,
    })),
  );
});

app.post('/api/v1/saved-recipes', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { original_id, recipe_data } = req.body || {};
  if (!original_id || !recipe_data) {
    return res.status(400).json({ error: 'original_id and recipe_data required' });
  }
  await savedRecipes().updateOne(
    { user_id: uid, original_id: String(original_id) },
    {
      $set: {
        user_id: uid,
        original_id: String(original_id),
        recipe_data,
        created_at: new Date(),
      },
    },
    { upsert: true },
  );
  res.status(201).json({ ok: true });
});

app.delete('/api/v1/saved-recipes/:originalId', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { originalId } = req.params;
  await savedRecipes().deleteOne({
    user_id: uid,
    original_id: originalId,
  });
  res.json({ ok: true });
});

// ── Custom recipes ────────────────────────────────────────────────────────────
function customRecipes() {
  return db.collection('custom_recipes');
}

app.get('/api/v1/custom-recipes', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const rows = await customRecipes()
    .find({ user_id: uid })
    .sort({ created_at: -1 })
    .toArray();
  res.json(rows.map((r) => ({ ...r, id: r.id })));
});

app.post('/api/v1/custom-recipes', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const body = req.body || {};
  if (!body.id || !body.name) {
    return res.status(400).json({ error: 'id and name required' });
  }
  const doc = { ...body, user_id: uid, created_at: new Date() };
  await customRecipes().insertOne(doc);
  res.status(201).json({ ok: true });
});

app.put('/api/v1/custom-recipes/:id', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { id } = req.params;
  const body = req.body || {};
  const r = await customRecipes().findOne({ id, user_id: uid });
  if (!r) return res.status(404).json({ error: 'Not found' });
  await customRecipes().updateOne(
    { id, user_id: uid },
    { $set: { ...body, updated_at: new Date() } },
  );
  res.json({ ok: true });
});

app.delete('/api/v1/custom-recipes/:id', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { id } = req.params;
  const result = await customRecipes().deleteOne({ id, user_id: uid });
  if (result.deletedCount === 0) {
    return res.status(404).json({ error: 'Not found' });
  }
  res.json({ ok: true });
});

// ── Notifications log ───────────────────────────────────────────────────────
app.get('/api/v1/notifications', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const limitRaw = Number(req.query.limit ?? 300);
  const skipRaw = Number(req.query.skip ?? 0);
  const limit = Number.isFinite(limitRaw)
    ? Math.min(Math.max(Math.trunc(limitRaw), 1), 1000)
    : 300;
  const skip = Number.isFinite(skipRaw)
    ? Math.max(Math.trunc(skipRaw), 0)
    : 0;
  const rows = await notifications()
    .find({ userId: uid })
    .sort({ createdAtTs: -1 })
    .skip(skip)
    .limit(limit)
    .toArray();

  res.json(
    rows.map((r) => ({
      id: r._id?.toString?.() ?? null,
      userId: r.userId,
      title: r.title,
      message: r.message,
      type: r.type,
      isRead: Boolean(r.isRead),
      createdAt: r.createdAt,
    })),
  );
});

app.post('/api/v1/notifications', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const body = req.body || {};
  const title = String(body.title || '').trim();
  const message = String(body.message || '').trim();
  const type = String(body.type || 'expiry').trim();

  if (!title || !message) {
    return res.status(400).json({ error: 'title and message required' });
  }

  const now = new Date();
  const createdAt = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}-${String(now.getUTCDate()).padStart(2, '0')}`;
  const doc = {
    userId: uid,
    title,
    message,
    type,
    isRead: false,
    createdAt,
    createdAtTs: now,
  };

  const result = await notifications().insertOne(doc);
  res.status(201).json({
    id: result.insertedId.toString(),
    userId: doc.userId,
    title: doc.title,
    message: doc.message,
    type: doc.type,
    isRead: doc.isRead,
    createdAt: doc.createdAt,
  });
});

app.patch('/api/v1/notifications/:id/read', clerkAuth, async (req, res) => {
  const uid = req.userId;
  const { id } = req.params;
  const body = req.body || {};
  const isRead = 'isRead' in body ? Boolean(body.isRead) : true;

  if (!ObjectId.isValid(id)) {
    return res.status(400).json({ error: 'Invalid notification id' });
  }

  const result = await notifications().updateOne(
    { _id: new ObjectId(id), userId: uid },
    { $set: { isRead } },
  );

  if (result.matchedCount === 0) {
    return res.status(404).json({ error: 'Not found' });
  }

  res.json({ ok: true });
});

async function main() {
  await connectMongo();
  await foodItems().createIndex({ user_id: 1 });
  await foodItems().createIndex({ id: 1, user_id: 1 }, { unique: true });
  await savedRecipes().createIndex({ user_id: 1 });
  await savedRecipes().createIndex(
    { user_id: 1, original_id: 1 },
    { unique: true },
  );
  await notifications().createIndex({ userId: 1, createdAtTs: -1 });
  await notifications().createIndex({ userId: 1, isRead: 1, createdAtTs: -1 });
  await customRecipes().createIndex({ user_id: 1, created_at: -1 });
  await customRecipes().createIndex({ id: 1, user_id: 1 }, { unique: true });

  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`[Harvest & Hearth API] Server listening on 0.0.0.0:${PORT}`);
    console.log(`[Harvest & Hearth API] Environment: ${NODE_ENV}`);
    console.log(`[Harvest & Hearth API] MongoDB: Connected`);
  });

  // Graceful shutdown cho Pterodactyl
  const gracefulShutdown = async (signal) => {
    console.log(`\n[Harvest & Hearth API] ${signal} received, shutting down gracefully...`);
    server.close(async () => {
      console.log('[Harvest & Hearth API] HTTP server closed');
      try {
        if (client) {
          await client.close();
          console.log('[Harvest & Hearth API] MongoDB connection closed');
        }
        process.exit(0);
      } catch (err) {
        console.error('[Harvest & Hearth API] Error during shutdown:', err);
        process.exit(1);
      }
    });

    // Force shutdown sau 10s nếu không đóng được
    setTimeout(() => {
      console.error('[Harvest & Hearth API] Forcing shutdown after timeout');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
}

main().catch((e) => {
  console.error('[Harvest & Hearth API] Fatal error:', e);
  process.exit(1);
});
