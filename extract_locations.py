import re
import json

# Read the SQL file
with open('il-ilce-semt-mahalle-veritabani-main/il-ilce-semt-mahalle-2021_01_29_10_57_42-dump.sql', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract iller data
iller_match = re.search(r"INSERT INTO `iller` VALUES (.+?);", content, re.DOTALL)
if iller_match:
    iller_data = iller_match.group(1)
    iller = {}
    for match in re.finditer(r"\((\d+),'([^']+)'\)", iller_data):
        iller[int(match.group(1))] = match.group(2)
    print(f"Found {len(iller)} iller")

# Extract ilceler data
ilceler_match = re.search(r"INSERT INTO `ilceler` VALUES (.+?);", content, re.DOTALL)
if ilceler_match:
    ilceler_data = ilceler_match.group(1)
    ilceler = {}
    for match in re.finditer(r"\((\d+),(\d+),'([^']+)'\)", ilceler_data):
        ilce_id = int(match.group(1))
        il_id = int(match.group(2))
        ilce_adi = match.group(3)
        if il_id not in ilceler:
            ilceler[il_id] = {}
        ilceler[il_id][ilce_id] = ilce_adi
    total_ilce = sum(len(v) for v in ilceler.values())
    print(f"Found {total_ilce} ilceler")

# Extract semtler data  
semtler_match = re.search(r"INSERT INTO `semtler` VALUES (.+?);", content, re.DOTALL)
if semtler_match:
    semtler_data = semtler_match.group(1)
    semtler = {}
    for match in re.finditer(r"\((\d+),(\d+),(\d+),'([^']+)'\)", semtler_data):
        semt_id = int(match.group(1))
        il_id = int(match.group(2))
        ilce_id = int(match.group(3))
        semt_adi = match.group(4)
        if ilce_id not in semtler:
            semtler[ilce_id] = {}
        semtler[ilce_id][semt_id] = semt_adi
    total_semt = sum(len(v) for v in semtler.values())
    print(f"Found {total_semt} semtler")

# Extract mahalleler data
mahalleler_match = re.search(r"INSERT INTO `mahalleler` VALUES (.+?);", content, re.DOTALL)
if mahalleler_match:
    mahalleler_data = mahalleler_match.group(1)
    mahalleler = {}
    for match in re.finditer(r"\((\d+),(\d+),(\d+),(\d+),'([^']+)','([^']+)'\)", mahalleler_data):
        mahalle_id = int(match.group(1))
        il_id = int(match.group(2))
        ilce_id = int(match.group(3))
        semt_id = int(match.group(4))
        mahalle_adi = match.group(5)
        posta_kodu = match.group(6)
        if semt_id not in mahalleler:
            mahalleler[semt_id] = []
        mahalleler[semt_id].append({
            'id': mahalle_id,
            'ad': mahalle_adi,
            'posta_kodu': posta_kodu
        })
    total_mahalle = sum(len(v) for v in mahalleler.values())
    print(f"Found {total_mahalle} mahalleler")

# Build structured data for Flutter
flutter_data = {
    'iller': [{'id': id, 'ad': ad} for id, ad in sorted(iller.items())],
    'ilceler': {},
    'semtler': {},
    'mahalleler': {}
}

# Group ilceler by il_id
for il_id, ilce_dict in ilceler.items():
    flutter_data['ilceler'][il_id] = [{'id': id, 'ad': ad} for id, ad in sorted(ilce_dict.items())]

# Group semtler by ilce_id
for ilce_id, semt_dict in semtler.items():
    flutter_data['semtler'][ilce_id] = [{'id': id, 'ad': ad} for id, ad in sorted(semt_dict.items())]

# Group mahalleler by semt_id
for semt_id, mahalle_list in mahalleler.items():
    flutter_data['mahalleler'][semt_id] = sorted(mahalle_list, key=lambda x: x['id'])

# Save full data as JSON
with open('flutter_app/assets/turkiye_konumlari.json', 'w', encoding='utf-8') as f:
    json.dump(flutter_data, f, ensure_ascii=False, indent=2)
print("Saved turkiye_konumlari.json")

# Create a simpler Dart file with just il-ilce mapping
dart_content = '''// Auto-generated from SQL database
// il-ilce-semt-mahalle-veritabani-main

class TurkiyeKonumlari {
  static const List<String> iller = [
'''

# Add iller sorted by name
sorted_iller = sorted(iller.items(), key=lambda x: x[1])
for il_id, il_ad in sorted_iller:
    dart_content += f"    '{il_ad}',\n"
dart_content += "  ];\n\n"

# Add ilceler map
dart_content += "  static const Map<String, List<String>> ilceler = {\n"
for il_id, il_ad in sorted_iller:
    if il_id in ilceler:
        ilce_list = sorted(ilceler[il_id].values())
        dart_content += f"    '{il_ad}': {ilce_list},\n"
dart_content += "  };\n\n"

# Helper method
dart_content += '''  static List<String> getIlceler(String il) {
    return ilceler[il] ?? [];
  }
}
'''

with open('flutter_app/lib/data/turkiye_konumlari.dart', 'w', encoding='utf-8') as f:
    f.write(dart_content)
print("Saved turkiye_konumlari.dart")
