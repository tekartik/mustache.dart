# mustache.dart

Yet another lightweight Mustache renderer.

Features:
* Lambdas and partials can be asynchronous
* No mirrors nor reflectable, using plain map
* Partials have a context to allow any resolving method (such as relative file path)

# mustache_fs.dart

FileSystem based renderer to allow for a file based templating system