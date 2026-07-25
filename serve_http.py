"""Simple HTTP server for Flutter web build on port 8080."""
import http.server
import os
import sys


def main():
    port = 8080
    directory = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "frontend",
        "build",
        "web",
    )

    if not os.path.isdir(directory):
        print(f"Error: directorio no encontrado: {directory}")
        print("Ejecuta primero: cd frontend && flutter build web")
        sys.exit(1)

    os.chdir(directory)

    handler = http.server.SimpleHTTPRequestHandler
    server = http.server.HTTPServer(("0.0.0.0", port), handler)

    print(f"Servidor HTTP iniciado en http://localhost:{port}")
    print(f"Sirviendo: {directory}")
    print("Ctrl+C para detener")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
        server.shutdown()


if __name__ == "__main__":
    main()
