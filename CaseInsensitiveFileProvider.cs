using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.FileProviders.Physical;
using Microsoft.Extensions.Primitives;

namespace CaseDropper;

public sealed class CaseInsensitiveFileProvider : IFileProvider, IDisposable
{
    private readonly PhysicalFileProvider _inner;
    private readonly string _root;
    private volatile Dictionary<string, string> _pathMap;
    private readonly FileSystemWatcher _watcher;
    private readonly Timer _debounce;
    private static readonly TimeSpan DebounceInterval = TimeSpan.FromSeconds(1);

    public CaseInsensitiveFileProvider(string root)
    {
        _root = Path.GetFullPath(root);
        _inner = new PhysicalFileProvider(_root);
        _pathMap = BuildPathMap(_root);

        _debounce = new Timer(_ => Rebuild(), null, Timeout.Infinite, Timeout.Infinite);

        _watcher = new FileSystemWatcher(_root)
        {
            IncludeSubdirectories = true,
            NotifyFilter = NotifyFilters.FileName | NotifyFilters.DirectoryName,
        };
        _watcher.Created += OnChange;
        _watcher.Deleted += OnChange;
        _watcher.Renamed += OnChange;
        _watcher.EnableRaisingEvents = true;
    }

    public IFileInfo GetFileInfo(string subpath)
    {
        var resolved = Resolve(subpath);
        return _inner.GetFileInfo(resolved);
    }

    public IDirectoryContents GetDirectoryContents(string subpath)
    {
        var resolved = Resolve(subpath);
        return _inner.GetDirectoryContents(resolved);
    }

    public IChangeToken Watch(string filter) => _inner.Watch(filter);

    private void OnChange(object sender, FileSystemEventArgs e)
    {
        _debounce.Change(DebounceInterval, Timeout.InfiniteTimeSpan);
    }

    private void Rebuild()
    {
        try
        {
            _pathMap = BuildPathMap(_root);
            Console.WriteLine($"Path map rebuilt ({_pathMap.Count} entries)");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Failed to rebuild path map: {ex.Message}");
        }
    }

    private string Resolve(string subpath)
    {
        if (string.IsNullOrEmpty(subpath))
            return subpath;

        var normalized = subpath.Replace('\\', '/').TrimStart('/');
        var key = normalized.ToLowerInvariant();

        return _pathMap.TryGetValue(key, out var actual) ? "/" + actual : subpath;
    }

    private static Dictionary<string, string> BuildPathMap(string root)
    {
        var map = new Dictionary<string, string>(StringComparer.Ordinal);
        var rootDir = new DirectoryInfo(root);

        if (!rootDir.Exists)
            return map;

        foreach (var file in rootDir.EnumerateFiles("*", SearchOption.AllDirectories))
        {
            var relative = Path.GetRelativePath(root, file.FullName).Replace('\\', '/');
            map[relative.ToLowerInvariant()] = relative;
        }

        foreach (var dir in rootDir.EnumerateDirectories("*", SearchOption.AllDirectories))
        {
            var relative = Path.GetRelativePath(root, dir.FullName).Replace('\\', '/');
            map[relative.ToLowerInvariant()] = relative;
        }

        return map;
    }

    public void Dispose()
    {
        _watcher.Dispose();
        _debounce.Dispose();
        _inner.Dispose();
    }
}
