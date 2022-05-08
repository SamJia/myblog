PROJECT_NAME = myblog

install:
	bundle install --path vendor/bundle

build:
	bundle exec jekyll build

#dev: install
dev:
	bundle exec jekyll serve --drafts

docker-run:
	docker-compose -p ${PROJECT_NAME} up -d

docker-stop:
	docker-compose -p ${PROJECT_NAME} stop

docker-down:
	docker-compose -p ${PROJECT_NAME} down
