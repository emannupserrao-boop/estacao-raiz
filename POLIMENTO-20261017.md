# Polimento de efeitos e animação — checkpoint para reinício

Rodada local iniciada em 17/10/2026 às 09:35:54 UTC, com teto separado de 45 minutos efetivos. O trabalho chegou a um ponto seguro após a solicitação de preparar o Windows Sandbox. Nenhum reinício foi executado por esta tarefa.

## Resultado

- Cápsula: recuo mais firme, retorno com pequena acomodação e pulso fino com ponta legível.
- Flor: recuo mais curto, pétalas articuladas em cada pulso e traço breve de pólen. Continuam três pulsos por ciclo.
- Corredor: passada mais rápida, elevação dos pés e balanço leve do corpo. Carapaça: passada mais lenta, curta e pesada.
- Dano: tom quente discreto e marcas pequenas com contorno. Mortes recolhem as pernas e liberam quatro fragmentos botânicos curtos.
- Trajetórias visuais guardam origem e destino da emissão, sem acompanhar a próxima mira. O cache visual não é gravado nas regras nem no save.

Foram alterados somente quatro arquivos de runtime, todos em `visual/`: `tower.gd`, `actor.gd`, `impact_layer.gd` e `world.gd`. Regras, economia, controlador, HUD, áudio, arte e escopo das três ondas foram preservados por hash. Não houve geração de novos assets, gastos, instalações, uploads ou publicação.

## Evidências locais

- Comparação com detalhes nativos (fora da cópia pública).
- Vídeo comparativo de movimento, 4s, sem áudio (fora da cópia pública).
- Fases da articulação (fora da cópia pública).
- Captura nativa em 960×608 (fora da cópia pública).
- Checkpoint verificável (fora da cópia pública).

O vídeo combina recortes de 416×384 das duas capturas reais da Godot, lado a lado, com rótulos; saída 832×416, 96 quadros a 24 FPS. Não há interpolação, câmera nova ou efeitos adicionados em pós-produção. As entradas e os passos da simulação foram iguais. Os estados finais de gameplay antes/depois são idênticos. Tweens nativos de morte acompanham o tempo de renderização; não se exige identidade de cada pixel entre execuções. A captura de pausa foi idêntica entre dois quadros completos.

## Verificações desta rodada

Em cópia isolada, passaram 45 verificações básicas, 60 integradas, 83 estendidas e reabertura em processo separado. Ambas as linhas de melhoria concluíram as três ondas; derrota, reset com confirmação, pausa e save foram exercitados. A captura anterior passou 107 verificações; a final passou 109, acrescentando pureza do modelo e estabilidade das trajetórias. A comparação preservou exatamente o estado final do gameplay.

A bateria estendida capturou 1200×760 e 960×608. Amostra curta: 60 FPS, mediana de processamento de 5,016ms e p95 de 5,556ms. Não é benchmark geral nem demonstra diversão ou acabamento aprovado. Não houve playtest humano nem nova escuta perceptiva; o áudio não foi alterado.

A importação inicial acusou tipo inferido de `stride`; foi corrigido antes das execuções aprovadas. Uma cadeia posterior de captura ficou sem resultado e sem processo Godot visível; somente após conferir timestamps e processos a sessão própria foi encerrada. A captura individual seguinte terminou com sucesso. As etapas de vídeo lento e movimento 960 dessa cadeia não chegaram a executar; não são apresentadas como concluídas. O aviso não fatal de cache/profiler em `user://` permanece, sem mudança de permissões.

## Preservação e retomada

Backup reversível completo de fontes, assets e pasta local, sem cache/evidências: `C:\Users\user\Documents\Codex\2026-10-16\task\estacao-raiz-backup-polimento-20261017-0935`. Foram conferidos 124 arquivos no backup, incluindo dez arquivos locais. Os dez continuam intactos no candidato. O save de jogador `local/save.json` não existia no início e não foi criado pelos testes. Os novos arquivos de captura possuem nomes próprios.

O projeto anterior `defesa-potencia` teve novamente seus 816 arquivos conferidos, sem alterações. Regressões desta rodada ficaram em `estacao-raiz-qa-polimento-20261017-0935`, evitando sobrescrever capturas e saves das etapas anteriores.

Para retomar, abrir o `Jogar.cmd` do candidato atual. Não há migração de save, build comercial ou dependência nova. A versão ZIP da primeira amostra permanece histórica; usar o pacote de polimento para a fonte atual. O registro `checkpoint.json` separa esta rodada dos orçamentos anteriores. Seu intervalo observado inclui esperas; esforço efetivo exato não foi medido continuamente. Não há autorização presumida para renovar os outros limites.

Não há teste longo pendente. Capturas opcionais novas em câmera lenta e de movimento 960 foram deixadas para uma eventual retomada autorizada. O aceite artístico e a avaliação de diversão seguem humanos. A configuração do Windows Sandbox e o reinício pertencem à frente que os está coordenando.
