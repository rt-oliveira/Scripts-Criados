:: OVE - Alias (Open View Edit)
:: Esse é o script de "Alias", que é responsável por definir as associações entre as ações e as extensões.
::
:: Observação: as associações aqui expostas são apenas para exemplo, pois você definir as associações à sua maneira,
:: para rodar os comandos que quiser.
::
:: Cada ação e extensão é definida da seguinte forma:
::
:: set acao.extensao=comando
::
:: Onde:
:: *acao*    : é o nome da ação passada (open, view ou edit).
:: *extensao*: é a extensão do arquivo que está sendo tratado no script "controller" (com o ponto ['.']).
:: *comando* : é o que quer que seja executado.
:: Geralmente *comando* seguirá um padrão, que é:
::    *comando* = inicio *programa* [*parâmetros*] ###
::      - Onde:
::        - "inicio"    : é um prefixo, que é substituído no script "controller".
::        - *programa*  : é o nome do programa que quer rodar. Ele pode ser:
::                          - O caminho completo de um programa, ou;
::                          - Um programa que está em uma pasta que está na variável de ambiente PATH do Windows.
::        - *parâmetros*: são os parâmetros que podem ser passados para *programa*.
::        - ###         : é uma string que é usada como "placeholder" para depois ser substituída pelo caminho do arquivo.
::
:: Porém há 2 comandos especiais:
:: - "goto :eof*"     : este comando indica que, naquela extensão e ação, nada será feito.
:: - "goto :abrirlnk" : este comando indica que será feito um tratamento especial para arquivos ".lnk". Pode ser usado
::                      para quando se quer abrir atalhos Windows.

@echo off

:: Comandos de view
:: Essa associação indica que, caso deseje visualizar um arquivo .3gp, ele abrirá o VLC para esse arquivo.
set view.3gp=inicio vlc ###
set view.bat=inicio notepad++ -ro ###
set view.exe=goto :eof
set view.mp4=inicio vlc ###

:: Comandos de edit
set edit.bat=inicio notepad++ ###
set edit.exe=goto :eof
set edit.ini=inicio notepad++ ###
:: Essa associação indica que não será possível editar um arquivo .lnk
set edit.lnk=goto :eof
set edit.md=inicio gvim -y ###
set edit.sql=inicio notepad++ ###

:: Comandos de open
set open.bat=inicio ###
set open.chm=inicio ###
set open.exe=inicio ###
set open.lnk=goto :abrirlnk
set open.msi=inicio ###
set open.pdf=inicio sumatrapdf ###
set open.txt=inicio showtx
