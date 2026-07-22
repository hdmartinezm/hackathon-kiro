"""Simple HTTPS server for Flutter web build on port 8443."""
import http.server
import ssl
import os
import sys


def main():
    port = 8443
    directory = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "flutter_app",
        "build",
        "web",
    )

    if not os.path.isdir(directory):
        print(f"Error: directorio no encontrado: {directory}")
        print("Ejecuta primero: cd flutter_app && flutter build web")
        sys.exit(1)

    os.chdir(directory)

    handler = http.server.SimpleHTTPRequestHandler

    # Generar certificado self-signed si no existe
    cert_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cert.pem")
    key_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "key.pem")

    if not os.path.exists(cert_file) or not os.path.exists(key_file):
        print("Generando certificado self-signed...")
        os.system(
            f'openssl req -x509 -newkey rsa:2048 -keyout {key_file} '
            f'-out {cert_file} -days 365 -nodes '
            f'-subj "/CN=localhost"'
        )

    server = http.server.HTTPServer(("0.0.0.0", port), handler)

    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(cert_file, key_file)
    server.socket = context.wrap_socket(server.socket, server_side=True)

    print(f"Servidor HTTPS iniciado en https://0.0.0.0:{port}")
    print(f"Sirviendo: {directory}")
    print("Ctrl+C para detener")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
        server.shutdown()


if __name__ == "__main__":
    main()
