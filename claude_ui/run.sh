#!/bin/bash
docker-compose build --no-cache sandbox
docker-compose up -d
docker exec -it vibe-sandbox ps aux

# Stop containers and DELETE the volumes (this clears the corrupt .antigravity-server)
docker-compose down -v

# Force a rebuild with the new Microsoft image
docker-compose up -d --build