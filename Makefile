API_DIR  := ../hisab-sathi-api
EMULATOR := emulator-5554
# Mac-এর LAN IP (আসল ফোন একই Wi-Fi তে থাকতে হবে)
LAN_IP   := $(shell ipconfig getifaddr en0)
API_PORT := 8080
PROD_API := https://hisabsathibd.vercel.app

.PHONY: help run run-e-l run-e-p run-r-l run-r-p devices

help:
	@echo "make run         - Go সার্ভার চালু (go run .)"
	@echo "make run-e-l     - এমুলেটরে অ্যাপ চালু, লোকাল সার্ভার দিয়ে (http://10.0.2.2:$(API_PORT))"
	@echo "make run-e-p     - এমুলেটরে অ্যাপ চালু, লাইভ API ($(PROD_API)) দিয়ে"
	@echo "make run-r-l     - আসল ফোনে অ্যাপ চালু, লোকাল সার্ভার দিয়ে, Mac-এর LAN IP (ঐচ্ছিক: DEVICE=<id>)"
	@echo "make run-r-p     - আসল ফোনে অ্যাপ চালু, লাইভ API ($(PROD_API)) দিয়ে (ঐচ্ছিক: DEVICE=<id>)"
	@echo "make devices     - ডিভাইসের তালিকা"

run:
	$(MAKE) -C $(API_DIR) run PORT=$(API_PORT)

run-e-l:
	flutter run -d $(EMULATOR) --dart-define=API_URL=http://10.0.2.2:$(API_PORT)

run-e-p:
	flutter run -d $(EMULATOR) --dart-define=API_URL=$(PROD_API)

# আসল ফোনে localhost কাজ করে না, তাই Mac-এর LAN IP দেওয়া হচ্ছে
run-r-l:
	flutter run $(if $(DEVICE),-d $(DEVICE),) --dart-define=API_URL=http://$(LAN_IP):$(API_PORT)

# লোকাল সার্ভার ছাড়াই, সরাসরি লাইভ (Vercel) API দিয়ে আসল ফোনে টেস্ট
run-r-p:
	flutter run $(if $(DEVICE),-d $(DEVICE),) --dart-define=API_URL=$(PROD_API)

devices:
	flutter devices
