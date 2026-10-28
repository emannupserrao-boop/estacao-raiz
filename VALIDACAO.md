# Primeira amostra — Estação Raiz

## Resultado

Candidato separado e reversível em `C:\Users\user\Documents\Codex\2026-10-16\task\estacao-raiz`. Uma arena, duas torres, dois arquétipos de inimigo, três ondas com restauração visual e duas linhas exclusivas de melhoria. Sem chefe, campanha, construção livre ou metaprogressão nova.

O gesto central foi preservado: antecipar ameaças e decidir qual via recebe o reforço de uma fonte compartilhada. A identidade mudou de cenário aberto com insetos para estufa cerâmica/cobre, coração de seiva e organismos-máquina próprios. O progresso agora reativa hardware de irrigação, faz os leitos brotarem e os leva à floração. O fundo continua danificado; a amostra demonstra a reativação dos sistemas e leitos, não uma simulação de reforma integral da estufa.

A cápsula dá um pulso por ciclo; a flor dá três, repartindo a energia potencial do ciclo. O ciclo nominal continua em 0,55s. Reserva reduz o intervalo de transferência e preserva dano básico; Rede amplia o número de alvos, reduzindo energia individual. Essas consequências foram verificadas, não apenas renomeadas na interface. A cápsula e a flor possuem bases/cabeças separadas, marcador de cano e recuo com AnimationPlayer. Os inimigos usam corpo e seis patas separadas, com fase guiada pelo deslocamento. Tween controla a morte, sem disputar propriedades com o movimento vivo.

## Verificações executadas

| Conjunto | Resultado final |
|---|---|
| Regressão básica de regras/UI/save/reset | 45 assertivas, zero falhas |
| Regressão estendida, dois ramos e cadências de decisão de 2s/4s | 83 assertivas, zero falhas |
| Verificações específicas da amostra | 60 assertivas, zero falhas |
| Controles de áudio | 38 assertivas, zero falhas |
| Movimento normal, lento e janela menor | 17 assertivas por sequência, zero falhas |
| Reabertura do checkpoint de vitória em outro processo | Aprovada |
| Reabertura de volume/mute em outro processo | Aprovada |
| Mix capturado, silêncio, dimensões e preservação | Oito condições objetivas aprovadas |

As 60 verificações específicas incluem energia por ciclo A/B, três emissões da flor, espaçamento da rajada, Reserva durante transferência, alvos adicionais da Rede, exclusividade, descarte de transientes na restauração de save, eixo do disparo alinhado ao cano, seis patas, pausa entre pulsos, morte congelada, restauração conquistada no fluxo da cena, pagamento das duas melhorias, vitória salva e reset confirmado. São assertivas de escopos variados, não participantes ou cenários independentes de avaliação humana.

Na execução integrada, Reserva concluiu com coração 9/10 e Rede com 10/10; ambas terminaram com três brotos e nível II. As simulações estendidas também venceram com decisões a cada 2s e 4s, variando entre 8 e 10 de integridade. Políticas fixas perderam. Isso demonstra possibilidades funcionais, sem provar equilíbrio amplo ou diversão.

O save de vitória foi reaberto com setor 3, Rede II, três brotos, fila de rajadas vazia e representação de floração. O reset retornou ao estado adormecido, com economia e melhorias limpas. Não havia `local/save.json` do jogador no candidato na verificação final; QA e captura usam caminhos próprios.

Recibos principais: `evidence/qa-report.json`, `evidence/polish/qa-report.json`, `evidence/raiz-qa-report.json`, `evidence/raiz-reopen-report.json`, `evidence/audio/qa-report.json`, `evidence/audio/reopen-report.json`, `evidence/motion/*-report.json` e `evidence/delivery-verification.json`.

## Capturas e áudio

Os PNGs vêm do framebuffer da Godot, não de mockups. A progressão usa estados realmente conquistados por uma mesma execução com Reserva; o mosaico é somente composição desses pixels. A montagem antes/depois compara a identidade de duas etapas diferentes e não afirma equivalência de estado ou de regras.

Normal/lento usam a mesma fixture inicial de estresse, com 12 inimigos e até sete feixes simultâneos. O vídeo normal cobre seis segundos; o lento, oito segundos com escala de tempo 0,25. Entradas ocorrem nos mesmos quadros de vídeo, portanto o lento cobre menos tempo lógico; não é teste de resultado idêntico entre velocidades. O pitch dos sons foi preservado. Há pausa entre os quadros 48–72; o normal também silencia a partir do quadro 120. Fonte: viewport e mixer da engine, via Movie Maker offline a 24 FPS. Não são gravações humanas em tempo real.

A sequência menor possui 144 imagens nativas de 960×608 capturadas em janela normal e codificadas a 24 FPS. Não é redução do vídeo padrão. Ela não contém áudio; o som é demonstrado nos dois vídeos padrão. O tempo de captura inclui readback e escrita de imagens e não serve como benchmark de fluidez. Foram inspecionados quadros normais, lentos, menores, progressão e contato de fases de movimento.

Mix normal: pico PCM16 10953/32767, sem amostras saturadas. Estresse com seis vozes e impactos a volume de 100%: pico 31656, sem amostras saturadas. As janelas medidas de pausa e mute possuem pico/RMS zero. A região do mundo em duas imagens menores durante a pausa é idêntica. Isso não substitui escuta perceptiva: não houve avaliação auditiva nesta execução e não se presume aceite dos blasters ou conforto em rajadas.

O último monitor de execução normal da bateria estendida registrou 60 FPS, mediana de processamento 3,543ms e p95 3,795ms, em 180 quadros após 120 de aquecimento, Compatibility/OpenGL 3.3 na RTX 5080 Laptop. É uma amostra curta do ambiente atual, não benchmark geral ou garantia em máquinas diferentes.

## Preservação e proveniência

Backup atualizado do protótipo anterior: `C:\Users\user\Documents\Codex\2026-10-16\task\defesa-potencia-backup-20261017-raiz-start`. Os oito arquivos existentes em sua pasta local foram copiados e tiveram hashes correspondentes. Também existe `estacao-raiz-backup-art-20261017-0536`, uma cópia de recuperação dos assets/fontes parciais na retomada, não uma versão jogável aprovada. A conferência final dos 816 arquivos do protótipo anterior encontrou zero modificações. Para voltar a ele, basta abrir seu próprio `Jogar.cmd`.

As duas imagens-fonte foram geradas com a ferramenta integrada de imagegen, a partir do briefing textual, sem fornecer imagens comerciais ou arquivos privados como referência. O atlas foi apenas recortado, redimensionado e ancorado por script, preservando alpha; os 16 cantos transparentes foram verificados. Prompts completos: `assets/PROVENIENCIA.json`. Cortes, pivôs e hashes: `assets/parts-manifest.json`. Isto registra autoria e processo, sem apresentar uma auditoria jurídica de produção comercial.

Sons próprios anteriores foram preservados: síntese matemática, variações A/B, volume/mute e limitador. Não foram extraídos áudios de filmes ou jogos. Fontes de sistema são consultadas em runtime e não foram embutidas. Não houve compra, instalação de dependências, ativação de plugin externo, nova conta, anúncio, publicação ou alteração de segurança. As ferramentas usadas já estavam disponíveis. Nenhum outro processo foi encerrado; as instâncias de QA encerraram seus próprios processos.

## Interrupção, erros e limites

A primeira conexão caiu durante uma escrita de `world.gd`. Na retomada, a leitura confirmou que o arquivo não existia; não houve recriação do projeto nem dos assets. O arquivo foi reconstruído somente após a inspeção, e a importação/execução posterior confirmou a recuperação.

Um teste herdado inicialmente não tinha o diretório de capturas; ele foi criado. Houve ainda uma falha transitória no clique sintético de retomada. O helper passou a preparar movimento do mouse antes do clique, e as execuções finais passaram. Isso não substitui teste humano de interação. Os logs das tentativas foram preservados.

O aviso não fatal da engine ao abrir cache/profiler em `user://` permanece no sandbox. Não foi relaxada nenhuma permissão; os saves graváveis do candidato foram testados. Não há erro de GDScript ou assertiva falha nas execuções finais. A amostra é um projeto editável local; não é um export comercial, instalador ou pacote com runtime embutido.

Permanecem três ondas apenas, animações simples por articulação e um cenário de fundo estático. Em grupos densos ainda há sobreposição parcial. A montagem dos rigs é definida em GDScript; uma entrega para autoria artística no editor deve serializar os recursos/cenas com os ajustes aprovados. Não houve playtest humano de compreensão, prazer, dificuldade ou conforto; funcionamento e FPS não demonstram demanda comercial.

## Tempo e destino

Esta etapa adicional de até duas horas efetivas foi autorizada em 17/10/2026 às 05:19:09 UTC, separadamente do histórico anterior. A primeira janela observada foi 05:19:43–05:34:56, 15min13s incluindo esperas. Há 63,5s conhecidos de espera das duas gerações. A pausa desconectada entre 05:34:56 e 05:36:29 não foi tratada como trabalho. As demais esperas não foram reconstruídas como consumo exato. O registro final separa janelas observadas, pausas e limite superior; não chama calendário de esforço efetivo nem soma o antigo total de 23h56 como consumo.

A guarda operacional de 07:19:09 foi conservadora, não débito de esforço. A entrega ficou bem antes dela. O esforço exato não foi cronometrado continuamente; o intervalo total desta etapa, usado apenas como limite superior, cabe nas duas horas. Histórico anterior preservado.

Nenhum arquivo novo desta amostra foi enviado à Library ou a outro destino. Os quatro VFX antigos já autorizados continuam com a indisponibilidade técnica registrada no protótipo anterior; não houve nova tentativa ou IDs novos nesta etapa. Modelo solicitado: GPT-6.1 Sol High. Não houve uso de subagentes ou troca de modelo; a configuração efetiva de inferência não é exposta pelas ferramentas para confirmação independente.
