# Diff Dark — GNOME

[English](README.md) · **Português**

Testado no **Ubuntu 22.04, GNOME 42, X11**. Tudo é instalado no diretório do usuário, sem sudo
(exceto os pacotes de pré-requisito).

## Instalar

```bash
sudo apt install git curl unzip sassc x11-utils python3-gi python3-pil libfuse2 gnome-shell-extension-prefs
./install.sh
```

Depois, recarregue o Shell para as extensões novas carregarem: no X11, **Alt+F2 → `r` → Enter**
(as janelas continuam abertas); no Wayland, saia e entre na sessão.

## Desinstalar

```bash
./uninstall.sh
```

Volta todas as configurações que o tema mexeu para como estavam antes da instalação e remove o
que o instalador baixou ou compilou (tema, ícones, fontes, extensões, Conky). O que já existia
na máquina fica.

## O que muda

- **GTK 3/4 e Shell:** tema `Diff-Green-Dark` (Colloid recolorido, sem borda de 1px). Os apps
  libadwaita recebem o tema em `~/.config/gtk-4.0`.
- **Ícones e fontes:** Colloid Grey Dark; Inter na interface e JetBrains Mono no monoespaçado.
- **Barra do topo flutuante:** sem a faixa de ponta a ponta; cada grupo (menu e app em foco,
  relógio, indicadores) vira uma pílula do tamanho do próprio conteúdo, flutuando sobre o wallpaper.
- **Dock:** Ubuntu Dock fixo à esquerda, ícones de 28px, sem fundo, pontinho sálvia no app em foco.
- **Menu:** ArcMenu no layout "Eleven", no canto esquerdo da barra do topo.
- **Terminal:** perfil `Diff` no gnome-terminal (22% transparente, JetBrains Mono, margem interna,
  barra de título no lugar do menu). O perfil antigo continua lá.
- **Widget:** card com anéis de CPU, RAM e disco no canto superior direito do monitor principal.
  Com o [`ai-usagebar`](https://crates.io/crates/ai-usagebar) instalado, aparece embaixo um segundo
  card com a cota de IA: barras de sessão (5h) e semana, um risco marcando quanto da janela de
  tempo já passou e quando cada uma zera.
- **Wallpaper:** o atual, quase sem cor, escurecido e com véu sálvia nas sombras. O arquivo
  original não é alterado. Se o wallpaper atual não for uma imagem, entra uma paisagem gerada
  (cumes em camadas de cinza e um disco sálvia, sem imagem de terceiros).

## Opções

```bash
DIFF_WALLPAPER=~/Imagens/foto.jpg ./apply.sh            # gradua outra imagem (padrão: o wallpaper atual)
DIFF_WALLPAPER=default ./apply.sh                       # a paisagem gerada, no tamanho do monitor
DIFF_BUTTONS=':minimize,maximize,close' ./apply.sh      # botões de janela à direita (padrão: esquerda)
```

O `apply.sh` só aplica configurações: é rápido e pode rodar quantas vezes quiser.

## Personalizar

| Para mudar | Edite | Depois rode |
|---|---|---|
| Cores do tema | `theme/palette.scss` | `./install.sh` |
| Barra do topo, espaçamento do dock e outros detalhes do Shell | `theme/shell-overrides.css` | `./apply.sh` |
| Desenho do widget | `conky/diff.lua` | `conky/start.sh` |
| Posição padrão do widget | `conky/place.py` | `conky/start.sh` |
