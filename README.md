# Diff Dark

Tema escuro minimalista em tons de cinza neutro com um fio de verde. O sálvia
`#8fb39d` é o único destaque e aparece pouco: seleção, cursor, foco, chamadas de
método.

![Desktop com Diff Dark: terminal translúcido, Nautilus, dock à esquerda e card de sistema](docs/desktop.png)

![IntelliJ IDEA com Diff Dark](docs/intellij.png)

São duas partes **independentes**. Instale uma, a outra ou as duas:

| Parte | O que muda | Instalação |
|---|---|---|
| [`gnome/`](gnome/) | GTK 3/4, GNOME Shell, ícones, fontes, dock, menu, terminal, widget de sistema, wallpaper | `gnome/install.sh` |
| [`intellij/`](intellij/) | Interface e editor do IntelliJ IDEA (e outros IDEs JetBrains 2025.3+) | `intellij/install.sh` |

```bash
git clone <este repositório> ~/diff-dark
~/diff-dark/gnome/install.sh      # desktop
~/diff-dark/intellij/install.sh   # IDE (com o IntelliJ aberto, ou passe o caminho dele)
```

## Paleta

| Papel | Cor |
|---|---|
| Fundo (janelas / editor) | `#202322` / `#1a1b1a` |
| Superfícies | `#161817` · `#1b1d1c` · `#2a2d2c` |
| Bordas | `#3a3e3c` |
| Texto | `#eceeed` · secundário `#9aa09d` |
| Destaque | `#8fb39d` (sálvia) · escuro `#4f7d63` |
| Erro / aviso | `#d98880` / `#d6c08e` |

Os cinzas têm matiz ~150° e saturação abaixo de 5%: parecem neutros, mas
conversam com o verde.

## O que fica fora do repositório

Nada de terceiros é redistribuído. Tudo é baixado ou gerado na hora da instalação:

- **Tema GTK/Shell:** compilado a partir do [Colloid](https://github.com/vinceliuice/Colloid-gtk-theme),
  num commit fixo, com a paleta de `gnome/theme/palette.scss`.
- **Tema do IntelliJ:** gerado a partir do Islands Dark que já vem no IDE de quem instala.
- **Ícones, fontes, extensões e Conky:** baixados das fontes oficiais, em versões fixas.

## Licença

[GPL-3.0](LICENSE). `gnome/theme/palette.scss` é uma versão modificada de um arquivo do
Colloid, que também é GPL-3.0.
