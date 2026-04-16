import bcrypt
from pymongo import MongoClient
import datetime
from bson import ObjectId

client = MongoClient('mongodb+srv://chatgbtseverim_db_user:1SUIfjvJSFX8m6w8@cluster0.quyqyud.mongodb.net/?appName=Cluster0')
db = client['EsaEmlakDb']
collection = db['emlakcis']

email = "admin@emlaktan.com"

# Remove any old misformatted admins
collection.delete_many({"Email": email})
collection.delete_many({"email": email})

password = b"Admin123!"
hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')

admin_user = {
    "_id": ObjectId(),
    "ad": "Admin",
    "soyad": "User",
    "email": email,
    "telefon": "905555559999",
    "sifre": hashed,
    "rol": "admin",
    "onayli": True,
    "banli": False,
    "emailOnayli": True,
    "telefonOnayli": True,
    "twoFactorEnabled": False,
    "createdAt": datetime.datetime.utcnow(),
    "updatedAt": datetime.datetime.utcnow()
}

collection.insert_one(admin_user)
print("Admin inserted successfully with correct field names.")

# Verify
users = list(collection.find({"email": email}))
print(users)
