@echo off
chcp 65001 >nul

rem Verifica se o git existe no computador
where git 1>nul
if %ERRORLEVEL% equ 1 (
	echo O programa não pode ser rodado, pois não existe git em seu computador.
	echo Tenha o 'git' em pastas da variável PATH do seu computador.
	pause
	goto :eof
)

rem Verifica se foi passada alguma pasta para o programa
if "%~s1"=="" (
	echo Não foi passada nenhuma pasta para o programa.
	echo Para executar o programa, é preciso passar uma pasta como argumento.
	pause
	goto :eof
)

cd /d "%~1"
echo %cd%

rem Adiciona todos os arquivos e mostra o status
git add *
git status
choice /c sn /m "Tudo foi adicionado (s/n)? " /n
if %ERRORLEVEL% equ 1 goto :confirmarcommit
if %ERRORLEVEL% equ 2 goto :addmais
exit /b 0

:addmais
rem Adiciona mais elementos ao commit
set /p oqueadd=O que adicionar? 
git add %oqueadd%
git status

:confirmarcommit
rem Para confirmar o commit, se deseja fazer realmente
choice /c sn /m "Confirmar commit (s/n)? " /n
if %ERRORLEVEL% equ 1 goto :commitar
if %ERRORLEVEL% equ 2 goto :desfazer
exit /b 0

:commitar
rem Para capturar mensagem do commit
set /p msgcommit=Mensagem do commit: 
git commit -m "%msgcommit%"
git push -f
goto :eof

:desfazer
rem Caso não deseje fazer o commit, os arquivos vão para o estado unstaged/modified
git reset HEAD
goto :eof