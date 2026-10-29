using GreetingService;

namespace GreetingService.Tests;

public class GreeterTests
{
    [Fact]
    public void Greet_WithName_ReturnsPersonalGreeting()
    {
        Assert.Equal("Hello, Ada!", Greeter.Greet("Ada"));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Greet_WithoutName_FallsBackToWorld(string? name)
    {
        Assert.Equal("Hello, world!", Greeter.Greet(name));
    }

    [Fact]
    public void Greet_TrimsSurroundingWhitespace()
    {
        Assert.Equal("Hello, Ada!", Greeter.Greet("  Ada  "));
    }
}
