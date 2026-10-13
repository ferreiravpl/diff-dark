# Diff Dark — IntelliJ

[English](README.md) · **Português**

Plugin de tema (interface e editor) para IDEs JetBrains **2025.3 ou mais novos** no Linux.
Independe da parte GNOME. Precisa só de `python3`.

## Instalar

```bash
./install.sh                              # com o IDE aberto: detecta instalação e perfil
./install.sh /opt/idea-IU-253.29346.138   # ou aponte a instalação (o IDE pode estar fechado)
```

Reinicie o IDE e escolha **Settings › Appearance › Theme → Diff Dark**. O esquema de cores do
editor vem junto.

## Desinstalar

```bash
./uninstall.sh                            # mesmos argumentos do install.sh
```

Reinicie o IDE e ele volta ao tema padrão.

## Como é gerado

O `build.py` lê o **Islands Dark** do próprio IDE (tema e esquema de cores) e gera um plugin `.jar`:

- **Interface:** o Islands Dark com as cores deslocadas: os cinzas perdem o tom azulado e ganham
  um leve matiz verde, o destaque azul vira sálvia com ~1/4 da saturação, e as demais cores perdem
  30% de saturação. O layout de ilhas fica igual.
- **Editor:** a mesma transformação, e por cima a sintaxe escolhida à mão numa família só de tons
  (cinza-verde → sálvia → sálvia-azulado).

| Elemento | Tom | Itálico |
|---|---|---|
| Chamada de método | menta clara | sim |
| Chamada estática | sálvia-azulado intenso | sim |
| Declaração de método | quase branco esverdeado | — |
| Classe / interface | quase branco neutro / sálvia-azulado | — |
| Parâmetro / variável local | verde bem claro / cinza | — |
| Campo / constante | cinza-sálvia / sálvia-azulado escuro | — |
| Keyword / string | sálvia médio / verde-folha | — |
| Anotação / comentário | verde escuro apagado / cinza escuro | — |

Para ajustar uma cor, edite a tabela `ROLES` no `build.py` (matiz, luz e saturação por papel) e
rode o `install.sh` de novo. Pode rodar com o IDE aberto.
