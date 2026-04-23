.PHONY: setup

setup:
	git config core.hooksPath .githooks
	@if [ ! -f .sensitive-patterns ]; then \
		cp .sensitive-patterns.example .sensitive-patterns; \
		echo "已生成 .sensitive-patterns，请填入实际敏感词。"; \
	fi
	@echo "Git hooks 已配置，敏感信息拦截规则生效。"
