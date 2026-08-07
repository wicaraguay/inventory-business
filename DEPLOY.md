# Deploy en VPS (Contabo · Ubuntu · Nginx del host)

La app corre en Docker escuchando **solo en `127.0.0.1`** del VPS. El **Nginx del
host** publica un subdominio con **HTTPS** (certbot) y una **contraseña** (basic
auth) — el mismo esquema que tus otras apps.

```
Internet → Nginx host (HTTPS + password)
             ├─ /        → web  (Flutter, 127.0.0.1:8091)
             └─ /api/*   → backend (Dart Frog, 127.0.0.1:8090)
           Postgres: interno (sin puerto expuesto)
```

Reemplazá `inventy.tudominio.com` por tu subdominio real (DNS `A` → IP del VPS).

---

## 1) Clonar en el VPS
```bash
cd /opt
git clone git@github.com:wicaraguay/inventory-business.git inventy
cd inventy
```

## 2) `.env` de producción (contraseñas NUEVAS y fuertes)
```bash
cat > .env <<'EOF'
DB_HOST=postgres
DB_NAME=inventy
DB_USER=inventy
DB_PASSWORD=CAMBIA_por_una_fuerte
JWT_SECRET=CAMBIA_por_un_secreto_largo_aleatorio
# URL pública del backend (a través del proxy):
WEB_API_BASE_URL=https://inventy.tudominio.com/api
# Credencial del basic-auth del proxy (mismo user:pass del htpasswd del paso 6):
WEB_API_AUTH=inventy:CAMBIA_password_web
EOF
```

## 3) Postgres + migraciones
```bash
docker compose -f docker-compose.prod.yml up -d postgres
docker compose -f docker-compose.prod.yml run --rm migrate up
```

## 4) (Opcional) Restaurar tus datos actuales
En tu **PC** (Git Bash, con el stack local corriendo):
```bash
docker compose exec -T postgres pg_dump -U inventy inventy > inventy_dump.sql
scp inventy_dump.sql root@IP_VPS:/opt/inventy/
```
En el **VPS**:
```bash
docker compose -f docker-compose.prod.yml exec -T postgres psql -U inventy -d inventy < inventy_dump.sql
```

## 5) Backend + web (compila la web dentro de Docker)
```bash
docker compose -f docker-compose.prod.yml up -d --build backend web
# chequeo interno:
curl -s -o /dev/null -w 'backend %{http_code}\n' http://127.0.0.1:8090/products
curl -s -o /dev/null -w 'web %{http_code}\n'     http://127.0.0.1:8091/
```

## 6) Contraseña (basic auth)
```bash
command -v htpasswd || apt-get install -y apache2-utils
htpasswd -c /etc/nginx/.htpasswd-inventy inventy   # usa el MISMO password del .env (WEB_API_AUTH)
```

## 7) Nginx del host
```bash
cp deploy/nginx-inventy.conf.example /etc/nginx/sites-available/inventy.conf
sed -i 's/INVENTY_DOMAIN/inventy.tudominio.com/' /etc/nginx/sites-available/inventy.conf
ln -s /etc/nginx/sites-available/inventy.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

## 8) HTTPS
```bash
certbot --nginx -d inventy.tudominio.com
```

## 9) APK móvil (apuntando al VPS)
En tu **PC**:
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://inventy.tudominio.com/api \
  --dart-define=API_AUTH=inventy:CAMBIA_password_web
```
Instalás ese APK en el celular. (La web ya queda lista en `https://inventy.tudominio.com`.)

---

## Actualizar (deploys futuros)
```bash
cd /opt/inventy && git pull
docker compose -f docker-compose.prod.yml up -d --build backend web
docker compose -f docker-compose.prod.yml run --rm migrate up
```

## Notas de seguridad
- La contraseña (basic auth) es la **primera barrera**. El siguiente paso
  recomendado es un **login real (JWT)** dentro de la app.
- Postgres nunca se expone a internet. `.env` NO se sube a git.
- La build de la web dentro de Docker usa bastante RAM (dart2js). Si el VPS
  tiene poca, compilá la web en tu PC y copiá `app/build/web` al VPS.
