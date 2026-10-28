# Estação Raiz

Atualização local de efeitos e animação: [polimento e checkpoint de 17/10/2026](POLIMENTO-20261017.md). As capturas e vídeos de evidência não fazem parte desta cópia pública.

Primeira amostra local, com nome provisório. Uma estação botânica abandonada ainda guarda um coração de seiva luminosa. Organismos-máquina desregulados seguem essa energia; você precisa defender duas vias e reativar irrigação, leitos e floração.

**Jogar:** instale o Godot 4.4 ou mais novo e abra `project.godot` no editor. (`Jogar.cmd` espera o Godot numa pasta `../tools/godot-4.7.2/`, que não faz parte deste repositório.)

## Como jogar

- **1 / 2**, botões A/B ou clique na via: mover o reforço de seiva. A troca leva 0,9s e reduz temporariamente o dano.
- **Espaço:** iniciar, pausar ou retomar. **Esc:** fechar ajuda, cancelar confirmação ou pausar.
- **Como jogar:** instruções. **Novo ciclo:** exige uma segunda confirmação para limpar o progresso.
- **Som** e controle de volume no cabeçalho: preferências persistentes, separadas da partida.

A **cápsula-semente** concentra energia em um pulso. A **flor-condensador** reparte a energia do ciclo em três pulsos, separados nominalmente por 90ms. As duas disparam automaticamente e mantêm dano básico; apenas uma recebe o reforço. Corredores são rápidos; carapaças são mais lentas e resistentes. Observe a previsão do próximo setor e antecipe a transferência.

Cada setor concluído rende três brotos. Entre setores, escolha uma linha exclusiva:

| Melhoria | Nível I | Nível II |
|---|---|---|
| Reserva de seiva | Troca em 0,45s; mantém dano básico durante a transferência | Troca em 0,18s; mantém a reserva |
| Rede de raízes | Reforço distribuído entre dois alvos, com menor energia individual | Reforço distribuído entre três alvos, com menor energia individual |

Cada nível custa três brotos. A Reserva aparece como reservatório nas bases; a Rede acrescenta brotos de conexão. A amostra termina após três setores e pode ser reiniciada para experimentar a outra linha.

## Progresso e save

Primeiro, os conduítes e vasos recebem irrigação; depois surgem brotos; por fim, os leitos florescem e a estação volta a respirar. O progresso visual deriva dos setores realmente concluídos e é restaurado junto do checkpoint.

A partida usa `local/save.json`, dentro deste candidato. O checkpoint é salvo entre setores e após preparação/compra. Sair no combate retorna ao início daquele setor; não retoma projéteis em voo. Preferências sonoras usam `local/audio-settings.json`. Os testes usam outros arquivos e não preenchem o save inicial do jogador.

## Ver e conferir

- [Validação, limites e orçamento](VALIDACAO.md).
- Os vídeos e capturas de evidência ficaram fora desta cópia pública.

Os vídeos são capturas automatizadas do viewport/mixer da Godot; as versões normal e lenta usam renderização offline. Não representam uma partida humana. A avaliação de diversão, conforto e acabamento ainda depende de playtest.

Arte original gerada nesta etapa, com cenário e 16 peças articuláveis; fontes, prompts e cortes ficam em `assets/PROVENIENCIA.json`, `assets/original/`, `assets/parts-manifest.json` e `assets/slice_parts.py`. Os sons são as sínteses próprias do protótipo anterior. Não há assets copiados de outros jogos.
