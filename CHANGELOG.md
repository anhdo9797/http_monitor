## 0.0.2

### Updated Flutter Support

* **Lowered Flutter Minimum Version**: Reduced minimum Flutter version requirement from 3.24.0 to 3.20.0 for broader compatibility

## 0.0.1

### Initial Release

* **HTTP Interception**: Automatic capture of all HTTP requests and responses
* **Multiple Client Support**: Built-in support for Dio and http.Client
* **SQLite Storage**: Persistent storage with efficient querying and indexing
* **Beautiful UI**: Clean interface for browsing and analyzing logs
  * Color-coded HTTP methods and status codes
  * Pull-to-refresh functionality
  * Advanced filtering by method, status, URL, and date
  * Search functionality with debouncing
* **Log Details**: Comprehensive view of request/response data
  * Expandable sections for headers, parameters, body, and response
  * JSON formatting with syntax highlighting
  * Raw text view toggle
* **cURL Export**: One-tap export of requests as cURL commands
* **Performance Optimized**:
  * Minimal overhead on HTTP requests
  * In-memory caching for recent logs
  * Automatic cleanup of old logs
  * Configurable response body size limits
* **Security**: Automatic sanitization of sensitive headers
* **Configuration**: Multiple preset configurations (development, production, testing)
* **Cross-Platform**: Works on Android, iOS, Web, and Desktop
* **Comprehensive Testing**: 98+ unit and integration tests
* **Documentation**: Complete README with examples and best practices
* **Example App**: Full working example demonstrating all features
