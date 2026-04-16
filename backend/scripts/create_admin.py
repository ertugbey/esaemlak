import bcrypt
from pymongo import MongoClient
import datetime
import uuid

client = MongoClient('mongodb://localhost:27017/')
db = client['esaemlak_v2']
collection = db['emlakcis']

email = "admin@emlaktan.com"
existing = collection.find_one({"Email": email})

if existing:
    print("Admin already exists. Updating role to admin.")
    collection.update_one({"_id": existing["_id"]}, {"$set": {"Rol": "admin"}})
else:
    password = b"Admin123!"
    hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')
    
    admin_user = {
        "_id": str(uuid.uuid4()),
        "Ad": "Admin",
        "Soyad": "User",
        "Email": email,
        "Telefon": "905555555555",
        "PasswordHash": hashed,
        "Rol": "admin",
        "Onayli": True,
        "Banli": False,
        "EmailOnayli": True,
        "TelefonOnayli": True,
        "TwoFactorEnabled": False,
        "CreatedAt": datetime.datetime.utcnow(),
        "UpdatedAt": datetime.datetime.utcnow()
    }
    collection.insert_one(admin_user)
    print("Admin inserted successfully. Email: admin@emlaktan.com, Password: Admin123!")
