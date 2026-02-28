NAME = inception
COMPOSE = docker compose -p $(NAME) -f srcs/docker-compose.yml --env-file srcs/.env
DATA_PATH = data

all: up

up:
	mkdir -p $(DATA_PATH)/mariadb
	mkdir -p $(DATA_PATH)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

restart: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean: down

vclean:
	-$(COMPOSE) down --remove-orphans
	-docker volume rm $(NAME)_mariadb_data $(NAME)_wordpress_data 2>/dev/null || true

fclean:
	$(COMPOSE) down -v --remove-orphans
	rm -rf $(DATA_PATH)/mariadb
	rm -rf $(DATA_PATH)/wordpress

re: fclean up

.PHONY: all up down restart logs ps clean vclean fclean re
