import requests
import json

url = "http://localhost:5000/api/auth/login"
payload = {
    "email": "admin@emlaktan.com",
    "password": "Admin123!"
}
headers = {
    "Content-Type": "application/json"
}

try:
    response = requests.post(url, json=payload, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
