.PHONY: help run migrate makemigrations test shell superuser docker-up docker-down clean

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

run: ## Run development server
	python manage.py runserver

migrate: ## Run database migrations
	python manage.py migrate

makemigrations: ## Create new migrations
	python manage.py makemigrations

test: ## Run tests
	python manage.py test --settings=config.settings.testing

shell: ## Open Django shell
	python manage.py shell

superuser: ## Create a superuser
	python manage.py createsuperuser

docker-up: ## Start Docker containers
	docker compose up -d

docker-down: ## Stop Docker containers
	docker compose down

docker-build: ## Build Docker image
	docker compose build

clean: ## Remove compiled Python files
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; \
	find . -type f -name "*.pyc" -delete 2>/dev/null; \
	rm -rf staticfiles/ 2>/dev/null; \
	echo "Cleaned!"

check-deploy: ## Check production deployment settings
	python manage.py check --deploy --settings=config.settings.production
