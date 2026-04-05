using Floto.Api.Settings;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Options;

namespace Floto.Api.Notes
{
    public class NoteRepository : INoteRepository
    {
        private readonly CosmosClient cosmosClient;
        private readonly CosmosDbSettings cosmosDbSettings;

        public NoteRepository(
            CosmosClient cosmosClient,
            IOptions<CosmosDbSettings> options)
        {
            cosmosDbSettings = options.Value;
            this.cosmosClient = cosmosClient;
        }

        public async Task<Note> CreateAsync(Note note)
        {
            var database = cosmosClient.GetDatabase(cosmosDbSettings.DatabaseId);

            var container = database.GetContainer(cosmosDbSettings.ContainerId);

            var response = await container.CreateItemAsync(note);

            return response.Resource;
        }
    }
}
