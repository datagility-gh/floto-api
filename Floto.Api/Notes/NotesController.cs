using Microsoft.AspNetCore.Mvc;

namespace Floto.Api.Notes
{
    [ApiController]
    [Route("v1/notes")]
    public class NotesController : ControllerBase
    {
        private readonly INoteRepository repository;

        private readonly ILogger<NotesController> logger;

        public NotesController(
            INoteRepository repository,
            ILogger<NotesController> logger)
        {
            this.repository = repository;
            this.logger = logger;
        }

        [HttpPost]
        [ProducesResponseType(StatusCodes.Status201Created, Description = "The note was created successfully.")]
        public async Task<IActionResult> Post([FromBody] Note note)
        {
            logger.LogDebug("starting Post - {Note}", note);

            var created = await repository.CreateAsync(note);

            return CreatedAtAction(nameof(Post), new { id = created.Id }, created);
        }

        [HttpGet]
        [Route("{date}")]
        [Produces("application/json")]
        [ProducesResponseType(StatusCodes.Status200OK, Description = "The notes were retrieved successfully.")]
        [ProducesResponseType(StatusCodes.Status400BadRequest, Description = "Invalid date format.")]
        public async Task<IActionResult> Get(string date)
        {
            logger.LogDebug("starting Get - {Date}", date);

            if (!DateOnly.TryParseExact(date, Note.DateFormat, out DateOnly parsedDate))
            {
                return BadRequest($"Invalid date format. Please use the format '{Note.DateFormat}'.");
            }

            var notes = await repository.GetAsync(parsedDate);

            return Ok(notes);
        }
    }
}
