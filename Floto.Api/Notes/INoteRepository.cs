namespace Floto.Api.Notes
{
    public interface INoteRepository
    {
        Task<Note> CreateAsync(Note note);

        Task<IEnumerable<Note>> GetAsync(DateOnly date);
    }
}
