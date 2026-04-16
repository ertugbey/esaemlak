import requests

base = "http://localhost:5000"
r = requests.get(f"{base}/api/locations/provinces")
print(f"Status: {r.status_code}")
print(f"Headers: {dict(r.headers)}")
print(f"Body: '{r.text[:500]}'")
