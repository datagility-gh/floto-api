using System.Reflection;

using Azure.Monitor.OpenTelemetry.AspNetCore;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;
using Microsoft.FeatureManagement;
using Microsoft.OpenApi;

using Floto.Api.Settings;
using Floto.Api.Notes;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddEnvironmentVariables();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Version = "v1",
        Title = "Floto",
        Description = "API for building and getting flows",
    });
});

builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var appInsightsCxn = builder.Configuration.GetValue<string>("APPLICATIONINSIGHTS_CONNECTION_STRING");
if (appInsightsCxn != null)
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor();
    builder.Logging.AddOpenTelemetry();

    builder.Logging.Services.Configure<LoggerFilterOptions>(options =>
        {
            LoggerFilterRule? defaultRule = options.Rules.FirstOrDefault(rule => rule.ProviderName
                == "Microsoft.Extensions.Logging.ApplicationInsights.ApplicationInsightsLoggerProvider");
            if (defaultRule != null)
            {
                options.Rules.Remove(defaultRule);
            }
        });
}

var appConfigCxn = builder.Configuration.GetValue<string>("APPLICATIONCONFIG_CONNECTION_STRING");
if (appConfigCxn != null)
{
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options.Connect(appConfigCxn)
            // Load configuration values with no label
            .Select(KeyFilter.Any, LabelFilter.Null)
            // Override with any configuration values specific to the current stack
            .Select(KeyFilter.Any, builder.Configuration.GetValue<string>("Stack"));
        options.UseFeatureFlags();
    });

    builder.Services.AddAzureAppConfiguration();
}

var cosmosDbCxn = builder.Configuration.GetValue<string>("COSMOSDB_CONNECTION_STRING");
if (cosmosDbCxn == null)
{
    throw new InvalidOperationException("Cosmos DB connection string is not configured. Please set the 'COSMOSDB_CONNECTION_STRING' environment variable.");
}

builder.Services.AddSingleton(sp =>
{
    CosmosClientOptions cosmosClientOptions = new CosmosClientOptions
    {
        // Direct mode is recommended for private endpoints, but it doesn't work with
        // the Cosmos DB emulator
        ConnectionMode = builder.Environment.IsDevelopment() ?
            ConnectionMode.Gateway : ConnectionMode.Direct,
        SerializerOptions = new CosmosSerializationOptions
        {
            PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase,
        }
    };

    return new CosmosClient(cosmosDbCxn, cosmosClientOptions);
});

builder.Services.AddFeatureManagement();

builder.Services.Configure<CosmosDbSettings>(builder.Configuration.GetSection("CosmosDb"));

builder.Services.AddScoped<INoteRepository, NoteRepository>();

builder.Services.AddControllers();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "v1");
        options.RoutePrefix = string.Empty;
    });
}

app.Configuration["Version"] = Assembly.GetEntryAssembly()?
    .GetCustomAttribute<AssemblyFileVersionAttribute>()?.Version;

app.UseRouting();

app.UsePathBase("/api");

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
