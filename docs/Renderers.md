# Pablitus Prompt Framework v1.0 — Renderers Reference
> **Pablitus Prompt Framework v1.0 Architecture Frozen**

Renderers format the context information into a printable string representation. 

PPF v1.0 comes with 8 built-in renderers:

---

## 1. Plain
- **Output**: Standard plain text.
- **Characteristics**: Contains no ANSI escape codes, colors, or formatting. Perfect for logging, legacy shells, or subshells.

---

## 2. Minimal
- **Output**: Shortened, minimal prompt.
- **Characteristics**: Displays only the essential directory name and ends with a prompt symbol (`>` or `#`). Designed for speed and minimal screen footprint.

---

## 3. JSON
- **Output**: Structured JSON.
- **Characteristics**: Encodes all active segments and collected prompt context variables into a clean JSON string. Ideal for CLI integration or piping to other tools.

---

## 4. ANSI
- **Output**: ANSI 16-color code text.
- **Characteristics**: Implements colors using basic ANSI escape sequences (e.g. `\e[34m`). Highly compatible across standard terminals.

---

## 5. PowerLine
- **Output**: Powerline-themed glyph prompt.
- **Characteristics**: Uses triangular branch delimiters (``, ``) and special nerd-font branch icons. Requires a Nerd Font installed in the host terminal.

---

## 6. Markdown
- **Output**: Markdown formatted text.
- **Characteristics**: Formats the prompt using markdown syntax (e.g. `**bold**`, `*italic*`, code blocks). Used for documentation generation, chatbot logging, or notebook integration.

---

## 7. HTML
- **Output**: Styled HTML code.
- **Characteristics**: Wraps segments in `<span>` tags with embedded CSS style attributes specifying foreground and background colors. Suitable for embedding prompt outputs in web pages.

---

## 8. Rich
- **Output**: Modern rich terminal layout.
- **Characteristics**: Uses complex unicode symbols (`➔`, square brackets, bold/dim styling) to create a beautiful, modern terminal user experience.
