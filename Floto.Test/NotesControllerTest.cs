using Floto.Api.Notes;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Floto.Test;

public class NotesControllerTest
{
    private readonly Mock<INoteRepository> mockRepository;
    private readonly Mock<ILogger<NotesController>> mockLogger;

    public NotesControllerTest()
    {
        mockRepository = new Mock<INoteRepository>();
        mockLogger = new Mock<ILogger<NotesController>>();
    }

    [Fact(DisplayName = "Post with valid note creates note and returns CreatedAtAction")]
    public async Task Post_ValidNote_CreatesAndReturnsCreatedAtAction()
    {
        // Arrange
        var note = new Note
        {
            Category = NoteCategory.General,
            Content = "Test content"
        };
        var createdNote = note with { Id = "test-id" };
        mockRepository.Setup(r => r.CreateAsync(note)).ReturnsAsync(createdNote);
        var controller = new NotesController(
            mockRepository.Object,
            mockLogger.Object);

        // Act
        var result = await controller.Post(note);

        // Assert
        result.Should().BeOfType<CreatedAtActionResult>();
        var createdResult = (CreatedAtActionResult)result;
        createdResult.ActionName.Should().Be(nameof(NotesController.Post));
        createdResult.RouteValues.Should().ContainKey("id").WhoseValue.Should().Be("test-id");
        createdResult.Value.Should().Be(createdNote);
    }
}