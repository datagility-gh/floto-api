using Floto.Api.Notes;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Floto.Api.Cache;

public class NotesChangeFeedFunction
{
    private readonly ILogger<NotesChangeFeedFunction> _logger;

    public NotesChangeFeedFunction(ILogger<NotesChangeFeedFunction> logger)
    {
        _logger = logger;
    }

    [Function("NotesChangeFeedFunction")]
    public void Run([CosmosDBTrigger(
        databaseName: "databaseName",
        containerName: "containerName",
        Connection = "",
        LeaseContainerName = "leases",
        CreateLeaseContainerIfNotExists = true)] IReadOnlyList<Note> input)
    {
        if (input != null && input.Count > 0)
        {
            _logger.LogInformation("Documents modified: " + input.Count);
            _logger.LogInformation("First document Id: " + input[0].Id);
        }
    }
}
