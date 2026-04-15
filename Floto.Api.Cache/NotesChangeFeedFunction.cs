using Floto.Api.Notes;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Floto.Api.Cache;

public class NotesChangeFeedFunction
{
    private readonly ILogger<NotesChangeFeedFunction> logger;

    public NotesChangeFeedFunction(ILogger<NotesChangeFeedFunction> logger)
    {
        this.logger = logger;
    }

    [Function("NotesChangeFeedFunction")]
    public void Run([CosmosDBTrigger(
        databaseName: "local-sqldb-floto",
        containerName: "notes",
        Connection = "COSMOSDB_CONNECTION_STRING",
        LeaseContainerName = "leases",
        CreateLeaseContainerIfNotExists = true)] IReadOnlyList<Note> input)
    {
        if (input != null && input.Count > 0)
        {
            logger.LogInformation("Documents modified: " + input.Count);
            logger.LogInformation("First document Id: " + input[0].Id);
        }
    }
}
