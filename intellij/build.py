"""Diff Dark para IntelliJ — gera um plugin de tema a partir do Islands Dark do
próprio IDE instalado.

Interface: o Islands Dark inteiro passa por uma transformação de cor (cinzas
neutros com fio de verde, azuis viram sálvia apagado, o resto perde saturação).
Editor: o esquema do Islands Dark recebe a mesma transformação e, por cima, a
sintaxe é definida à mão numa família só de tons (cinza-verde a sálvia-azulado),
com itálico só nas chamadas de método.

Uso: python3 build.py <diretório-do-IDE> <saída.jar>
"""
import colorsys
import json
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

IDE = Path(sys.argv[1])
OUT = Path(sys.argv[2])
VERSION = "1.0.0"

THEME_SRC = "themes/islands/ManyIslandsDark.theme.json"
SCHEME_SRC = "themes/islands/IslandSchemeDark.xml"

SAGE_HUE = 148 / 360
GREY_HUE = 150 / 360


# ── transformação de cor ──────────────────────────────────────────────────
def shift(rgb):
    r, g, b = (c / 255 for c in rgb)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    deg = h * 360
    if s < 0.16 or l < 0.04 or l > 0.97:
        # cinzas (os do Islands puxam pro azul): neutros com um fio de verde
        h, s = GREY_HUE, min(s, 0.03)
    elif 185 <= deg <= 265:
        # família azul = cor de destaque do Islands → sálvia apagado
        h, s = SAGE_HUE, s * 0.26
    else:
        s *= 0.7
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return tuple(round(c * 255) for c in (r, g, b))


def shift_hex(hexstr):
    """'RRGGBB' ou 'RRGGBBAA' (sem #) → mesmo formato transformado."""
    body, alpha = hexstr[:6], hexstr[6:]
    rgb = tuple(int(body[i:i + 2], 16) for i in (0, 2, 4))
    return "".join(f"{c:02X}" for c in shift(rgb)) + alpha


HASH_HEX = re.compile(r"#([0-9A-Fa-f]{8}|[0-9A-Fa-f]{6})\b")


def shift_json_text(text):
    return HASH_HEX.sub(lambda m: "#" + shift_hex(m.group(1)), text)


# ── tema da interface ─────────────────────────────────────────────────────
def build_theme(src_text):
    theme = json.loads(shift_json_text(src_text))
    theme["name"] = "Diff Dark"
    theme["author"] = "diff-dark"
    theme["editorScheme"] = "/themes/DiffDark.xml"
    c = theme["colors"]
    # destaque principal um tom mais fundo: texto branco por cima continua legível
    c["accent-brand-bg"] = "#4F7D63"
    c["accent-brand-border"] = "#4F7D63"
    c["text-link"] = "#8FC0B8"
    c["popup-completion-match-text"] = "#8FB39D"
    c["search-match-bg"] = "#A88F4F"
    c["editor-text"] = "#C9CDCB"
    # moldura (barra de cima, faixas laterais, barra de status) quase preta, abaixo das
    # ilhas; o Islands tem duas variantes de moldura e o IDE escolhe uma delas
    c["main-window-bg"] = c["main-window-bg-alt"] = "#101110"
    return theme


# ── esquema do editor ─────────────────────────────────────────────────────
# Sintaxe numa família só (cinza-verde → sálvia → sálvia-azulado). Cada papel
# muda luz, saturação e um pouco de matiz; itálico só em chamada de método.
# papel: (matiz°, luz, saturação)
ROLES = {
    "text":       (150, .68, .03),  # identificadores e variáveis locais
    "punct":      (150, .50, .04),
    "comment":    (150, .42, .05),
    "doc":        (150, .48, .07),
    "doc_tag":    (150, .56, .09),
    "keyword":    (148, .56, .20),
    "string":     (128, .66, .26),
    "number":     (175, .70, .20),
    "method":     (150, .82, .10),  # declaração
    "call":       (150, .74, .22),  # chamada de instância
    "static":     (182, .64, .30),  # chamada estática
    "param":      (122, .78, .14),
    "field":      (160, .62, .14),
    "constant":   (182, .60, .16),  # campos estáticos e constantes
    "class":      (150, .86, .03),
    "interface":  (168, .70, .26),
    "annotation": (118, .52, .16),
    "type_param": (175, .72, .12),
}


def tone(role):
    h, l, s = ROLES[role]
    r, g, b = colorsys.hls_to_rgb(h / 360, l, s)
    return "".join(f"{round(c * 255):02x}" for c in (r, g, b))


ITALIC = {"FONT_TYPE": "2"}
UNDERLINE = {"EFFECT_COLOR": "6b716e", "EFFECT_TYPE": "1"}


def fg(role, **extra):
    return {"FOREGROUND": tone(role), **extra}


# (atributo, {chave: valor}) — valores sem '#', como o formato .icls espera
SYNTAX = {
    "TEXT": {"FOREGROUND": tone("text"), "BACKGROUND": "1a1b1a"},
    "DEFAULT_IDENTIFIER": fg("text"),
    "DEFAULT_LOCAL_VARIABLE": fg("text"),
    "DEFAULT_REASSIGNED_LOCAL_VARIABLE": fg("text", **UNDERLINE),
    "DEFAULT_BRACES": fg("punct"),
    "DEFAULT_COMMA": fg("punct"),
    "DEFAULT_DOT": fg("punct"),
    "DEFAULT_SEMICOLON": fg("punct"),
    "DEFAULT_OPERATION_SIGN": fg("punct"),
    "DEFAULT_KEYWORD": fg("keyword"),
    "DEFAULT_VALID_STRING_ESCAPE": fg("keyword"),
    "DEFAULT_STRING": fg("string"),
    "DEFAULT_NUMBER": fg("number"),
    "DEFAULT_LINE_COMMENT": fg("comment"),
    "DEFAULT_BLOCK_COMMENT": fg("comment"),
    "DEFAULT_DOC_COMMENT": fg("doc"),
    "DEFAULT_DOC_COMMENT_TAG": fg("doc_tag", EFFECT_TYPE="1"),
    "DEFAULT_FUNCTION_DECLARATION": fg("method"),
    "DEFAULT_FUNCTION_CALL": fg("call", **ITALIC),
    "DEFAULT_INSTANCE_METHOD": fg("call", **ITALIC),
    "DEFAULT_STATIC_METHOD": fg("static", **ITALIC),
    "Static method access": fg("static", **ITALIC),
    # construtor herda de FUNCTION_CALL: em `new Foo()` o Foo é classe, não chamada
    "CONSTRUCTOR_CALL_ATTRIBUTES": fg("class"),
    "DEFAULT_PARAMETER": fg("param"),
    "DEFAULT_REASSIGNED_PARAMETER": fg("param", **UNDERLINE),
    "IMPLICIT_ANONYMOUS_CLASS_PARAMETER_ATTRIBUTES": fg("param", **UNDERLINE),
    "DEFAULT_INSTANCE_FIELD": fg("field"),
    "DEFAULT_STATIC_FIELD": fg("constant"),
    "DEFAULT_CONSTANT": fg("constant"),
    "DEFAULT_CLASS_NAME": fg("class"),
    "DEFAULT_INTERFACE_NAME": fg("interface"),
    "DEFAULT_METADATA": fg("annotation"),
    "TYPE_PARAMETER_NAME_ATTRIBUTES": fg("type_param"),
    "IDENTIFIER_UNDER_CARET_ATTRIBUTES": {"BACKGROUND": "2a302d", "ERROR_STRIPE_COLOR": "6b8a77", "EFFECT_TYPE": "1"},
    "SEARCH_RESULT_ATTRIBUTES": {"BACKGROUND": "34453b", "ERROR_STRIPE_COLOR": "8fb39d"},
    "INLAY_DEFAULT": {"FOREGROUND": "858b88", "BACKGROUND": "2a2d2c"},
}
COLORS = {
    "CARET_COLOR": "8fb39d",
    "CARET_ROW_COLOR": "1d201e",
    "LINE_NUMBERS_COLOR": "4e5351",
    "LINE_NUMBER_ON_CARET_ROW_COLOR": "a8adaa",
    "SELECTION_BACKGROUND": "2f3d35",
    "INDENT_GUIDE": "262928",
    "SELECTED_INDENT_GUIDE": "3a3e3c",
    "RIGHT_MARGIN_COLOR": "262928",
}

HEX_VALUE = re.compile(r"^([0-9A-Fa-f]{8}|[0-9A-Fa-f]{6})$")


def build_scheme(src_text):
    root = ET.fromstring(src_text)
    root.set("name", "Diff Dark")
    # tudo o que tem cor passa pela transformação (inclusive variantes daltônicas)
    for el in root.iter("option"):
        for key in ("value", "deuteranopia", "protanopia"):
            v = el.get(key)
            if v and HEX_VALUE.match(v):
                el.set(key, shift_hex(v))

    colors = root.find("colors")
    by_name = {o.get("name"): o for o in colors.findall("option")}
    for name, value in COLORS.items():
        opt = by_name.get(name)
        if opt is None:
            opt = ET.SubElement(colors, "option", name=name)
        opt.set("value", value)

    attributes = root.find("attributes")
    by_name = {o.get("name"): o for o in attributes.findall("option")}
    for name, values in SYNTAX.items():
        opt = by_name.get(name)
        if opt is None:
            opt = ET.SubElement(attributes, "option", name=name)
        opt.attrib.pop("baseAttributes", None)
        for child in list(opt):
            opt.remove(child)
        value = ET.SubElement(opt, "value")
        for k, v in values.items():
            ET.SubElement(value, "option", name=k, value=v)
    ET.indent(root, "  ")
    return ET.tostring(root, encoding="unicode")


PLUGIN_XML = f"""<idea-plugin>
  <id>diff-dark.theme</id>
  <name>Diff Dark</name>
  <version>{VERSION}</version>
  <vendor>diff-dark</vendor>
  <description>Cinzas neutros com um fio de verde e destaque em sálvia apagado. Derivado do Islands Dark.</description>
  <idea-version since-build="253"/>
  <depends>com.intellij.modules.platform</depends>
  <extensions defaultExtensionNs="com.intellij">
    <themeProvider id="diff-dark" path="/themes/DiffDark.theme.json"/>
  </extensions>
</idea-plugin>
"""


def read_from_ide(entry):
    """O jar que guarda o Islands muda entre versões (app.jar no 2025.3,
    intellij.platform.ide.impl.jar no 2026.x): procura em todos do lib/."""
    for path in sorted((IDE / "lib").glob("*.jar")):
        with zipfile.ZipFile(path) as jar:
            if entry in jar.namelist():
                return jar.read(entry).decode("utf-8")
    sys.exit(f"{entry} não encontrado em {IDE}/lib — o IDE precisa ser 2025.3 ou mais novo")


def main():
    theme_src = read_from_ide(THEME_SRC)
    scheme_src = read_from_ide(SCHEME_SRC)

    theme = build_theme(theme_src)
    scheme = build_scheme(scheme_src)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUT.with_suffix(".tmp")
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("META-INF/plugin.xml", PLUGIN_XML)
        z.writestr("themes/DiffDark.theme.json", json.dumps(theme, indent=2, ensure_ascii=False))
        z.writestr("themes/DiffDark.xml", scheme)
    # troca atômica: o IDE aberto pode estar com o jar antigo mapeado
    tmp.replace(OUT)
    print(f"{OUT}  ({len(theme['colors'])} cores de UI, {len(SYNTAX)} regras de sintaxe)")


if __name__ == "__main__":
    main()
