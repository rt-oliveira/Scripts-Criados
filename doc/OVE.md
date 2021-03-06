# OVE (Open View Edit)

OVE é um acrônimo que foi criado, que significa "Open View Edit".

## Descrição

É um script que foi criado para ajudar no processo de associação de programas, para tornar esse processo portátil e independente do sistema operacional.

Ele foi criado para, inicialmente, poder me facilitar, pois como sou um usuário dos chamados *programas portáteis*, percebi que havia essa necessidade de se criar um mecanismo para configuração de programas padrão para as extensões de maneira portátil também.

Esse script, junto com um outro, chamado de "Alias", que possui as associações criadas, permite que possam ser rodadas associações customizadas de programa padrão com as extensões, sem precisar configurá-las no sistema operacional.

## Motivação

Normalmente, para fazer com que um determinado arquivo, de uma determinada extensão, rode em um programa específico, é preciso ir nas configurações de `Programas Padrão` do sistema operacional, escolher a extensão e o programa padrão desta extensão.

Porém, ela só configura o programa padrão para a extensão em só uma ação, que geralmente é a única que há no sistema operacional: abrir.

Mas, com esse script, esse processo se tornou independente, de modo que não seja mais necessário o sistema dentro desse processo, além de ser customizável, pois você configurar o programa que quiser, para cada ação e extensão.

## Funcionamento do script

Esse script atua como sendo uma espécie de `controller`, na qual dado uma lista de arquivos e uma ação, esse script roda o programa apropriado para a ação e extensão de cada arquivo contido na lista.

- Exemplo:

Supondo 2 arquivos, `conta.pdf` e `apresentacao.txt`, e uma ação, por exemplo, `view`, esse script executará a ação relativa a visualização de arquivos *pdf* e *txt*, respectivamente (o que, neste caso, seriam, provavelmente, leitores de pdf e de txt).

Porém, além desse `controller`, existe também um outro script, para configuração desses associações para as extensões, chamado de *Alias*.

No início da execução do script *controller*, o script de alias é chamado, de forma a criar as associações. Após isso, para cada arquivo passado, é executada a ação passada apropriada para aquela extensão. Caso a associação não tenha sido configurada, é sugerido criá-la, para futuras utilizações.

## Como executar o script?

O script principal pode ser executado da seguinte forma:

```ahk
OVE acao arquivo1 [arquivo2 arquivo3 ...]

Onde "acao" é uma sequência de letras (sem acentos) e números.
```

O script sempre requerirá 1 ação e, pelo menos, 1 arquivo, para o seu funcionamento.

**Novidade na versão 2.0.0 do OVE em AutoHotkey**: agora será permitido passar um parâmetro que permite escolher na hora qual ação deseja. Este mesmo modo permite criar novas ações na hora também.

Para tal, o parâmetro de ação deve ser *-la*. Com isso, o programa é usado da seguinte forma:

~~~ahk
OVE -la arquivo1 [arquivo2 arquivo3 ...]
~~~

**Novidade na versão 2.3.0 do OVE em AutoHotkey**: agora será permitido poder executar comandos de ações já existentes com parâmetros.

Para tal, *ação* deve conter um sufixo **-p**. Com isso, pode ser passado para o script, além da ação:
    - 1 único arquivo (**obrigatório**), e;
    - Argumentos, que serão aplicados sobre este arquivo (**opcional**).
Com isso, o programa é usado da seguinte forma:

```ahk
O programa deve ser usado da seguinte forma:
OVE acao-p arquivo [argumento1 argumento2 ...]
```

**Novo na versão 2.5.0 do OVE em AutoHotkey**: modo mais poderoso de execução de ações já existentes com parâmetros.

Para tal, o programa ser usado da seguinte forma:

~~~ahk
OVE combinacao argumento1 [argumento2 argumento3 ...]
~~~
- Onde *combinacao* é: *acao*+*extensao*
    - *extensao* pode ser:
        - A extensão normal de um arquivo (incluindo o ponto '.');
        - `\nomeArquivo`, caso o arquivo não tenha uma extensão, ou;
        - `:Pastas`, para se referir as pastas e diretórios em geral.

## Restrições

1. Esse script foi planejado para ser executado no Double Commander, porém ele pode ser adaptado para ser usado junto com outros programas (geralmente exploradores de arquivos).
    - Foi planejado para este programa, pois o mesmo permite que se possa configurar ações customizadas para as extensões, até mesmo sobreescrita de ações padrão para as mesmas extensões.
2. Todos os arquivos passados vão estar sempre baseados na mesma ação, isto é, ao passar uma ação, e uma lista de arquivos, todas os arquivos vão ser tratados na mesma ação passada.
    - Exemplo: uma lista de arquivos e a ação "view", todos os arquivos serão tratados na ação de visualizá-los.
    - Isto não se aplica quando se usa o parâmetro `-la`. Neste modo, será possível usar uma ação diferente para cada arquivo.

## Como implantar o script para seu uso?

Baseando-se pelo Double Commander:

1. Com o Double Commander, vá no menu *Configuração*, e selecione o item *Associações de ficheiros...*

![Primeiro passo do processo de implantação.](/images/passo1-ove.png)

2. Ao escolher a opção, aparecerá uma tela similar a imagem abaixo:

![Tela de associação de ficheiros aberta, no Double Commander.](/images/passo2-ove.png)

Escolha a opção *Adicionar* (sublinhada na imagem).

3. Aparecerá uma janela, pedindo o nome desta associação. Dê um nome qualquer, como *OVE*.

4. Confirme, e assim criará um espaço para configuração de associação de arquivos, como na imagem abaixo.

![Criado "OVE", um espaço onde será criada a associação de arquivos.](/images/passo4-ove.png)

Com ele criado, primeiro é preciso escolher as extensões que farão parte desta associação. Selecione a opção *Adicionar* como mostrado acima.

5. Aparecerá uma janela, pedindo o nome de uma extensão para adicionar na lista de extensões cobertas nesse espaço. Digite *default*
    - O programa entenderá *default* não como uma extensão específica, e sim como a definição padrão a ser usada em todas as extensões, dentro do programa.
  
![Extensão "default" digitado na janela de extensões do espaço de associação](/images/passo5-ove.png)

Confirme.

6. Após a extensão adicionada, é preciso configurar as ações a serem executadas neste espaço de associação.
    - Serão adicionadas 3 ações: *Open*, *View* e *Edit*. Essas ações significam:
        - *Abrir* (ou seja, quando der duplo clique no arquivo ou apertar *Enter* para um arquivo);
        - *Ver* (quando, ao selecionar um arquivo, aperta *F3*);
        - *Editar* (quando, ao selecionar um arquivo, aperta *F4*).
Para cada uma dessas ações, o caminho será o mesmo, com apenas passando parâmetros diferentes entre eles. Os valores configurados podem ser vistos nas imagens abaixo:

![Configuração da ação "Open"](/images/passo6-1-ove.png)
![Configuração da ação "View"](/images/passo6-2-ove.png)
![Configuração da ação "Edit"](/images/passo6-3-ove.png)

Observação: O parâmetro `%p` que está sendo usado significa, dentro do Double Commander, a lista de arquivos selecionados.

7. E assim já está configurado o OVE no Double Commander. Agora, para cada vez que for querer abrir, ver ou editar um arquivo, o programa delegará ao OVE a execução dos programas adequados, de acordos com as ações disponíveis e as extensões dos arquivos passados.

## Observações Finais

- A documentação inteira do script foi focada nas três ações (*open*, *view* e *edit*), porém este script pode ser customizado para adaptar novos tipos de ações, de acordo com a necessidade.
- Inicialmente o script foi desenvolvido em Batch Script, porém posteriormente foi adaptado para VBScript também.
    - Neste caso, ao invés de haver um script *Alias*, há um arquivo de configuração .INI onde há as ações configuradas.
- [Edit 26/09/2020] O script foi mais uma vez adaptado, e também foi modernizado, para a linguagem AutoHotkey.
    - Essa adaptação foi feita, pois esta linguagem possui recursos que não eram vistos na linguagem VBScript, como a leitura de arquivos .INI, e o tratamento mais simples de arquivos de atalho (.lnk).
    - Além disso, na versão do script nesta linguagem foi adicionado um mecanismo para adição de novas ações sem precisar editar diretamente o arquivo de configurações.
    - **Esta é a versão mais recomendada para uso.**

## Códigos-fonte

- Em Batch Script
    - [Para ver o script "Controller", que executa as ações.](/Batch%20Script/OVE.bat)
    - [Para ver o script "Alias", que configura as ações.](/Batch%20Script/OVE%20-%20Alias.bat)
- Em VBScript
    - [Para ver o script "Controller", que executa as ações.](/VBScript/OVE.vbs)
    - [Para ver o arquivo de configuração .INI, que configura as ações.](/INI/Config%20OVE.ini)
- Em AutoHotkey
    - [Para ver o script "Controller", que executa as ações.](/AutoHotkey/OVE.ahk)
    - [Para ver o arquivo de configuração .INI, que configura as ações.](/INI/Config%20OVE%20(AHK).ini)