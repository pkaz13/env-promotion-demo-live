"""Synthetic demo service. Stands in for any deployable (web API, Windows service, console app)."""
import json
import pathlib

here = pathlib.Path(__file__).parent
settings = json.loads((here / "appsettings.json").read_text())
version = (here / "VERSION").read_text().strip()

print(f"service version : {version}")
print(f"environment     : {settings['Environment']}")
print(f"database host   : {settings['Database']['Host']}")
print(f"key vault       : {settings['KeyVault']['Name']}")
print(f"tenant          : {settings['Azure']['TenantId']}")
print(f"db password set : {'yes' if settings['Database']['Password'] and not settings['Database']['Password'].startswith('#{') else 'NO'}")
