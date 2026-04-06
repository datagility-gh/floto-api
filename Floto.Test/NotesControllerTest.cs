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

    [Fact(DisplayName = "Get with invalid date returns BadRequest")]
    public async Task Get_InvalidDate_ReturnsBadRequest()
    {
        //Arrange
        var controller = new NotesController(
            mockRepository.Object,
            mockLogger.Object);

        // Act
        var result = await controller.Get("invalid-date");

        // Assert
        result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact(DisplayName = "Get with valid date returns notes")]
    public async Task Get_ValidDate_ReturnsNotes()
    {
        //Arrange
        mockRepository.Setup(r => r.GetAsync(It.IsAny<DateOnly>())).ReturnsAsync(new List<Note>
        {
            new Note { Id = "1", Category = NoteCategory.General, Content = "Note 1" },
            new Note { Id = "2", Category = NoteCategory.General, Content = "Note 2" }
        });

        var controller = new NotesController(
            mockRepository.Object,
            mockLogger.Object);

        // Act
        var result = await controller.Get("20260430");

        // Assert
        result.Should().BeOfType<OkObjectResult>();
        var okResult = (OkObjectResult)result;
        okResult.Value.Should().BeOfType<List<Note>>();
        var notes = (List<Note>)okResult.Value;
        notes.Should().HaveCount(2);
    }
}
