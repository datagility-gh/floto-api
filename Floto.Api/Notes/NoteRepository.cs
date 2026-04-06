using Floto.Api.Settings;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Options;

namespace Floto.Api.Notes
{
    public class NoteRepository : INoteRepository
    {
        private readonly CosmosDbSettings cosmosDbSettings;

        private readonly Container container;

        public NoteRepository(
            CosmosClient cosmosClient,
            IOptions<CosmosDbSettings> options)
        {
            cosmosDbSettings = options.Value;

            var database = cosmosClient.GetDatabase(cosmosDbSettings.DatabaseId);

            container = database.GetContainer(cosmosDbSettings.ContainerId);
        }

        public async Task<Note> CreateAsync(Note note)
        {
            var response = await container.CreateItemAsync(note);

            return response.Resource;
        }

        public async Task<IEnumerable<Note>> GetAsync(DateOnly date)
        {
            var query = $"SELECT * FROM n WHERE n.date = @date";

            var queryDefinition = new QueryDefinition(query)
                .WithParameter("@date", date.ToString(Note.DateFormat));

            using FeedIterator<Note> feed = container.GetItemQueryIterator<Note>(
                queryDefinition
            );

            var items = new List<Note>();
            while (feed.HasMoreResults)
            {
                var response = await feed.ReadNextAsync();
                foreach (Note item in response)
                {
                    items.Add(item);
                }
            }

            return items;
        }
    }
}
