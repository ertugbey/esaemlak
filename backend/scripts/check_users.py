import pymongo

client = pymongo.MongoClient('mongodb://localhost:27017/')
db = client['esaemlak_v2']
collection = db['emlakcis']

users = list(collection.find())
print(f"Total users: {len(users)}")
for u in users:
    print(u)
