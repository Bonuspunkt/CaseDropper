using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.FileProviders.Physical;
using Microsoft.Extensions.Primitives;

namespace CaseDropper;

public sealed class CaseInsensitiveFileProvider : IFileProvider, IDisposable
{
    private readonly PhysicalFileProvider _inner;
    private readonly string _root;
    private readonly Dictionary<string, string> _pathMap;

    public CaseInsensitiveFileProvider(string root)
    {
        _root = Path.GetFullPath(root);
        _inner = new PhysicalFileProvider(_root);
        _pathMap = BuildPathMap(_root);
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

    public void Dispose() => _inner.Dispose();
}
