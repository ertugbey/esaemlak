// MongoDB init script — runs once when the container is first created
// Creates the esaemlak_v2 database and seeds an admin user
// Field names MUST match C# User.cs BsonElement attributes

db = db.getSiblingDB('esaemlak_v2');

// Check if admin already exists
const existing = db.users.findOne({ email: 'admin@esaemlak.com' });
if (!existing) {
    db.users.insertOne({
        ad: 'Admin',
        soyad: 'Kullanıcı',
        email: 'admin@esaemlak.com',
        telefon: '05551234567',
        sifre: '$2b$10$QMzUgkdbdrrAkjAp8YQzBeBzzem.YYva35wSX11N5fMIlnraj7YCu',
        rol: 'admin',
        onayli: true,
        banli: false,
        emailOnayli: true,
        telefonOnayli: true,
        twoFactorEnabled: false,
        createdAt: new Date(),
        updatedAt: new Date()
    });
    print('✅ Admin user created: admin@esaemlak.com / Admin123!');
} else {
    print('ℹ️ Admin user already exists, skipping.');
}
