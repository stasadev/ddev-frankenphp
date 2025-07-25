<?php

// Generated by Claude
// Basic FrankenPHP worker example

// Initialize any global state, connections, etc.
$startTime = time();
$requestCount = 0;

// Database connection pool (example)
$pdo = new PDO('sqlite::memory:');
$pdo->exec('CREATE TABLE IF NOT EXISTS visits (id INTEGER PRIMARY KEY, timestamp INTEGER, path TEXT)');

echo "Worker started at " . date('Y-m-d H:i:s') . "\n";
error_log("FrankenPHP Worker: Started successfully");
file_put_contents('/tmp/worker.log', "Worker started at " . date('Y-m-d H:i:s') . "\n", FILE_APPEND);

// Main worker loop
while (true) {
    // Wait for incoming request
    $request = \frankenphp_handle_request(function() use (&$requestCount, $pdo, $startTime) {
        $requestCount++;

        // Get request information
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $uri = $_SERVER['REQUEST_URI'] ?? '/';
        $path = parse_url($uri, PHP_URL_PATH);
        $query = parse_url($uri, PHP_URL_QUERY);

        // Log the visit
        $stmt = $pdo->prepare('INSERT INTO visits (timestamp, path) VALUES (?, ?)');
        $stmt->execute([time(), $path]);

        // Set response headers
        header('Content-Type: text/html; charset=utf-8');
        header('X-Worker-Uptime: ' . (time() - $startTime) . 's');
        header('X-Request-Count: ' . $requestCount);

        // Simple routing
        switch ($path) {
            case '/':
                handleHome($requestCount, $startTime);
                break;

            case '/api/stats':
                handleStats($pdo, $requestCount, $startTime);
                break;

            case '/api/health':
                handleHealth();
                break;

            case '/visits':
                handleVisits($pdo);
                break;

            case '/worker-test':
                header('Content-Type: text/plain');
                echo "Worker is active! Request #" . $requestCount . "\n";
                echo "Uptime: " . (time() - $startTime) . " seconds\n";
                echo "PID: " . getmypid() . "\n";
                break;

            default:
                handle404($path);
                break;
        }
    });

    // Break the loop if worker should stop
    if ($request === false) {
        break;
    }
}

echo "Worker shutting down...\n";

// Helper functions for handling different routes

function handleHome($requestCount, $startTime) {
    $uptime = time() - $startTime;
    $memoryUsage = formatBytes(memory_get_usage());
    $peakMemory = formatBytes(memory_get_peak_usage());

    echo <<<HTML
<!DOCTYPE html>
<html>
<head>
    <title>FrankenPHP Worker Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .stats { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        .nav a { margin-right: 15px; text-decoration: none; color: #0066cc; }
    </style>
</head>
<body>
    <h1>FrankenPHP Worker Demo</h1>
    <div class="nav">
        <a href="/">Home</a>
        <a href="/api/stats">Stats (JSON)</a>
        <a href="/api/health">Health Check</a>
        <a href="/visits">Visit Log</a>
    </div>

    <div class="stats">
        <h3>Worker Statistics</h3>
        <p><strong>Requests handled:</strong> {$requestCount}</p>
        <p><strong>Uptime:</strong> {$uptime} seconds</p>
        <p><strong>Memory usage:</strong> {$memoryUsage}</p>
        <p><strong>Peak memory:</strong> {$peakMemory}</p>
    </div>

    <h3>Features Demonstrated</h3>
    <ul>
        <li>Persistent worker process</li>
        <li>Shared state across requests</li>
        <li>Database connection pooling</li>
        <li>Simple routing</li>
        <li>Request counting</li>
    </ul>
</body>
</html>
HTML;
}

function handleStats($pdo, $requestCount, $startTime) {
    header('Content-Type: application/json');

    // Get visit count
    $stmt = $pdo->query('SELECT COUNT(*) as total FROM visits');
    $visitCount = $stmt->fetchColumn();

    $stats = [
        'status' => 'ok',
        'uptime_seconds' => time() - $startTime,
        'requests_handled' => $requestCount,
        'total_visits' => $visitCount,
        'memory_usage' => memory_get_usage(),
        'memory_peak' => memory_get_peak_usage(),
        'timestamp' => date('c')
    ];

    echo json_encode($stats, JSON_PRETTY_PRINT);
}

function handleHealth() {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'healthy', 'timestamp' => date('c')]);
}

function handleVisits($pdo) {
    header('Content-Type: text/html; charset=utf-8');

    $stmt = $pdo->query('SELECT * FROM visits ORDER BY timestamp DESC LIMIT 50');
    $visits = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo <<<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Recent Visits</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .nav { margin-bottom: 20px; }
        .nav a { margin-right: 15px; text-decoration: none; color: #0066cc; }
    </style>
</head>
<body>
    <div class="nav">
        <a href="/">← Back to Home</a>
    </div>

    <h1>Recent Visits (Last 50)</h1>
    <table>
        <tr>
            <th>ID</th>
            <th>Timestamp</th>
            <th>Path</th>
        </tr>
HTML;

    foreach ($visits as $visit) {
        $time = date('Y-m-d H:i:s', $visit['timestamp']);
        echo "<tr><td>{$visit['id']}</td><td>{$time}</td><td>" . htmlspecialchars($visit['path']) . "</td></tr>";
    }

    echo <<<HTML
    </table>
</body>
</html>
HTML;
}

function handle404($path) {
    http_response_code(404);
    header('Content-Type: text/html; charset=utf-8');

    echo <<<HTML
<!DOCTYPE html>
<html>
<head>
    <title>404 - Not Found</title>
    <style>body { font-family: Arial, sans-serif; margin: 40px; }</style>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The path <code>" . htmlspecialchars($path) . "</code> was not found.</p>
    <p><a href="/">← Go back home</a></p>
</body>
</html>
HTML;
}

function formatBytes($bytes, $precision = 2) {
    $units = array('B', 'KB', 'MB', 'GB', 'TB');

    for ($i = 0; $bytes > 1024; $i++) {
        $bytes /= 1024;
    }

    return round($bytes, $precision) . ' ' . $units[$i];
}
