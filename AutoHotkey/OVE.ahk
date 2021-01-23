;@Ahk2Exe-SetDescription Script que ajuda na customização de comandos para os arquivos.
;@Ahk2Exe-SetVersion 2.1.1.0
;@Ahk2Exe-SetName OVE
;@Ahk2Exe-SetCopyright Script feito por Rafael Teixeira.

/*
  OVE (Open-View-Edit)
  Esta é a versão em AutoHotkey do script criado inicialmente em Batch Script, e depois em VBScript.
  Este é o script que atua como 'controller', apenas acionando as ações definidas em um arquivo .ini.
*/

#Warn
DetectHiddenText, on

Testar()

; Duas variáveis globais
global acao
global localIni
global NvAcao
localIni = %A_ScriptDir%\Config OVE.ini
if (!FileExist(localIni)){
  MsgBox 48, , O arquivo de configuração não foi encontrado. Ele será criado.
  FileAppend, , %localIni%, UTF-8-RAW
}
;
ConfigurarVariaveisAmbiente()
;
global ParaTodos
ParaTodos := false
;
for i, arquivo in A_Args
{
	if (i == 1)
		continue
	else{
		if (acao == "-la")
		{
			ListarAcoes(arquivo)
			Pause, Toggle
		}
		;
		if (SubStr(arquivo, -3) == ".lnk") {
          FileGetShortcut, %arquivo%, destino, , argumentos
          RecuperarEExecutarComando(acao, destino, argumentos)
        } else
          RecuperarEExecutarComando(acao, arquivo)
		;
		if (!ParaTodos)
			acao := "-la"
	}
}
exitapp
	
;----------------------------------------------------------------

; Caso ainda não exista um comando associado a uma ação/extensão, será dada a oportunidade
; do usuário poder cadastrar, sem precisar acessar o arquivo de configuração diretamente,
; um comando para aquela associação.
AcaoNaoDefinida(extensao){
  msgbox, 36, ,
  (
  A ação %acao%%extensao% não foi definida.
Deseja definir agora?
  )
  IfMsgBox, Yes
  {
    while (1=1){
      InputBox, comandoASerFeito, Ação não definida, Digite o comando para a ação %acao%%extensao%
      if ErrorLevel
        return ""
      ;
      comandoASerFeito = %comandoASerFeito%
      ;
      if (comandoASerFeito = ""){
        MsgBox, 36, , Confirma a inclusão de comando vazio para a ação %acao%%extensao%?
        ifMsgBox, Yes
        {
          IniWrite, %comandoASerFeito%, %localIni%, %acao%, %acao%%extensao%
          return comandoASerFeito
        }
      } else {
        If (!InStr(comandoASerFeito, "###")){
          msgbox, 16, , Em comandos não-vazios, a máscara ### deve existir.
          Continue
        }
        ;
        if (comandoASerFeito != "###" and !Instr(comandoASerFeito, """", , , 2)){
          msgbox, 16, , O programa deve estar entre aspas.
          continue
        }
        ;
        IniWrite, %comandoASerFeito%, %localIni%, %acao%, %acao%%extensao%
        return comandoASerFeito
      }
    }
  }
}


; Esta é a função que efetivamente executará os comandos vindos das associações.
ExecutarComando(comando, arquivo, argumentos := ""){
  if (trim(comando) == "")
    return
  ;
  comando := StrReplace(comando, "###", """" arquivo """")
  if (trim(argumentos) <> "")
    comando := comando . " " . argumentos
  ;
  try
  {
    Run, %comando%, , , outPID
  }
  catch
  {
    WinKill, ahk_pid %outPID%
    msgbox, 
    (
    Erro na abertura do programa.
          
Verifique sua configuração de associação.
Comando: %comando%
    )
    exitapp
  }
}

; Caso 'acao' seja '-la', eu abro uma janela que listo as ações já cadastradas no
; arquivo de configurações. O usuário pode então escolher uma das ações mostradas
; para usar no arquivo atual, e pode usar esta mesma ação para todos os próximos
; arquivos passados.
ListarAcoes(arquivo){
  IniRead, outSecoes, %localIni%
  outSecoes := StrReplace(outSecoes, "`n", "|")
  ;
  tamanhoFonte := 16
  tamanhoListBox := 50 * tamanhoFonte
  ;
  Gui, Font, s%tamanhoFonte%, MS Sans Serif
  if (FileExist(arquivo) == "D")
    Gui, Add, Text, , Pasta: %arquivo%
  else
    Gui, Add, Text, , Arquivo: %arquivo%
  Gui, Add, Text, , Ações:
  Gui, Add, ListBox, x+m R10 Sort vacao gBotao w%tamanhoListBox%, %outSecoes%
  Gui, Add, Button, xm R0.5 gNovaAcao, Nova Ação:
  Gui, Add, Edit, x+m vNvAcao
  Gui, Add, Checkbox, xm vParaTodos, Válido para este e os próximos arquivos?
  Gui, -MaximizeBox AlwaysOnTop
  Gui, Show, , Lista de ações
  return

GuiClose:
exitapp

Botao:
Gui, Submit
Gui, Destroy
Pause, Toggle
return

NovaAcao:
Gui, Submit, NoHide
if (Trim(NvAcao) == ""){
  MsgBox 262144, , Não há ação preenchida. Por favor, preencha a ação.
  return
}
if (!RegExMatch(NvAcao, "^[a-zA-Z0-9]+$")){
  MsgBox 262144, , %NvAcao% é inválido. Ações só podem ter letras e números.
  return
}
if (InStr(outSecoes . "`n", NvAcao . "`n")){
  MsgBox 262144, , %NvAcao% já existe.
  return
}
acao := NvAcao
Gui, Destroy
Pause, Toggle
return
}

RecuperarExtensao(arquivo){
	if (FileExist(arquivo) == "D")
		return "Pastas"
	else{
		SplitPath, arquivo, nomeArquivo, , tmpExt
		StringLower, tmpExt, tmpExt
		;
		return (tmpExt == "") ? "\"nomeArquivo : "."tmpExt
	}
}

RecuperarEExecutarComando(acao, arquivo, argumentos := ""){
    extensao := RecuperarExtensao(arquivo)
	;
	IniRead, comandoRecuperado, %localIni%, %acao%, %acao%%extensao%
	comandoRecuperado = %comandoRecuperado% ; Para remover espaços em branco no início e no fim da string
	if (comandoRecuperado == "ERROR")
      comandoRecuperado := AcaoNaoDefinida(extensao)
    ;
    ExecutarComando(comandoRecuperado, arquivo, argumentos)
}

; Esta função foi criada para permitir a execução de programas sem precisar, muitas vezes,
; ficar usando o caminho completo dele no arquivo de configuração.
; A partir dessa função:
;  - Os programas que serão usados podem estar na mesma pasta onde o script está localizado.
;  - Eles podem ser referenciados apenas pelo nome do executável/atalho/...
ConfigurarVariaveisAmbiente(){
  ; Esta primeira parte permitirá aos programas poderem estar na mesma pasta do script
  ; e apenas serem referenciados no arquivo de configuração pelo seu nome.
	EnvGet, dirPath, PATH
	dirPath := dirPath ";" A_ScriptDir
	EnvSet, PATH, %dirPath%
  ;
  ; Esta segunda parte permitirá poder executar atalhos sem precisar colocar a extensão
  ; no comando. Isto é: para uma associação cujo comando use o atalho 'teste.lnk', ao invés 
  ; de usar a forma completo, usará apenas o nome do atalho, ou seja, 'teste'.
	EnvGet, varPathExt, PATHEXT
	StringLower, varPathExt, varPathExt
	if (Instr(varPathExt, ".lnk") = 0)
	{
		varPathExt := varPathExt ";.LNK"
		EnvSet, PATHEXT, %varPathExt%
	}
}

Testar(){
  ; Tem, no mínimo, 2 argumentos
  if (A_Args.Length() < 2)
    ErroOVE()
  ;
  ; É uma ação válida?
  ; Uma ação só tem letras e números.
  acao := A_Args[1]
  if (!RegExMatch(acao, "^[a-zA-Z0-9]+$")
      and acao != "-la")
    ErroOVE()
}

; Mensagem de erro, informando que deve ser passado, pelo menos, 1 ação e 1 arquivo,
; para o script ser executado.
ErroOVE(){
	msg = 
  (
    Não foi passada ação ou arquivo para o programa.

O programa deve ser usado da seguinte forma:
OVE acao programa1 [programa2 programa3 ...]

Onde 'acao' pode ser:
- Um termo que contenha somente letras (sem acentos) e números, ou;
- '-la', que vai listar as ações.
  )
	MsgBox, 16, OVE, %msg%
	exitapp
}