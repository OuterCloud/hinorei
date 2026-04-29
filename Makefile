.PHONY: setup frontend-install frontend-dev frontend-build dev start stop restart status logs

setup:
	git config core.hooksPath .githooks
	@if [ ! -f .sensitive-patterns ]; then \
		cp .sensitive-patterns.example .sensitive-patterns; \
		echo "已生成 .sensitive-patterns，请填入实际敏感词。"; \
	fi
	@echo "Git hooks 已配置，敏感信息拦截规则生效。"

frontend-install:
	cd frontend && npm install

frontend-dev:
	cd frontend && npm run dev

frontend-build:
	cd frontend && npm run build

dev: frontend-build
	uvicorn app.main:app --reload

start:
	./deploy.sh start

stop:
	./deploy.sh stop

restart:
	./deploy.sh restart

status:
	./deploy.sh status

logs:
	./deploy.sh logs -f
