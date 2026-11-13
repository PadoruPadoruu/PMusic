import re
from pathlib import Path
from opencc import OpenCC

cc = OpenCC('s2twp')  # Simplified Chinese to Traditional Chinese (with standard UI phrases)
path = Path('lib/features/music/presentation/providers/app_strings_translation_catalog.dart')

def split_top_level_elements(body: str):
    """Splits a Dart <String>[...] body by top-level commas, preserving multiline concatenated strings."""
    elements = []
    current = []
    in_str = False
    quote_char = ''
    escape = False
    for ch in body:
        if in_str:
            current.append(ch)
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == quote_char:
                in_str = False
        else:
            if ch in ("'", '"'):
                in_str = True
                quote_char = ch
                current.append(ch)
            elif ch == ',':
                elem = ''.join(current).strip()
                if elem:
                    elements.append(elem)
                current = []
            else:
                current.append(ch)
    tail = ''.join(current).strip()
    if tail:
        elements.append(tail)
    return elements


def main():
    if not path.exists():
        print(f"[ERROR] {path} not found.")
        return

    content = path.read_text(encoding='utf-8')

    # 1. Register zh_TW / zh_HK / zh-Hant at index 5 in _appStringLanguageIndex (if not already present)
    if "'zh_TW': 5" not in content:
        content = re.sub(
            r"('ja'\s*:\s*4\s*,?)",
            r"\1\n  'zh_TW': 5,\n  'zh_HK': 5,\n  'zh-Hant': 5,",
            content,
            count=1,
        )
        print("[OK] Added 'zh_TW', 'zh_HK', and 'zh-Hant' to _appStringLanguageIndex.")

    # 2. Append 6th element (Traditional Chinese) to any 5-element <String>[...] list
    list_pattern = re.compile(r"(<String>\[)(.*?)(\])", re.DOTALL)
    patched_count = 0

    def patch_list(match):
        nonlocal patched_count
        prefix, body, suffix = match.groups()
        elems = split_top_level_elements(body)
        # Only patch lists that currently have exactly 5 elements [pt, fr, ko, zh, ja]
        if len(elems) == 5:
            zh_trad_elem = cc.convert(elems[3])
            elems.append(zh_trad_elem)
            patched_count += 1
            if '\n' in body:
                inner = ',\n    '.join(elems)
                return f"{prefix}\n    {inner},\n  {suffix}"
            else:
                inner = ', '.join(elems)
                return f"{prefix}{inner}{suffix}"
        return match.group(0)

    content = list_pattern.sub(patch_list, content)

    # 3. Add safe bounds fallback in translateAppString to prevent RangeError (0..4: 5)
    content = content.replace(
        "if (exact != null) return exact[index];",
        "if (exact != null) return exact[index < exact.length ? index : 3];",
    ).replace(
        "return template.translations[index].replaceAllMapped(",
        "return template.translations[index < template.translations.length ? index : 3].replaceAllMapped(",
    )

    path.write_text(content, encoding='utf-8')
    print(f"[OK] Patched {patched_count} translation lists with 6th zh_TW element.")


if __name__ == '__main__':
    main()