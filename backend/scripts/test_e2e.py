import requests
import json
import random
import string
import time

BASE_URL = "http://localhost:5000"

def get_random_string(length=8):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

def run_tests():
    print("--- ESAEMLAK E2E API TEST ---")
    
    # 1. Register
    email = f"testuser_{get_random_string()}@example.com"
    password = "Password123*"
    print(f"\n[1] Registering new user: {email}")
    reg_response = requests.post(f"{BASE_URL}/api/auth/register", json={
        "ad": "Test",
        "soyad": "User",
        "email": email,
        "telefon": f"555{random.randint(1000000, 9999999)}",
        "sifre": password,
        "rol": "kullanici"
    })
    
    if reg_response.status_code not in (200, 201):
        print(f"FAILED to register: {reg_response.text}")
    else:
        print("SUCCESS: Registered")

    # 2. Login
    print(f"\n[2] Logging in with {email}")
    login_response = requests.post(f"{BASE_URL}/api/auth/login", json={
        "email": email,
        "sifre": password
    })
    
    token = None
    if login_response.status_code == 200:
        data = login_response.json()
        token = data.get('token') or data.get('accessToken')
        if token:
            print("SUCCESS: Logged in, Got Token")
        else:
            print("FAILED: No token in response", data)
    else:
        print(f"FAILED to login: {login_response.text}")

    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    # 3. Create Listing (if token exists)
    listing_id = None
    if token:
        print("\n[3] Creating a new listing")
        listing_payload = {
            "baslik": "Sahibinden Acil Satılık 3+1 Daire",
            "kategori": 1, # Konut
            "altKategori": 1, # Daire
            "islemTipi": 1, # Satilik
            "fiyat": 3500000,
            "brutMetrekare": 135,
            "netMetrekare": 120,
            "odaSayisi": "3+1",
            "binaYasi": "5-10",
            "bulunduguKat": 3,
            "katSayisi": 5,
            "isitmaTipi": "Kombi",
            "banyoSayisi": 2,
            "il": "İstanbul",
            "ilce": "Kadıköy",
            "mahalle": "Caddebostan",
            "aciklama": "Deniz manzaralı temiz daire, acil satılıktır.",
            "konum": {
                "type": "Point",
                "coordinates": [29.0645, 40.9658]
            }
        }
        
        create_res = requests.post(f"{BASE_URL}/api/listings", json=listing_payload, headers=headers)
        if create_res.status_code in (200, 201):
            data = create_res.json()
            listing_id = data.get('id')
            print(f"SUCCESS: Created listing {listing_id}")
        else:
            print(f"FAILED to create listing: Status={create_res.status_code}, Body={create_res.text}")

    # 4. Fetch the listing
    if listing_id:
        print(f"\n[4] Fetching listing {listing_id}")
        get_res = requests.get(f"{BASE_URL}/api/listings/{listing_id}")
        if get_res.status_code == 200:
            print("SUCCESS: Fetched listing successfully")
        else:
            print(f"FAILED to fetch listing: {get_res.text}")

    # 5. Search
    print("\n[5] Searching listings")
    # Add a small delay for elasticsearch to index
    time.sleep(2)
    search_payload = {
        "searchTerm": "Acil",
        "minFiyat": 1000000,
        "maxFiyat": 5000000
    }
    search_res = requests.post(f"{BASE_URL}/api/search", json=search_payload, headers=headers)
    if search_res.status_code == 200:
        data = search_res.json()
        print(f"SUCCESS: Search returned {len(data.get('items', [])) if isinstance(data, dict) else len(data)} results")
    else:
        print(f"FAILED to search: {search_res.status_code} {search_res.text}")

    # 6. Check Redis Price Drops
    print("\n[6] Fetching price drops from Redis")
    drops_res = requests.get(f"{BASE_URL}/api/listings/price-drops")
    if drops_res.status_code == 200:
        print("SUCCESS: Fetched price drops")
    else:
        print(f"WARNING: Failed to fetch price drops (Status: {drops_res.status_code}). Maybe endpoint is not fully ready or elasticsearch is warming up.")

    print("\n--- TEST COMPLETE ---")

if __name__ == "__main__":
    run_tests()
