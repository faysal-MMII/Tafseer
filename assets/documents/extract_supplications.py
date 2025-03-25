import json

islamic_qa_path = '/home/faisal/Documents/islam101/assets/data/islamic_qa.json'
fortress_of_muslim_path = '/home/faisal/Documents/islam101/assets/documents/fortress_of_muslim.json'
output_path = '/home/faisal/Documents/islam101/assets/data/islamic_qa_merged.json'

with open(islamic_qa_path, 'r', encoding='utf-8') as f:
    islamic_qa_data = json.load(f)

with open(fortress_of_muslim_path, 'r', encoding='utf-8') as f:
    fortress_of_muslim_data = json.load(f)

# Ensure both variables are lists before merging
if isinstance(islamic_qa_data, dict):
    islamic_qa_data = [islamic_qa_data]  # Convert dict to list

merged_data = islamic_qa_data + fortress_of_muslim_data

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(merged_data, f, ensure_ascii=False, indent=2)

print(f"Merged {len(islamic_qa_data)} + {len(fortress_of_muslim_data)} = {len(merged_data)} entries")