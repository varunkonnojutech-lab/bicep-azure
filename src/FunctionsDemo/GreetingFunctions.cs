using System.Net;
using GreetingService;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace FunctionsDemo;

/// <summary>
/// Two HTTP-triggered functions — the workload that APIM fronts.
/// GET /api/health -> {"status":"ok"}
/// GET /api/greet?name=Ada -> {"greeting":"Hello, Ada!"}
/// </summary>
public class GreetingFunctions(ILogger<GreetingFunctions> logger)
{
    [Function("Health")]
    public HttpResponseData Health(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "health")] HttpRequestData req)
    {
        logger.LogInformation("Health check requested.");
        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json");
        response.WriteString("""{"status":"ok"}""");
        return response;
    }

    [Function("Greet")]
    public HttpResponseData Greet(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "greet")] HttpRequestData req)
    {
        // System.Web is unavailable in the isolated worker, so parse the
        // query string by hand instead of reaching for a helper package.
        var name = req.Query["name"];
        var greeting = Greeter.Greet(name);
        logger.LogInformation("Greeted {Name}", string.IsNullOrWhiteSpace(name) ? "world" : name);

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json");
        response.WriteString(System.Text.Json.JsonSerializer.Serialize(new { greeting }));
        return response;
    }
}
