"""Serve the compiled mobUI browser preview without starting another backend."""
import from pathlib { Path }
import from functools { partial }
import from http.server { ThreadingHTTPServer, SimpleHTTPRequestHandler }

with entry {
    assets = Path.cwd() / ".jac" / "client" / "mobile" / "dist";
    if not (assets / "index.html").is_file() {
        print("Build mobile first: jac build mobile --platform web");
        raise SystemExit(1);
    }
    handler = partial(SimpleHTTPRequestHandler, directory=str(assets));
    server = ThreadingHTTPServer(("127.0.0.1", 8002), handler);
    print("Studyline mobile preview: http://localhost:8002", flush=True);
    print("Keep the planner backend running with jac run on port 8000.", flush=True);
    try { server.serve_forever(); }
    except KeyboardInterrupt { server.server_close(); }
}
