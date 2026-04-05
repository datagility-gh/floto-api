namespace Floto.Api.Notes
{
    public interface INoteRepository
    {
        Task<Note> CreateAsync(Note note);
    }
}
