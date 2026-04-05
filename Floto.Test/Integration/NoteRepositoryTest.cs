using Floto.Api.Notes;
using Floto.Api.Settings;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Options;

namespace Floto.Test.Integration;

public class NoteRepositoryTest
{
    private readonly INoteRepository noteRepository;

    public NoteRepositoryTest()
    {
        CosmosClientOptions cosmosClientOptions = new CosmosClientOptions
        {
            ConnectionMode = ConnectionMode.Gateway,
            SerializerOptions = new CosmosSerializationOptions
            {
                PropertyNamingPolicy = CosmosPropertyNamingPolicy.CamelCase,
            }
        };

        CosmosClient cosmosClient = new CosmosClient(
            "AccountEndpoint=http://localhost:8081;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGg==;",
            cosmosClientOptions);

        CosmosDbSettings cosmosDbSettings = new CosmosDbSettings
        {
            DatabaseId = "local-sqldb-floto",
            ContainerId = "sql-cont-floto"
        };

        noteRepository = new NoteRepository(cosmosClient, Options.Create(cosmosDbSettings));
    }

    [Fact(DisplayName = "CreateAsync creates a note successfully")]
    public async Task CreateAsync_CreatesNoteSuccessfully()
    {
        // Arrange
        Note note = new Note
        {
            Category = NoteCategory.General,
            Content = "This is a test note."
        };

        // Act
        Note createdNote = await noteRepository.CreateAsync(note);

        // Assert
        createdNote.Should().NotBeNull();
        createdNote.Id.Should().Be(note.Id);
        createdNote.Category.Should().Be(note.Category);
        createdNote.Content.Should().Be(note.Content);
    }
}
