namespace GreetingService;

/// <summary>A tiny greeting library, kept separate from the Functions
/// project so it can be unit tested without the Functions runtime.</summary>
public static class Greeter
{
    public static string Greet(string? name) =>
        string.IsNullOrWhiteSpace(name) ? "Hello, world!" : $"Hello, {name.Trim()}!";
}
