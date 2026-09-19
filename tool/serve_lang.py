"""Sert l'application compilee en forcant une langue.

AIDE AU TEST — a retirer avant la mise en production.

Un port par langue, pour comparer les trois versions cote a cote sans
toucher a l'URL. Le script sert `build/web` tel quel et se contente
d'injecter, dans `index.html`, un court script qui pose `?lang=xx` avant
le demarrage de Flutter. L'app lit ce parametre au demarrage : la langue
est donc deja choisie au premier ecran, sans rechargement.

    python tool/serve_lang.py 8081 fr

Le repertoire servi est `build/web`, relatif a la racine du projet.
"""

import functools
import http.server
import pathlib
import socketserver
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent / "build" / "web"

# Pose la langue avant le chargement de Flutter. `replaceState` evite un
# aller-retour : l'URL est corrigee sur place, la page ne recharge pas.
GABARIT = """<script>
  (function () {
    var u = new URL(window.location.href);
    if (u.searchParams.get('lang') !== '%s') {
      u.searchParams.set('lang', '%s');
      window.history.replaceState(null, '', u.toString());
    }
  })();
</script>
"""


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, langue="fr", **kwargs):
        self.langue = langue
        super().__init__(*args, directory=str(RACINE), **kwargs)

    def do_GET(self):  # noqa: N802 — nom impose par la bibliotheque
        chemin = self.path.split("?")[0]
        if chemin in ("/", "/index.html"):
            self.servir_index()
            return
        super().do_GET()

    def servir_index(self):
        page = (RACINE / "index.html").read_text(encoding="utf-8")
        injection = GABARIT % (self.langue, self.langue)
        page = page.replace("<head>", "<head>\n" + injection, 1)
        corps = page.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(corps)))
        # Pas de cache : les rebuilds doivent se voir au rafraichissement.
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(corps)

    def log_message(self, *args):
        pass  # sortie silencieuse : trois serveurs en parallele


class Serveur(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    port = int(sys.argv[1])
    langue = sys.argv[2]
    with Serveur(("127.0.0.1", port), functools.partial(Handler, langue=langue)) as s:
        print(f"{langue} -> http://127.0.0.1:{port}", flush=True)
        s.serve_forever()
