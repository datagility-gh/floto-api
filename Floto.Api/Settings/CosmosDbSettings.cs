namespace Floto.Api.Settings
{
    public record CosmosDbSettings
    {
        public required string DatabaseId { get; init; }
        public required string ContainerId { get; init; }
    }
}
