# Diff Dark — IntelliJ

Plugin de tema (interface e editor) para IDEs JetBrains **2025.3 ou mais novos** no Linux.
Independe da parte GNOME.

## Instalar

```bash
./install.sh                              # com o IDE aberto: detecta instalação e perfil
./install.sh /opt/idea-IU-253.29346.138   # ou aponte a instalação (pode estar fechado)
./install.sh --uninstall                  # remove
```

Depois, **reinicie o IDE** e escolha em **Settings › Appearance › Theme → Diff Dark**. O esquema
do editor vem junto.

Precisa só de `python3`.

## Como é gerado

O `build.py` lê o **Islands Dark** do próprio IDE (tema da interface e esquema do editor)
e gera um plugin `.jar` com:

- **Interface:** o Islands Dark inteiro passa por uma transformação de cor:
  - cinzas perdem o tom azulado e ganham matiz verde (saturação ≤ 3%);
  - azuis, que são a cor de destaque do Islands, viram sálvia com ~1/4 da saturação;
  - as demais cores (erro, aviso, sucesso...) perdem 30% de saturação.

  O layout de ilhas fica idêntico.
- **Editor:** o esquema do Islands Dark com a mesma transformação, e por cima a sintaxe definida
  à mão numa família só de tons (cinza-verde → sálvia → sálvia-azulado).

| Elemento | Tom | Itálico |
|---|---|---|
| Chamada de método | menta clara | sim |
| Chamada estática | sálvia-azulado intenso | sim |
| Declaração de método | quase branco esverdeado | — |
| Classe / Interface | quase branco neutro / sálvia-azulado | — |
| Parâmetro / variável local | verde bem claro / cinza | — |
| Campo / constante | cinza-sálvia / sálvia-azulado escuro | — |
| Keyword / string | sálvia médio / verde-folha | — |
| Anotação / comentário | verde escuro apagado / cinza escuro | — |

Para ajustar, edite a tabela `ROLES` no `build.py` (matiz, luz e saturação por papel) e rode
o `install.sh` de novo. Ele troca o `.jar` de forma atômica, então pode rodar com o IDE aberto.

## Notas técnicas

- **Nada da JetBrains é redistribuído.** O tema é derivado na máquina de quem instala, a partir
  do IDE dela.
- **O jar com o Islands muda entre versões:** `lib/app.jar` no 2025.3,
  `lib/intellij.platform.ide.impl.jar` no 2026.x. O `build.py` procura em todos os jars de `lib/`.
- **Perfil (pasta de plugins):** vem de `product-info.json` (`dataDirectoryName`). Se o arquivo
  não existir, vem de `build.txt` (`IU-253…` → `IntelliJIdea2025.3`). Um IDE aberto pode usar
  outro perfil via `-Didea.paths.selector`, e o instalador respeita isso.
- **Heranças de cor no Java** (conferidas no bytecode do IDE):
  - `METHOD_CALL`, `INHERITED_METHOD` e `ABSTRACT_METHOD` herdam de `FUNCTION_CALL`;
  - chamada estática usa `STATIC_METHOD`, mas a *declaração* de um método estático usa
    `METHOD_DECLARATION`, por isso o itálico fica só nas chamadas;
  - `CONSTRUCTOR_CALL` também herda de `FUNCTION_CALL`. Por isso ele é fixado com a cor de
    classe, senão o `Foo` de `new Foo()` ficaria itálico com cor de método;
  - interfaces têm chave própria (`INTERFACE_NAME`), separada de `CLASS_NAME`.
