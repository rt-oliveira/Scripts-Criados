# Git All

## Descrição

Esse script foi criado para tentar ajudar no processo de adicionar e dar commit em todos os arquivos modificados em um repositório Git.

## Motivação

Normalmente, é preciso digitar alguns comandos Git no repositório para que isso seja feito. Porém, com esse script, o processo fica mais simples, pois eles são todos feitos automaticamente, e somente algumas perguntas são feitas para que seja confirmado o processo, e os arquivos que foram *commitados* sejam enviados para o repositório remoto.

## Funcionamento do script

1. Ele adiciona todos os arquivos modificados do respositório para o estado *staged*.
2. É mostrado o status atual, para que você possa ver se todos os arquivos modificados foram para o estado *staged*.
3. Pergunta se foi adicionado tudo. Caso positivo, siga para o passo 5.
4. Caso ainda tenha faltado algum arquivo, o script pergunta o que faltou, e o tenta adicionar.
5. É feita uma confirmação, para saber se o commit será feito ou não. Caso negativo, é dado um *reset* no respositório.
6. Confirmando o commit, pergunta a mensagem que o commit terá.
7. O commit é feito, e os arquivos são enviados ao seu repositório remoto.

---

[Código-fonte do script](Batch%20Script/Git%20All.bat)
