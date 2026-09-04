# Sistema de diálogo

O componente `dialogo_visual_novel.tscn` é independente e não está conectado a nenhuma cena do jogo.

## Uso

```gdscript
const CENA_DIALOGO := preload("res://dialogo/dialogo_visual_novel.tscn")

var dialogo := CENA_DIALOGO.instantiate()
add_child(dialogo)
dialogo.iniciar([
    {"ator": "personagem", "texto": "Minha primeira fala."},
    {"ator": "chefe", "texto": "A resposta do chefe."},
])
```

Os atores disponíveis são `personagem` e `chefe`. Para montar uma conversa nova, altere somente `ator` e `texto` em cada item. Clique, pressione Enter ou Espaço para completar/avançar. Esc também avança.

O sinal `dialogo_finalizado` é emitido ao final. Por padrão, o jogo fica pausado enquanto o diálogo está aberto e o componente se remove ao terminar; essas opções podem ser alteradas pelas propriedades `pausar_jogo` e `fechar_ao_terminar`.

`teste_dialogo.tscn` serve apenas para validação manual e pode ser executada diretamente no editor com **F6**.

O teste automatizado pode ser repetido por linha de comando com:

```text
godot --headless --path . --script res://dialogo/teste_dialogo_automatico.gd
```
