# Update app name in l10n file
with open('frontend/lib/core/l10n/app_localizations.dart', 'r', encoding='utf-8') as f:
    c = f.read()

# Update ID version
c = c.replace("get appName => 'ServisGadget'", "get appName => 'Service Me'")
# Update EN version - it's already 'ServisGadget' for both
c = c.replace("ServisGadget v2.0", "Service Me v1.0")

with open('frontend/lib/core/l10n/app_localizations.dart', 'w', encoding='utf-8') as f:
    f.write(c)

# Update main.dart title
with open('frontend/lib/main.dart', 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace("title: 'ServisGadget'", "title: 'Service Me'")
with open('frontend/lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(c)

print('App name updated to Service Me')
