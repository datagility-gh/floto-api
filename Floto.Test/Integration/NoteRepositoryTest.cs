using Floto.Api.Notes;
using Floto.Api.Settings;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Options;

namespace Floto.Test.Integration;

public class NoteRepositoryTest
{
    const string DatabaseId = "local-sqldb-floto";
    const string ContainerId = "sql-cont-floto";

    private readonly INoteRepository noteRepository;

    private readonly Container container;

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

        var cosmosClient = new CosmosClient(
            "AccountEndpoint=http://localhost:8081;AccountKey=C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGg==;",
            cosmosClientOptions);

        container = cosmosClient
                .GetDatabase(DatabaseId)
                .GetContainer(ContainerId);

        CosmosDbSettings cosmosDbSettings = new CosmosDbSettings
        {
            DatabaseId = DatabaseId,
            ContainerId = ContainerId
        };

        noteRepository = new NoteRepository(cosmosClient, Options.Create(cosmosDbSettings));
    }

    [Fact(DisplayName = "CreateAsync creates a note successfully")]
    public async Task CreateAsync_CreatesNoteSuccessfully()
    {
        Note note = null!;

        try
        {
            // Arrange
            note = new Note
            {
                Category = NoteCategory.General,
                Content = "This is a test note."
            };

            // Act
            var createdNote = await noteRepository.CreateAsync(note);

            // Assert
            createdNote.Should().NotBeNull();
            createdNote.Id.Should().Be(note.Id);
            createdNote.Category.Should().Be(note.Category);
            createdNote.Content.Should().Be(note.Content);
        }
        finally
        {
            // Clean up - delete the created note
            await container.DeleteItemAsync<Note>(
                note.Id,
                new PartitionKey(note.Date));
        }
    }

    [Fact(DisplayName = "GetAsync by date retrieves notes successfully")]
    public async Task GetAsync_ByDate_RetrievesNotesSuccessfully()
    {
        IEnumerable<Note> notes = null!;
        try
        {
            // Arrange
            notes = GetTestNotes();
            foreach (var note in notes)
            {
                await container.CreateItemAsync(note);
            }

            // Act
            var retrievedNotes = await noteRepository.GetAsync(DateOnly.FromDateTime(DateTime.UtcNow));

            // Assert
            retrievedNotes.Should().NotBeNull();
            retrievedNotes.Should().NotBeEmpty();
            retrievedNotes.Should().HaveCount(notes.Count());
            retrievedNotes.First().Should().BeEquivalentTo(notes.First());
        }
        finally
        {
            // Clean up - delete all notes for the date
            foreach (var note in notes)
            {
                await container.DeleteItemAsync<Note>(
                    note.Id,
                    new PartitionKey(note.Date));
            }
        }
    }

    private IEnumerable<Note> GetTestNotes()
    {
        return new List<Note>
        {
            new Note
            {
                Category = NoteCategory.General,
                Content = "This is the first test note."
            },
            new Note
            {
                Category = NoteCategory.General,
                Content = "This is the second test note."
            }
        };
    }
}
