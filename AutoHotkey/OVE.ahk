;@Ahk2Exe-SetDescription Script que ajuda na customiza��o de comandos para os arquivos.
;@Ahk2Exe-SetVersion 2.0.0.0
;@Ahk2Exe-SetName OVE
;@Ahk2Exe-SetCopyright Script feito por Rafael Teixeira.

/*
  OVE (Open-View-Edit)
  Esta � a vers�o em AutoHotkey do script criado inicialmente em Batch Script, e depois em VBScript.
  Este � o script que atua como 'controller', apenas acionando as a��es definidas em um arquivo .ini.
*/

#Warn
DetectHiddenText, on

Testar()

; Duas vari�veis globais
global acao
global localIni
global NvAcao
localIni = %A_ScriptDir%\Config OVE.ini
if (!FileExist(localIni)){
  MsgBox 48, , O arquivo de configura��o n�o foi encontrado. Ele ser� criado.
  FileAppend, , %localIni%, UTF-8-RAW
}
;
ConfigurarVariaveisAmbiente()
;
global ParaTodos
ParaTodos := false
ExecutarAcoes()
;----------------------------------------------------------------
Testar(){
  ; Tem, no m�nimo, 2 argumentos
  if (A_Args.Length() < 2)
    ErroOVE()
  ;
  ; � uma a��o v�lida?
  ; Uma a��o s� tem letras e n�meros.
  acao := A_Args[1]
  if (!RegExMatch(acao, "^[a-zA-Z0-9]+$")
      and acao != "-la")
    ErroOVE()
}

; Mensagem de erro, informando que deve ser passado, pelo menos, 1 a��o e 1 arquivo,
; para o script ser executado.
ErroOVE(){
  msg = 
  (
    N�o foi passada a��o ou arquivo para o programa.

O programa deve ser usado da seguinte forma:
OVE acao programa1 [programa2 programa3 ...]

Onde 'acao' pode ser:
- Um termo que contenha somente letras (sem acentos) e n�meros, ou;
- '-la', que vai listar as a��es.
  )
  MsgBox, 16, OVE, %msg%
  exitapp
}

; Na vers�o em Batch desse script, s� era aceito uma a��o para arquivos atalho (.lnk), a a��o 'open'.
; Por�m, tanto na vers�o em VBScript, como nessa, em AHK, isso foi ampliado, de modo a permitir qualquer
; a��o.
TratarAtalho(arquivo){
  local comandoAtalho
  FileGetShortcut, %arquivo%, destino, , argumentos
  ; Se o atalho tiver argumentos, geralmente isso vai se referir a um atalho de um programa com argumentos.
  ; Com isso, caso o atalho tenha argumentos, simplesmente executa o programa com os seus devidos argumentos.
  if (Trim(argumentos) <> "")
  {
    if (FileExist(destino))
      Run, "%destino%" %argumentos%
  } else {
    ; Aqui eu vejo para o que o atalho est� "apontando".
    tipo := FileExist(destino)
    if (tipo = "D")     ; � diret�rio
    {
      ; Se estiver apontando para um diret�rio, ser� procurado o comando padr�o para abrir pastas.
      ; Geralmente este comando ser� para abrir a pasta em um explorador de arquivos.
      ; Esta � a �nica associa��o com chave padr�o que h� no script (todos os atalhos de pastas usar�o
      ; o comando associado a chave 'openPastas'.
      IniRead, comandoAtalho, %localIni%, open, openPastas
      comandoAtalho = %comandoAtalho%
      if (comandoAtalho = "ERROR"){
        comandoAtalho := AcaoNaoDefinida("Pastas")
        if (comandoAtalho != "ERROR")
            ExecutarComando(comandoAtalho, arquivo)
      }
      else
        ExecutarComando(comandoAtalho, destino)
    } 
    else                ; � arquivo
    {
      ; Se estiver apontando para um arquivo, simplesmente executa o mesmo script, passando a a��o que j�
      ; havia passado, mas agora para o destino do atalho.
      if A_IsCompiled
        comandoAtalho := """" A_ScriptFullPath """ " acao " ###" 
      else
        comandoAtalho := """" A_AhkPath """" " """ A_ScriptFullPath """ " acao " ###"
      ExecutarComando(comandoAtalho, destino)
    }
  }
}

; Caso ainda n�o exista um comando associado a uma a��o/extens�o, ser� dada a oportunidade
; do usu�rio poder cadastrar, sem precisar acessar o arquivo de configura��o diretamente,
; um comando para aquela associa��o.
AcaoNaoDefinida(extensao){
  msgbox, 36, ,
  (
  A a��o %acao%%extensao% n�o foi definida.
Deseja definir agora?
  )
  IfMsgBox, Yes
  {
    while (1=1){
      InputBox, comandoASerFeito, A��o n�o definida, Digite o comando para a a��o %acao%%extensao%
      if ErrorLevel
        return "ERROR"
      ;
      comandoASerFeito = %comandoASerFeito%
      ;
      if (comandoASerFeito = ""){
        MsgBox, 36, , Confirma a inclus�o de comando vazio para a a��o %acao%%extensao%?
        ifMsgBox, Yes
        {
          IniWrite, %comandoASerFeito%, %localIni%, %acao%, %acao%%extensao%
          return comandoASerFeito
        }
      } else {
        If (!InStr(comandoASerFeito, "###")){
          msgbox, 16, , Em comandos n�o-vazios, a m�scara ### deve existir.
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


; Esta � a fun��o que efetivamente executar� os comandos vindos das associa��es.
ExecutarComando(comando, arquivo){
  comando := StrReplace(comando, "###", """" arquivo """")
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
          
Verifique sua configura��o de associa��o.
Comando: %comando%
    )
    exitapp
  }
}

; Caso 'acao' seja '-la', eu abro uma janela que listo as a��es j� cadastradas no
; arquivo de configura��es. O usu�rio pode ent�o escolher uma das a��es mostradas
; para usar no arquivo atual, e pode usar esta mesma a��o para todos os pr�ximos
; arquivos passados.
ListarAcoes(arquivo){
  static outSecoes
  IniRead, outSecoes, %localIni%
  ;
  Gui, Font, s16, MS Sans Serif
  if (FileExist(arquivo) == "D")
    Gui, Add, Text, , Pasta: %arquivo%
  else
    Gui, Add, Text, , Arquivo: %arquivo%
  Gui, Add, Text, , A��es:
  loop, parse, outSecoes, `n
  {
    Gui, Add, Button, w350 gBotao, %A_LoopField%
  }
  Gui, Add, Button, R0.5 gNovaAcao, Nova A��o:
  Gui, Add, Edit, x+m R0.5 vNvAcao
  Gui, Add, Checkbox, x-m vParaTodos, V�lido para este e os pr�ximos arquivos?
  Gui, -MaximizeBox AlwaysOnTop
  Gui, Show, , Lista de a��es
  return

GuiClose:
exitapp

Botao:
Gui, Submit
acao := A_GuiControl
Gui, Destroy
Pause, Toggle
return

NovaAcao:
Gui, Submit, NoHide
if (Trim(NvAcao) == ""){
  MsgBox 262144, , N�o h� a��o preenchida. Por favor, preencha a a��o.
  return
}
if (!RegExMatch(NvAcao, "^[a-zA-Z0-9]+$")){
  MsgBox 262144, , %NvAcao% � inv�lido. A��es s� podem ter letras e n�meros.
  return
}
if (InStr(outSecoes . "`n", NvAcao . "`n")){
  MsgBox 262144, , %NvAcao% j� existe.
  return
}
acao := NvAcao
Gui, Destroy
Pause, Toggle
return
}

ExecutarAcoes(){
  for i, arquivo in A_Args
  {
    if (i = 1)
      continue
    else
    {
      if (acao == "-la")
      {
        ListarAcoes(arquivo)
        Pause, Toggle
      }
      ;
      if (FileExist(arquivo) == "D")
        extensao := "\Pastas"
      else {
        SplitPath, arquivo, nomeArquivo, , extensao
        StringLower, extensao, extensao
        ;
        extensao := (extensao == "") ? "\"nomeArquivo : "."extensao
      }
      ;
      if (extensao = ".lnk")
        TratarAtalho(arquivo)
      else {
        IniRead, comando, %localIni%, %acao%, %acao%%extensao%
        comando = %comando% ; Para remover espa�os em branco no in�cio e no fim da string
        if (comando == "ERROR"){
          comando := AcaoNaoDefinida(extensao)
          if (comando != "ERROR")
            ExecutarComando(comando, arquivo)
        }
        else if (comando <> "")
          ExecutarComando(comando, arquivo)
      }
      ;
      if (!ParaTodos){
        acao := "-la"
      }
    }
  }
  exitapp
}

; Esta fun��o pfoi criada para permitir a execu��o de programas sem precisar, muitas vezes,
; ficar usando o caminho completo dele no arquivo de configura��o.
; A partir dessa fun��o:
;  - Os programas que ser�o usados podem estar na mesma pasta onde o script est� localizado.
;  - Eles podem ser referenciados apenas pelo nome do execut�vel/atalho/...
ConfigurarVariaveisAmbiente(){
  ; Esta primeira parte permitir� aos programas poderem estar na mesma pasta do script
  ; e apenas serem referenciados no arquivo de configura��o pelo seu nome.
  EnvGet, dirPath, PATH
  dirPath := dirPath ";" A_ScriptDir
  EnvSet, PATH, %dirPath%
  ;
  ; Esta segunda parte permitir� poder executar atalhos sem precisar colocar a extens�o
  ; no comando. Isto �: para uma associa��o cujo comando use o atalho 'teste.lnk', ao inv�s 
  ; de usar a forma completo, usar� apenas o nome do atalho, ou seja, 'teste'.
  EnvGet, varPathExt, PATHEXT
  StringLower, varPathExt, varPathExt
  if (Instr(varPathExt, ".lnk") = 0)
  {
    varPathExt := varPathExt ";.LNK"
    EnvSet, PATHEXT, %varPathExt%
  }
}
