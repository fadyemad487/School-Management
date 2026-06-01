import os
import re
import sys

# Base path relative to this script
base_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'wesal_ui_pages')

if not os.path.exists(base_path):
    # Try absolute path if relative fails
    base_path = '/Users/fadimegali/Desktop/ابلكيشن WeCircle/Wesal_app/wesal_ui_pages'

if not os.path.exists(base_path):
    print(f"ERROR: Base path {base_path} not found.")
    sys.exit(1)

output_file = os.path.join(base_path, 'wesal_full_ui_design.html')
css_path = os.path.join(base_path, 'css', 'style.css')

# Load CSS
shared_css = ""
if os.path.exists(css_path):
    try:
        with open(css_path, 'r', encoding='utf-8') as f:
            shared_css = f.read()
    except Exception as e:
        print(f"Error reading CSS: {e}")

html_template = """<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wesal App - Full UI Design Board</title>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        {shared_css}
        
        /* Layout Fixes for Design Board */
        body {{
            background: #F3F4F6;
            display: block;
            margin: 0;
            padding: 80px;
            font-family: 'Cairo', sans-serif;
            direction: rtl;
            overflow: auto;
            min-width: 5000px;
        }}

        .board-header {{
            margin-bottom: 80px;
            text-align: right;
            border-right: 8px solid #3B82F6;
            padding-right: 30px;
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        }}

        .category-section {{
            margin-bottom: 150px;
        }}

        .category-title {{
            font-size: 42px;
            font-weight: 900;
            color: #111827;
            margin-bottom: 40px;
            background: #3B82F6;
            color: white;
            display: inline-block;
            padding: 15px 60px;
            border-radius: 50px;
            box-shadow: 0 10px 15px -3px rgba(59, 130, 246, 0.3);
        }}

        .screens-grid {{
            display: flex;
            flex-wrap: nowrap;
            gap: 100px;
            padding: 20px;
        }}

        .screen-container {{
            display: flex;
            flex-direction: column;
            gap: 25px;
            align-items: center;
        }}

        .screen-name {{
            font-size: 20px;
            font-weight: 800;
            color: #4B5563;
            background: #fff;
            padding: 10px 30px;
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
            border: 1px solid #E5E7EB;
        }}

        /* Override phone-frame to be static and consistent */
        .phone-frame {{
            margin: 0 !important;
            flex-shrink: 0;
            box-shadow: 0 50px 100px -20px rgba(0, 0, 0, 0.25);
            transform: scale(1);
            transition: none !important;
        }}
    </style>
</head>
<body>
    <div class="board-header">
        <h1 style="font-size: 64px; margin: 0; font-weight: 900; color: #1E3A8A;">لوحة تصميم تطبيق WeCircle</h1>
        <p style="font-size: 24px; color: #4B5563; margin-top: 10px;">التطبيق التعليمي المتكامل - جميع الواجهات في مكان واحد</p>
    </div>

    {content}

    <footer style="margin-top: 200px; text-align: center; color: #9CA3AF; padding: 100px;">
        <p>© 2026 مشروع WeCircle - تم توليد هذه اللوحة لتسهيل أعمال التصميم في Figma</p>
    </footer>
</body>
</html>
"""

def extract_body_content(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        match = re.search(r'<body[^>]*>(.*?)</body>', content, re.DOTALL | re.IGNORECASE)
        if match:
            return match.group(1).strip()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    return ""

def generate_section(title, files):
    section_html = f'<div class="category-section"><h2 class="category-title">{{title}}</h2><div class="screens-grid">'
    for f_name, f_path in files:
        body = extract_body_content(f_path)
        if body:
            section_html += f"""
            <div class="screen-container">
                <div class="screen-name">{{f_name}}</div>
                {{body}}
            </div>"""
    section_html += '</div></div>'
    return section_html

categories = {{
    "المصادقة والبدء (Authentication)": [],
    "تطبيق ولي الأمر (Parent App)": [],
    "تطبيق المعلم (Teacher App)": []
}}

for root, dirs, files in os.walk(base_path):
    category_key = ""
    try:
        rel_root = os.path.relpath(root, base_path).lower()
    except:
        rel_root = root.lower()
    
    if "auth" in rel_root: category_key = "المصادقة والبدء (Authentication)"
    elif "parent" in rel_root: category_key = "تطبيق ولي الأمر (Parent App)"
    elif "teacher" in rel_root: category_key = "تطبيق المعلم (Teacher App)"
    
    if category_key:
        for file in sorted(files):
            if file.endswith('.html') and file != 'wesal_full_ui_design.html':
                name = file.replace('.html', '').replace('_', ' ').title()
                categories[category_key].append((name, os.path.join(root, file)))

sections_html = []
order = ["المصادقة والبدء (Authentication)", "تطبيق ولي الأمر (Parent App)", "تطبيق المعلم (Teacher App)"]
for title in order:
    files = categories.get(title, [])
    if files:
        print(f"Adding section: {{title}} ({{len(files)}} screens)")
        sections_html.append(generate_section(title, files))

final_content = "\\n".join(sections_html)
full_html = html_template.format(shared_css=shared_css, content=final_content)

with open(output_file, 'w', encoding='utf-8') as f:
    f.write(full_html)

print(f"SUCCESS: Generated {{output_file}}")
