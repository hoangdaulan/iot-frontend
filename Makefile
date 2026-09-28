.ONESHELL:
.SHELLFLAGS = -ec

include .env/make.env

.PHONY: build rebuild gen-api gen-api-prod deploy-web deploy-web-prod deploy-ios deploy-android deploy-mobile deploy-prod
# ==============================================================================
# 1. DEVELOPMENT TARGETS
# ==============================================================================

build:
	dart run build_runner build

rebuild:
	dart run build_runner clean
	dart run build_runner build

gen-api:
	rm -rf lib/generated
	dart run swagger_parser --schema_url "$(SWAGGER_URL)"
	$(MAKE) rebuild

gen-api-prod:
	$(MAKE) gen-api SWAGGER_URL="$(SWAGGER_URL_PROD)"

# ==============================================================================
# 2. DEPLOYMENT TARGETS
# ==============================================================================

deploy-web:
	flutter build web --release --dart-define-from-file=.env/$(or $(ENV),dev).json
	rsync -avz --delete build/web/ $(WEB_DEST)

deploy-web-prod:
	$(MAKE) deploy-web ENV=prod WEB_DEST="$(WEB_DEST_PROD)"

deploy-ios:
	cd ios && fastlane release

deploy-android:
	cd android && fastlane release

deploy-mobile:
	$(MAKE) --jobs=2 deploy-ios deploy-android

deploy-prod:
	$(MAKE) gen-api-prod
	$(MAKE) --jobs=3 deploy-web-prod deploy-ios deploy-android
