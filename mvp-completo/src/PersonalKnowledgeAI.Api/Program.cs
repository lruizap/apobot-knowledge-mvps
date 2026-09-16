using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Npgsql;
using Neo4j.Driver;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<KnowledgeSearchService>();
builder.Services.AddSingleton<KnowledgeGraphService>();
builder.Services.AddSingleton<KnowledgeIndexer>();
builder.Services.AddHttpClient<OllamaClient>(client => { client.BaseAddress = new Uri(Environment.GetEnvironmentVariable("OLLAMA_BASE_URL") ?? "http://127.0.0.1:11434"); client.Timeout = TimeSpan.FromMinutes(5); });
var app = builder.Build();
app.UseDefaultFiles();
app.UseStaticFiles();

app.MapGet("/", (IWebHostEnvironment environment) => Results.File(Path.Combine(environment.ContentRootPath, "wwwroot", "index.html"), "text/html"));
app.MapGet("/api/knowledge/health", async (KnowledgeSearchService search, KnowledgeIndexer indexer, CancellationToken ct) => Results.Ok(await indexer.GetHealthAsync(search, ct)));
app.MapGet("/api/knowledge/graph", async (KnowledgeGraphService graph, CancellationToken ct) => Results.Ok(await graph.GetHealthAsync(ct)));
app.MapGet("/api/knowledge/search", async (string? q, int? limit, KnowledgeSearchService search, CancellationToken ct) =>
{
    if (string.IsNullOrWhiteSpace(q)) return Results.BadRequest(new { error = "El parametro q es obligatorio." });
    return Results.Ok(await search.FindAsync(q, Math.Clamp(limit ?? 5, 1, 20), ct));
});
app.MapPost("/api/knowledge/index", async (KnowledgeIndexer indexer, CancellationToken ct) =>
{
    try { return Results.Ok(await indexer.IndexAsync(ct)); }
    catch (Exception ex) { return Results.Problem("No se pudo indexar la boveda: " + ex.Message, statusCode: 500); }
});
app.MapPost("/api/chat", async (ChatRequest request, KnowledgeSearchService search, KnowledgeGraphService graph, OllamaClient ollama, CancellationToken ct) =>
{
    if (string.IsNullOrWhiteSpace(request.Message)) return Results.BadRequest(new { error = "El campo message es obligatorio." });
    var vectorNotes = await search.FindAsync(request.Message, Math.Clamp(request.Limit ?? 5, 1, 8), ct);
    var graphNotes = await graph.SearchAsync(request.Message, 2, ct);
    var notes = vectorNotes.Concat(graphNotes).GroupBy(note => note.Path, StringComparer.OrdinalIgnoreCase).Select(group => group.OrderByDescending(note => note.Score).First()).Take(Math.Clamp(request.Limit ?? 5, 1, 8)).ToList();
    if (notes.Count == 0) return Results.Ok(new { answer = "No encuentro informacion suficiente en la boveda para responder.", sources = Array.Empty<string>(), grounded = false });
    try
    {
        var answer = await ollama.AnswerAsync(request.Message, notes, ct);
        return Results.Ok(new { answer, sources = notes.Select(note => note.Path), grounded = true, model = ollama.Model, search = notes.FirstOrDefault()?.SearchType });
    }
    catch (HttpRequestException ex) { return Results.Json(new { error = "No se pudo conectar con Ollama.", detail = ex.Message }, statusCode: 503); }
    catch (TaskCanceledException) { return Results.Json(new { error = "Ollama tardo demasiado en responder. Prueba con una pregunta más corta o espera a que termine la carga del modelo." }, statusCode: 504); }
});
app.Run();

record ChatRequest(string? Message, int? Limit);
record KnowledgeNote(string Path, string Title, double Score, string Snippet, string SearchType);
record IndexResult(int Documents, int Chunks, int Embedded, string VaultPath);

sealed class OllamaClient
{
    private readonly HttpClient _http;
    public string Model { get; } = Environment.GetEnvironmentVariable("OLLAMA_MODEL") ?? "qwen3:4b-instruct";
    public string EmbeddingModel { get; } = Environment.GetEnvironmentVariable("OLLAMA_EMBEDDING_MODEL") ?? "qwen3-embedding:0.6b";
    public OllamaClient(HttpClient http) => _http = http;

    public async Task<float[]> EmbedAsync(string input, CancellationToken ct)
    {
        using var response = await _http.PostAsJsonAsync("/api/embed", new { model = EmbeddingModel, input }, ct);
        response.EnsureSuccessStatusCode();
        using var json = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        return json.RootElement.GetProperty("embeddings")[0].EnumerateArray().Select(x => x.GetSingle()).ToArray();
    }

    public async Task<string> AnswerAsync(string question, IReadOnlyList<KnowledgeNote> notes, CancellationToken ct)
    {
        var context = string.Join("\n\n", notes.Select(note => $"FUENTE: {note.Path}\n{note.Snippet}"));
        var body = new { model = Model, stream = false, think = false, options = new { temperature = 0, num_predict = 500 }, messages = new[]
        {
            new { role = "system", content = "Eres un asistente de conocimiento personal. Responde SOLO en espanol y SOLO con el CONTEXTO proporcionado. No inventes datos. Si el contexto no basta, di que no lo sabes. Responde de forma directa y cita las fuentes usando su ruta exacta. Distingue hechos de inferencias." },
            new { role = "user", content = $"PREGUNTA:\n{question}\n\nCONTEXTO DE LA BOVEDA:\n{context}" }
        }};
        using var response = await _http.PostAsJsonAsync("/api/chat", body, ct);
        response.EnsureSuccessStatusCode();
        using var json = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        return json.RootElement.GetProperty("message").GetProperty("content").GetString() ?? "Ollama no devolvio contenido.";
    }
}

sealed class KnowledgeSearchService
{
    private readonly string _vaultPath;
    private static readonly string[] IgnoredDirectories = [".obsidian", ".git", "bin", "obj"];
    public string VaultPath => _vaultPath;
    public KnowledgeSearchService(IConfiguration configuration)
    {
        var configured = configuration["Knowledge:VaultPath"] ?? Environment.GetEnvironmentVariable("KNOWLEDGE_VAULT_PATH");
        var current = new DirectoryInfo(Directory.GetCurrentDirectory());
        var defaultPath = current.Name.Equals("PersonalKnowledgeAI.Api", StringComparison.OrdinalIgnoreCase) ? current.Parent?.Parent?.FullName ?? current.FullName : current.FullName;
        _vaultPath = Path.GetFullPath(configured ?? defaultPath);
    }
    public IEnumerable<(string Path, string Title, string Content)> GetDocuments()
    {
        if (!Directory.Exists(_vaultPath)) return [];
        return Directory.EnumerateFiles(_vaultPath, "*.md", SearchOption.AllDirectories)
            .Where(path => !IgnoredDirectories.Any(directory => path.Split(Path.DirectorySeparatorChar).Contains(directory, StringComparer.OrdinalIgnoreCase)))
            .Select(path => (Path.GetRelativePath(_vaultPath, path).Replace('\\', '/'), Path.GetFileNameWithoutExtension(path).Replace('-', ' '), File.ReadAllText(path)));
    }
    public async Task<IReadOnlyList<KnowledgeNote>> FindAsync(string query, int limit, CancellationToken ct)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__Knowledge");
        if (!string.IsNullOrWhiteSpace(connectionString))
        {
            try { return await SearchVectorAsync(connectionString, query, limit, ct); } catch { /* permite usar busqueda local mientras se levanta la base */ }
        }
        return FindLocal(query, limit);
    }
    public IReadOnlyList<KnowledgeNote> FindLocal(string query, int limit)
    {
        var terms = Tokenize(query);
        return GetDocuments().Select(document => Score(document, terms)).Where(note => note.Score > 0).OrderByDescending(note => note.Score).ThenBy(note => note.Path).Take(limit).ToList();
    }
    private static KnowledgeNote Score((string Path, string Title, string Content) document, IReadOnlyList<string> terms)
    {
        var normalized = document.Content.ToLowerInvariant(); var score = 0;
        foreach (var term in terms) { score += Regex.Matches(normalized, $"\\b{Regex.Escape(term)}\\b").Count; if (document.Title.Contains(term, StringComparison.OrdinalIgnoreCase)) score += 4; }
        var firstMatch = terms.Select(term => normalized.IndexOf(term, StringComparison.OrdinalIgnoreCase)).Where(index => index >= 0).DefaultIfEmpty(0).Min();
        var start = Math.Max(0, firstMatch - 100); var snippet = Regex.Replace(document.Content[start..Math.Min(document.Content.Length, start + 900)], @"\\s+", " ").Trim();
        return new KnowledgeNote(document.Path, document.Title, score, snippet, "local");
    }
    private static async Task<IReadOnlyList<KnowledgeNote>> SearchVectorAsync(string cs, string query, int limit, CancellationToken ct)
    {
        await using var connection = new NpgsqlConnection(cs); await connection.OpenAsync(ct);
        var ollama = new OllamaClient(new HttpClient { BaseAddress = new Uri(Environment.GetEnvironmentVariable("OLLAMA_BASE_URL") ?? "http://127.0.0.1:11434") });
        var embedding = await ollama.EmbedAsync(query, ct); var vector = "[" + string.Join(',', embedding.Select(value => value.ToString(System.Globalization.CultureInfo.InvariantCulture))) + "]";
        await using var command = new NpgsqlCommand("SELECT document_path, content, 1 - (embedding <=> @embedding::vector) AS score FROM knowledge_chunks WHERE embedding IS NOT NULL ORDER BY embedding <=> @embedding::vector LIMIT @limit", connection);
        command.Parameters.AddWithValue("embedding", vector); command.Parameters.AddWithValue("limit", limit);
        var result = new List<KnowledgeNote>(); await using var reader = await command.ExecuteReaderAsync(ct);
        while (await reader.ReadAsync(ct)) { var path = reader.GetString(0); var content = reader.GetString(1); result.Add(new KnowledgeNote(path, Path.GetFileNameWithoutExtension(path).Replace('-', ' '), reader.GetDouble(2), Regex.Replace(content, @"\\s+", " ").Trim(), "pgvector")); }
        return result;
    }
    private static IReadOnlyList<string> Tokenize(string query) => Regex.Matches(query.ToLowerInvariant(), @"[\\p{L}\\p{N}_-]{3,}").Select(match => match.Value).Distinct().ToList();
}

sealed class KnowledgeGraphService
{
    private readonly IDriver _driver;
    private readonly bool _enabled;
    public KnowledgeGraphService(IConfiguration config)
    {
        var uri = config["Neo4j:Uri"] ?? Environment.GetEnvironmentVariable("NEO4J_URI") ?? "bolt://neo4j:7687";
        var user = config["Neo4j:User"] ?? Environment.GetEnvironmentVariable("NEO4J_USER") ?? "neo4j";
        var password = config["Neo4j:Password"] ?? Environment.GetEnvironmentVariable("NEO4J_PASSWORD") ?? "knowledge_dev_only";
        _driver = GraphDatabase.Driver(uri, AuthTokens.Basic(user, password)); _enabled = true;
    }
    public async Task UpsertDocumentAsync(string path, string title, string content, CancellationToken ct)
    {
        if (!_enabled) return;
        await using var session = _driver.AsyncSession();
        try
        {
            var links = Regex.Matches(content, @"\[\[([^\]|#]+)").Select(m => Path.GetFileNameWithoutExtension(m.Groups[1].Value.Trim()).Replace('-', ' ')).Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
            await session.RunAsync("MERGE (n:Note {path:$path}) SET n.title=$title, n.content=$content, n.updatedAt=datetime()", new { path, title, content });
            await session.RunAsync("MATCH (n:Note {path:$path})-[r:LINKS_TO]->() DELETE r", new { path });
            foreach (var link in links) await session.RunAsync("MERGE (a:Note {path:$path}) SET a.title=$title MERGE (n:Note {path:$source}) MERGE (n)-[:LINKS_TO]->(a)", new { source = path, path = link, title = link });
        }
        finally { await session.CloseAsync(); }
    }
    public async Task<IReadOnlyList<KnowledgeNote>> SearchAsync(string query, int limit, CancellationToken ct)
    {
        var terms = Regex.Matches(query.ToLowerInvariant(), @"[\p{L}\p{N}_-]{3,}").Select(m => m.Value).Distinct().Take(8).ToArray();
        if (terms.Length == 0) return [];
        await using var session = _driver.AsyncSession();
        try
        {
            var cursor = await session.RunAsync("MATCH (n:Note) WHERE any(term IN $terms WHERE toLower(n.title) CONTAINS term OR toLower(n.path) CONTAINS term OR toLower(n.content) CONTAINS term) RETURN n.path AS path,n.title AS title,n.content AS content LIMIT $limit", new { terms, limit });
            var result = new List<KnowledgeNote>(); await cursor.ForEachAsync(record => { var content = record["content"].As<string>(); result.Add(new KnowledgeNote(record["path"].As<string>(), record["title"].As<string>(), 0.5, Regex.Replace(content[..Math.Min(content.Length, 900)], @"\s+", " ").Trim(), "neo4j")); }); return result;
        }
        finally { await session.CloseAsync(); }
    }
    public async Task UpsertDocumentAsyncBatchAsync(IEnumerable<(string Path, string Title, string Content)> docs, CancellationToken ct) { foreach (var doc in docs) await UpsertDocumentAsync(doc.Path, doc.Title, doc.Content, ct); }
    public async Task<object> GetHealthAsync(CancellationToken ct)
    {
        await using var session = _driver.AsyncSession();
        try { var cursor = await session.RunAsync("MATCH (n:Note) RETURN count(n) AS count"); var record = await cursor.SingleAsync(); return new { backend = "neo4j", connected = true, notes = record["count"].As<long>() }; }
        catch (Exception ex) { return new { backend = "neo4j", connected = false, error = ex.Message }; }
        finally { await session.CloseAsync(); }
    }
}
sealed class KnowledgeIndexer
{
    private readonly KnowledgeSearchService _search; private readonly OllamaClient _ollama; private readonly KnowledgeGraphService _graph; private readonly string? _cs;
    public KnowledgeIndexer(KnowledgeSearchService search, OllamaClient ollama, KnowledgeGraphService graph, IConfiguration config) { _search = search; _ollama = ollama; _graph = graph; _cs = config.GetConnectionString("Knowledge") ?? Environment.GetEnvironmentVariable("ConnectionStrings__Knowledge"); }
    public async Task<object> GetHealthAsync(KnowledgeSearchService search, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(_cs)) return new { vaultPath = search.VaultPath, exists = Directory.Exists(search.VaultPath), backend = "local", markdownFiles = search.GetDocuments().Count() };
        try { await using var c = new NpgsqlConnection(_cs); await c.OpenAsync(ct); await using var cmd = new NpgsqlCommand("SELECT (SELECT count(*) FROM knowledge_documents), (SELECT count(*) FROM knowledge_chunks), (SELECT count(*) FROM knowledge_chunks WHERE embedding IS NOT NULL)", c); await using var r = await cmd.ExecuteReaderAsync(ct); await r.ReadAsync(ct); return new { vaultPath = search.VaultPath, exists = Directory.Exists(search.VaultPath), backend = "postgresql/pgvector", documents = r.GetInt64(0), chunks = r.GetInt64(1), embedded = r.GetInt64(2) }; } catch (Exception ex) { return new { vaultPath = search.VaultPath, exists = Directory.Exists(search.VaultPath), backend = "postgresql/error", error = ex.Message }; }
    }
    public async Task<IndexResult> IndexAsync(CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(_cs)) throw new InvalidOperationException("Falta ConnectionStrings__Knowledge");
        await using var c = new NpgsqlConnection(_cs); await c.OpenAsync(ct); await EnsureSchemaAsync(c, ct); var docs = _search.GetDocuments().ToList(); var chunks = 0; var embedded = 0;
        foreach (var doc in docs)
        {
            var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(doc.Content)));
            await using (var existing = new NpgsqlCommand("SELECT content_hash FROM knowledge_documents WHERE path=@path", c))
            {
                existing.Parameters.AddWithValue("path", doc.Path);
                var previousHash = await existing.ExecuteScalarAsync(ct) as string;
                if (string.Equals(previousHash, hash, StringComparison.OrdinalIgnoreCase)) { await _graph.UpsertDocumentAsync(doc.Path, doc.Title, doc.Content, ct); continue; }
            }
            await using (var d = new NpgsqlCommand("INSERT INTO knowledge_documents(path,title,content,content_hash) VALUES(@path,@title,@content,@hash) ON CONFLICT(path) DO UPDATE SET title=EXCLUDED.title,content=EXCLUDED.content,content_hash=EXCLUDED.content_hash,updated_at=now()", c)) { d.Parameters.AddWithValue("path", doc.Path); d.Parameters.AddWithValue("title", doc.Title); d.Parameters.AddWithValue("content", doc.Content); d.Parameters.AddWithValue("hash", hash); await d.ExecuteNonQueryAsync(ct); }
            await using (var del = new NpgsqlCommand("DELETE FROM knowledge_chunks WHERE document_path=@path", c)) { del.Parameters.AddWithValue("path", doc.Path); await del.ExecuteNonQueryAsync(ct); }
            var index = 0; foreach (var text in Chunk(doc.Content)) { var vector = await _ollama.EmbedAsync(text, ct); var vectorText = "[" + string.Join(',', vector.Select(value => value.ToString(System.Globalization.CultureInfo.InvariantCulture))) + "]"; await using var q = new NpgsqlCommand("INSERT INTO knowledge_chunks(document_path,chunk_index,content,content_hash,embedding) VALUES(@path,@idx,@content,@hash,@embedding::vector)", c); q.Parameters.AddWithValue("path", doc.Path); q.Parameters.AddWithValue("idx", index++); q.Parameters.AddWithValue("content", text); q.Parameters.AddWithValue("hash", hash); q.Parameters.AddWithValue("embedding", vectorText); await q.ExecuteNonQueryAsync(ct); chunks++; embedded++; }
        }
        await _graph.UpsertDocumentAsyncBatchAsync(docs, ct);
        return new IndexResult(docs.Count, chunks, embedded, _search.VaultPath);
    }
    private static async Task EnsureSchemaAsync(NpgsqlConnection c, CancellationToken ct) { await using var q = new NpgsqlCommand("CREATE EXTENSION IF NOT EXISTS vector; CREATE TABLE IF NOT EXISTS knowledge_documents (id BIGSERIAL PRIMARY KEY, path TEXT NOT NULL UNIQUE, title TEXT NOT NULL, content TEXT NOT NULL, metadata JSONB NOT NULL DEFAULT '{}'::jsonb, content_hash TEXT NOT NULL, updated_at TIMESTAMPTZ NOT NULL DEFAULT now()); CREATE INDEX IF NOT EXISTS knowledge_documents_content_fts ON knowledge_documents USING GIN (to_tsvector('simple', content)); CREATE TABLE IF NOT EXISTS knowledge_chunks (id BIGSERIAL PRIMARY KEY, document_path TEXT NOT NULL, chunk_index INTEGER NOT NULL, content TEXT NOT NULL, metadata JSONB NOT NULL DEFAULT '{}'::jsonb, content_hash TEXT NOT NULL, embedding vector(1024), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), UNIQUE(document_path,chunk_index)); CREATE INDEX IF NOT EXISTS knowledge_chunks_embedding_idx ON knowledge_chunks USING hnsw (embedding vector_cosine_ops);", c); await q.ExecuteNonQueryAsync(ct); }
    private static IEnumerable<string> Chunk(string content) { const int size = 1200, overlap = 150; if (string.IsNullOrWhiteSpace(content)) yield break; for (var start = 0; start < content.Length; start += size - overlap) { yield return content[start..Math.Min(content.Length, start + size)]; if (start + size >= content.Length) break; } }
}










