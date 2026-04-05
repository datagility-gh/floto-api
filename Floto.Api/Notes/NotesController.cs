using Microsoft.AspNetCore.Mvc;

namespace Floto.Api.Notes
{
    [ApiController]
    [Route("v1/notes")]
    public class NotesController : ControllerBase
    {
        private readonly INoteRepository _repository;

        private readonly ILogger<NotesController> logger;

        public NotesController(
            INoteRepository repository,
            ILogger<NotesController> logger)
        {
            _repository = repository;
            this.logger = logger;
        }

        [HttpPost]
        [ProducesResponseType(StatusCodes.Status201Created, Description = "The note was created successfully.")]
        public async Task<IActionResult> Post([FromBody] Note note)
        {
            logger.LogDebug("starting Post - {Note}", note);

            var created = await _repository.CreateAsync(note);

            return CreatedAtAction(nameof(Post), new { id = created.Id }, created);
        }
    }
}
