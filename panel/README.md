PANEL

```
docker compose up -d

docker compose exec panel bash

python manage.py migrate

python manage.py createsuperuser --username admin --email admin@admin.com

python manage.py aws_update_images

docker compose restart
```
