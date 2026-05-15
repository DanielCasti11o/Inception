# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: dacastil <dacastil@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/05/15 16:48:02 by dacastil          #+#    #+#              #
#    Updated: 2026/05/15 17:01:49 by dacastil         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME= inception
COMPOSE_FILE= srcs/docker-compose.yml

GREEN= \033[0;32m
RESET= \033[0m
RED= \033[0;31m
YELLOW = \033[0;33m

all: build up # CONSTRUYE Y ARRANCA

build: # CONSTRUYE

	@echo "$(GREEN)Building the images... $(RESET)"
	@docker compose -f $(COMPOSE_FILE) build

up: # ARRANCA
	@echo "$(GREEN)Uploading containers... $(RESET)"
	@docker compose -f $(COMPOSE_FILE) up -d

down: # DETIENE Y ELIMINA
	@echo "$(RED) stopping and removing containers... $(RESET)"
	@docker compose -f $(COMPOSE_FILE) down

status:
	@echo "$(YELLOW) Status of containers $(RESET)"
	@docker compose -f $(COMPOSE_FILE) ps

logs:
	@echo "$(YELLOW) Logs: $(RESET)"
	@docker compose -f $(COMPOSE_FILE) logs -f

clean: down

fclean:
	@echo "$(RED) deep cleaning... $(RESET)"
	@docker system prune -a --volumes -f

re: fclean all

.PHONY all build up down status logs clean fclean re
