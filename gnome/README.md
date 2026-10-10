# Diff Dark — GNOME

Testado no **Ubuntu 22.04, GNOME 42, X11**. Tudo é instalado no diretório do
usuário, sem sudo (exceto os pacotes de pré-requisito).

## Instalar

```bash
sudo apt install git curl unzip sassc x11-utils python3-gi python3-pil libfuse2 gnome-shell-extension-prefs
./install.sh
```

Depois, recarregue o Shell para as extensões novas carregarem: no X11, **Alt+F2 → `r` → Enter**
(as janelas continuam abertas); no Wayland, saia e entre na sessão.

| Script | Faz |
|---|---|
| `install.sh` | Confere dependências, salva o estado atual, compila o tema, baixa ícones, fontes, extensões e Conky, e chama o `apply.sh`. Pode rodar de novo, porque pula o que já existe. |
| `apply.sh` | Só aplica as configurações (dconf, CSS, terminal, widget, wallpaper). Rode depois de mudar qualquer coisa aqui. |
| `revert.sh` | Volta ao estado salvo antes da primeira instalação. Restaura só o que o projeto mexe; o resto do dconf fica intacto. |

Opções do `apply.sh`:

```bash
DIFF_WALLPAPER=~/Imagens/foto.jpg ./apply.sh           # gradua outra imagem (padrão: o wallpaper atual)
DIFF_WALLPAPER=default ./apply.sh                      # paisagem gerada (a do print), no tamanho do monitor
DIFF_BUTTONS=':minimize,maximize,close' ./apply.sh     # botões de janela à direita (padrão: esquerda)
```

## O que muda

- **GTK 3/4 e Shell:** tema `Diff-Green-Dark` (Colloid recolorido, sem borda de 1px). O libadwaita
  recebe o tema em `~/.config/gtk-4.0`.
- **Ícones e fontes:** Colloid Grey Dark; Inter na interface e JetBrains Mono no monoespaçado.
- **Dock:** Ubuntu Dock fixo à esquerda, ícones de 28px, fundo `#161817` a 60%, pontinho sálvia
  no app em foco.
- **Menu:** ArcMenu no layout "Eleven", no canto esquerdo da barra do topo.
- **Blur:** a barra do topo fica fosca, e o terminal ganha vidro (Blur my Shell).
- **Terminal:** perfil `Diff` no gnome-terminal (22% transparente, JetBrains Mono, margem
  interna, barra de título no lugar do menu). O perfil antigo continua lá.
- **Widget:** card com anéis de CPU, RAM e disco no canto superior direito do monitor principal.
- **Wallpaper:** o atual, quase sem cor, escurecido e com véu sálvia nas sombras. A original
  não é alterada; a versão graduada fica em `~/.local/share/diff-dark/wallpapers`. Se o wallpaper
  atual não for uma imagem, entra a paisagem gerada por `wallpaper/generate.py`: cumes em
  camadas de cinza e um disco sálvia, sem imagem de terceiros.

## Ajustar

- **Cores do tema:** edite `theme/palette.scss` e rode `./install.sh`, que recompila e reaplica.
- **Espaçamento do dock e outros detalhes do Shell:** `theme/shell-overrides.css`, injetado no
  CSS do Shell a cada `apply.sh`.
- **Widget:** desenhado em Lua/Cairo em `conky/diff.lua`. A posição padrão fica em `conky/place.py`
  (24px da borda e da barra do topo).

## Notas técnicas (o que não é óbvio)

- **O backup é feito antes do build.** O Colloid escreve em `~/.config/gtk-4.0`, então o
  `install.sh` salva o estado (`~/.local/share/diff-dark/backup`) antes de compilar. O backup
  nunca é sobrescrito; o `revert.sh` sempre volta ao estado de antes da primeira instalação.
- **O User Themes recarrega o CSS sem reiniciar o Shell.** Basta trocar o nome do tema para vazio
  e de volta, que é o que o `apply.sh` faz.
- **Conky via AppImage:** os bindings Lua do Cairo ficam em `$APPDIR/usr/lib/conky`, mas o
  `package.cpath` do AppImage aponta para o diretório de build. O `diff.lua` corrige isso
  na primeira linha.
- **Conky com `alignment` fixo puxa a janela de volta para o canto a cada segundo.** Por isso
  o card usa `alignment = 'none'` e quem posiciona e dimensiona a janela é o `conky/place.py`.
  Nesse modo o Conky também não dimensiona a janela, que nasceria com 5px.
- **A posição do card persiste** em `~/.local/share/diff-dark/stats-pos` quando a janela é
  movida. Se o ponto salvo cair fora de qualquer monitor, ele volta ao canto padrão.
- **Super+D esconde o card junto com as janelas**, e o Mutter não move uma janela fixada no fundo
  com Super+arrastar. Para mudar a posição padrão, edite o `place.py`.
- **Ubuntu Dock em vez de Dash to Panel:** o Ubuntu Dock é carregado pela sessão e liga na hora;
  extensões recém-baixadas só carregam depois de recarregar o Shell. Desligar o dock antes
  disso deixa a máquina sem barra.
- **`pkill -f` com padrão de caminho** mata o próprio shell se o padrão aparecer na linha de
  comando dele. Os scripts usam padrões que só casam com o processo do Conky.
