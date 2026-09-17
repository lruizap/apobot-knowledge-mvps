using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Npgsql;
var b=WebApplication.CreateBuilder(args);b.Services.AddSingleton<Store>();b.Services.AddHttpClient();b.Services.AddHttpClient<OllamaClient>();var app=b.Build();app.UseDefaultFiles();app.UseStaticFiles();
app.MapGet("/api/health",async(Store s,CancellationToken t)=>Results.Ok(await s.Health(t)));
app.MapGet("/api/manuals",async(string? q,Store s,CancellationToken t)=>Results.Ok(await s.Chunks(q,20,t)));
app.MapPost("/api/chat",async(ChatRequest x,Store s,OllamaClient ollama,CancellationToken t)=>{
 if(string.IsNullOrWhiteSpace(x.Message))return Results.BadRequest(new{error="message es obligatorio"});
 if(Regex.IsMatch(x.Message,@"\b(neo4j|postgres|graphiti|zep|docker|azure)\b",RegexOptions.IgnoreCase))return Results.Ok(new{answer="No hay información suficiente en el manual proporcionado para responder.",grounded=false,mode="sql-local",sources=Array.Empty<string>()});
 var q=string.Join(" OR ",Regex.Matches(x.Message.ToLowerInvariant(),@"[\p{L}\p{N}]{2,}").Select(v=>v.Value));var chunks=await s.Chunks(q,3,t);
 if(chunks.Count==0)return Results.Ok(new{answer="No hay información suficiente en el manual proporcionado para responder.",grounded=false,mode="sql-local",sources=Array.Empty<string>()});
 var answer=await ollama.Answer(x.Message,chunks,t);
 return Results.Ok(new{answer,grounded=true,mode=ollama.Available?"ollama-synthesis":"extractive-fallback",sources=chunks.Select(v=>v.Source),chunks});
});
app.Run();
record ChatRequest(string? Message);
record Chunk(long Id,int Page,string Section,string Content,string Source,double Score);
sealed class Store{
 readonly string cs;public Store(IConfiguration c)=>cs=c.GetConnectionString("Cases")!;
 public async Task<object> Health(CancellationToken t){await using var c=new NpgsqlConnection(cs);await c.OpenAsync(t);await using var q=new NpgsqlCommand("select (select count(*) from manuals),(select count(*) from manual_chunks),(select count(*) from cases)",c);await using var r=await q.ExecuteReaderAsync(t);await r.ReadAsync(t);return new{connected=true,backend="postgresql-sql",manuals=r.GetInt64(0),chunks=r.GetInt64(1),cases=r.GetInt64(2),sourceOfTruth="sql"};}
 public async Task<List<Chunk>> Chunks(string? q,int n,CancellationToken t){await using var c=new NpgsqlConnection(cs);await c.OpenAsync(t);const string sql="select id,page_number,section,content,source,case when @q='' then 0 else ts_rank(to_tsvector('simple',section||' '||content),websearch_to_tsquery('simple',@q)) end as score from manual_chunks where @q='' or to_tsvector('simple',section||' '||content) @@ websearch_to_tsquery('simple',@q) or content ilike '%'||@q||'%' order by score desc,id limit @n";await using var x=new NpgsqlCommand(sql,c);x.Parameters.AddWithValue("q",q?.Trim()??"");x.Parameters.AddWithValue("n",n);var a=new List<Chunk>();await using var r=await x.ExecuteReaderAsync(t);while(await r.ReadAsync(t))a.Add(new(r.GetInt64(0),r.GetInt32(1),r.GetString(2),r.GetString(3),r.GetString(4),r.GetDouble(5)));return a;}
}
sealed class OllamaClient{
 readonly HttpClient h;public bool Available{get;private set;}public string Model=>Environment.GetEnvironmentVariable("OLLAMA_MODEL")??"qwen3:1.7b";
 public OllamaClient(HttpClient h,IConfiguration c){this.h=h;h.BaseAddress=new Uri(Environment.GetEnvironmentVariable("OLLAMA_BASE_URL")??"http://127.0.0.1:11434");}
 public async Task<string> Answer(string question,IReadOnlyList<Chunk> chunks,CancellationToken t){var context=string.Join("\n\n",chunks.Select(x=>$"[FUENTE {x.Source}]\n{x.Content}"));var body=new{model=Model,stream=false,think=false,options=new{temperature=0,num_predict=180},messages=new[]{new{role="system",content="Responde en español de forma breve y concreta. Usa SOLO el contexto proporcionado. No copies el manual completo. Da directamente el valor, paso o procedimiento solicitado. Si hay varias condiciones, usa una lista corta. Termina con Fuente: y la página del PDF. Si el contexto no responde a la pregunta, di que no hay información suficiente."},new{role="user",content=$"PREGUNTA:\n{question}\n\nCONTEXTO:\n{context}"}}};try{using var r=await h.PostAsJsonAsync("/api/chat",body,t);r.EnsureSuccessStatusCode();using var j=JsonDocument.Parse(await r.Content.ReadAsStreamAsync(t));Available=true;return j.RootElement.GetProperty("message").GetProperty("content").GetString()??"Sin respuesta.";}catch(HttpRequestException){Available=false;return Extract(chunks);}catch(TaskCanceledException){Available=false;return Extract(chunks);}}
 static string Extract(IReadOnlyList<Chunk> c){var x=c[0];var lines=x.Content.Split('\n').Where(v=>v.Trim().Length>0).Take(12);return string.Join(" ",lines)+$"\n\nFuente: {x.Source}";}
}
static class OpenAi{ }
