using System.Text.Json.Serialization;

namespace Floto.Api.Notes
{
    public record Note
    {
        public static string DateFormat => "yyyyMMdd";

        [JsonPropertyName("id")]
        public string Id { get; init; } = Guid.NewGuid().ToString();

        [JsonPropertyName("timestamp")]
        public DateTime Timestamp { get; init; } = DateTime.UtcNow;

        [JsonPropertyName("date")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenReading)]
        public string Date => Timestamp.ToString(DateFormat);

        [JsonPropertyName("category")]
        public required NoteCategory Category { get; init; }

        [JsonPropertyName("content")]
        public required string Content { get; init; }

        [JsonPropertyName("lattitude")]
        public double? Lattitude { get; init; }

        [JsonPropertyName("longitude")]
        public double? Longitude { get; init; }
    }
}
