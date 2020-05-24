:: OVE (Open View Edit)
:: Esse é script "controller", que apenas faz as ações configuradas no script de "Alias".
:: Esse é o script a ser usado, pois é a partir dele que os arquivos serão executados nos programas configurados.

@echo off
@chcp 65001 > nul

:: Outras variáveis
@set teste=2
@set inicio=start /b ""

:: Caminho do script
@set pathinicial=%~dp0
@set OVE=%pathinicial%OVE.bat
@set OVEAlias=%pathinicial%\OVE - Alias.bat

:: Processo de funcionamento do script.

:: No começo do programa, é invocado o script de "Alias", que, neste caso, está na mesma pasta desse script.
:: Ele tem a função de colocar no ambiente deste programa todas as associações que foram definidas.
:: A partir dele, este programa consegue "enxergar" essas associações, e assim usá-las, quando for o caso.
call "%OVEAlias%"

cls

:: Depois da execução do script "Alias", é feito um teste para saber se o primeiro parâmetro
:: informado é 'open', 'view' ou 'edit'. Caso não seja nenhum deles, uma crítica é dada, e o script é encerrado,
:: sem fazer nada.
@set acao=%~1
@if /i "%acao%" equ "open" @set teste=0
@if /i "%acao%" equ "view" @set teste=0
@if /i "%acao%" equ "edit" @set teste=0
@if %teste% neq 0 (
	echo Não foi passada ação para o programa.
	echo.
	echo O programa deve ser usado na seguinte forma:
	echo OVE acao programa1 [programa2 programa3 ...]
	echo.
	echo Onde "acao" deve ser: "open", "view" ou "edit"
	echo.
	pause
	goto :eof
)

:: É testado também se foi passado, pelo menos, um arquivo para o script.
:: Em caso negativo, uma crítica é dada, e o programa é encerrado, sem qualquer execução.
:: Para o script funcionar, é preciso haver, no mínimo uma ação e um arquivo.
@set programa=""
@if "%~2" equ "" (
	echo Não foi passado arquivo para o programa.
	echo.
	echo O programa deve ser usado na seguinte forma:
	echo OVE acao programa1 [programa2 programa3 ...]
	echo.
	echo Onde "acao" deve ser: "open", "view" ou "edit"
	echo.
	pause
	goto :eof
)

:: Agora começa a leitura da lista de arquivos passados.
@shift

@setlocal enabledelayedexpansion

:: Este é o "core" do processo, onde a extensão de cada arquivo passado é lida, e, de acordo com a ação
:: passada antes, o programa respectivo é executado, com os devidos parâmetros.
:: Antes de rodar efetivamente, é testado se aquela associação existe.
:: Caso não exista, é sugerida a opção de se criá-la no script de "Alias".
:fazeracao
@set extensao=%~x1
:: Esta era uma exceção, para poder esse tipo de arquivo ser "visto" dentro do script.
@if "%~n1" equ "_vimrc" @set extensao=.vimrc
@if "!%acao%%extensao%!" equ "" goto :acaonaodefinida
:: Após confirmar que a associação existe, é lida a mesma.
@set programa=!%acao%%extensao%!
:: É trocado o prefixo do comando, para estar em um padrão para ser executado no batch script.
@set programa=!programa:inicio=start /b ""!
:: E é substituída a string identificadora do arquivo pelo caminho do arquivo.
:: A string "###" serve para, posteriormente, ser usada para pôr o caminho do arquivo atual que está sendo tratado.
@set programa=!programa:###="%~1"!
:: E por fim o executa.
%programa%
goto :fim

:: Esse é um caso especial de tratamento, quando se quer abrir (open) arquivos de extensão .lnk (atalho de Windows).
:: Nesse caso, é procurado o destino desse atalho.
:: Após achar, testa se é um diretório ou um arquivo. Sendo um arquivo, roda esse mesmo script, mas para o destino do atalho.
:: Sendo diretório, o Double Commander é aberto no diretório identificado.
:abrirlnk
@set caminho=""
chcp 1252 > nul
for /f "delims=" %%R in ('chcp 1252 ^| type "%~s1" ^| find "\" ^| find ":" ^| find /v "/"') do @set caminho=%%R
if exist "%caminho%\" (
	start /b "" %doublecmd% -C -T -path "%caminho%"
	goto :fim
)
start "" /D "%pathinicial%" OVE.bat "%acao%" "%caminho%"
chcp 65001 > nul
goto :fim

:: Como antes falei, não havendo associação entre a ação e a extensão, é sugerido definí-la.
:: Aceitando a sugestão, o arquivo de configuração de alias é aberto.
:acaonaodefinida
echo Ação %acao%%extensao% ainda não foi definida.
choice /C sn /M "Deseja configurar (s/n)? " /N
@if %ERRORLEVEL% equ 1 (
	start /b /max "" gvim -y "%OVEAlias%"
)
goto :eof

:: Após o tratamento da ação de cada arquivo, é testado se não houve erro em alguma execução de programa, pois podem
:: haver erros do tipo "não achar o caminho do programa usado". Havendo, o script dá uma crítica, e não segue seu processo
:: para os próximos arquivos que podem ter sido passados.
:: Também é testado se terminou a lista de arquivos. Confirmando, o programa termina normalmente :).
:fim
if %ERRORLEVEL% neq 0 (
	echo Erro no processo!
	pause
	goto :eof
)
@if "%~2" neq "" (
@shift
goto :fazeracao
)
@if "%~2" == "" goto :eof

endlocal
