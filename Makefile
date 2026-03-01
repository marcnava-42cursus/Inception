NAME = inception
ENV_FILE = srcs/.env
COMPOSE = docker compose -p $(NAME) -f srcs/docker-compose.yml --env-file srcs/.env
DATA_PATH = $(shell [ -f $(ENV_FILE) ] && sed -n 's/^DATA_PATH=//p' $(ENV_FILE))

ifeq ($(strip $(DATA_PATH)),)
DATA_PATH = ../data
endif

ifeq ($(filter /%,$(DATA_PATH)),)
HOST_DATA_PATH = $(abspath srcs/$(DATA_PATH))
else
HOST_DATA_PATH = $(DATA_PATH)
endif

all: up

up:
	mkdir -p $(HOST_DATA_PATH)/mariadb
	mkdir -p $(HOST_DATA_PATH)/wordpress
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
	rm -rf $(HOST_DATA_PATH)/mariadb
	rm -rf $(HOST_DATA_PATH)/wordpress

re: fclean up

.PHONY: all up down restart logs ps clean vclean fclean re
