using System.Net;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Extensions.FileProviders;
using CaseDropper;

var wwwroot = Environment.GetEnvironmentVariable("WWWROOT") ?? "wwwroot";
var portStr = Environment.GetEnvironmentVariable("PORT") ?? "8080";
var enableDirBrowsing = Environment.GetEnvironmentVariable("ENABLE_DIRECTORY_BROWSING");

if (!int.TryParse(portStr, out var port) || port < 1 || port > 65535)
{
    Console.Error.WriteLine($"Invalid PORT value: '{portStr}'. Must be 1-65535.");
    return 1;
}

var resolvedRoot = Path.GetFullPath(wwwroot);
if (!Directory.Exists(resolvedRoot))
{
    Console.Error.WriteLine($"WWWROOT directory does not exist: {resolvedRoot}");
    return 1;
}

var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();

builder.WebHost.ConfigureKestrel(options =>
{
    options.Listen(IPAddress.Any, port, listenOptions =>
    {
        listenOptions.Protocols = HttpProtocols.Http1;
    });
});

var fileProvider = new CaseInsensitiveFileProvider(resolvedRoot);
builder.Services.AddSingleton<IFileProvider>(fileProvider);

var dirBrowsingEnabled = string.Equals(enableDirBrowsing, "true", StringComparison.OrdinalIgnoreCase)
                         || enableDirBrowsing == "1";
if (dirBrowsingEnabled)
    builder.Services.AddDirectoryBrowser();

var app = builder.Build();

app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = fileProvider });
app.UseStaticFiles(new StaticFileOptions { FileProvider = fileProvider });

if (dirBrowsingEnabled)
    app.UseDirectoryBrowser(new DirectoryBrowserOptions { FileProvider = fileProvider });

Console.WriteLine($"Serving files from: {resolvedRoot}");
Console.WriteLine($"Listening on:       http://0.0.0.0:{port}");
Console.WriteLine($"Protocols:          HTTP/1.0, HTTP/1.1");
Console.WriteLine($"Directory browsing: {(dirBrowsingEnabled ? "enabled" : "disabled")}");

app.Run();

return 0;
